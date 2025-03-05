import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'data/workout_data.dart';
import 'data/storage_service.dart';
import 'data/fake_data.dart';
import 'services/workout_service.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'providers/group_workout_provider.dart';
import 'widgets/workout_history_page.dart';
import 'widgets/recent_performance_widget.dart';
import 'widgets/auth_page.dart';
import 'widgets/group_workout_list.dart';
import 'widgets/workout_selection_page.dart';
import 'widgets/create_group_workout.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize Firebase with error handling
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print("Firebase initialized successfully");

    // Create services
    final authService = AuthService();
    final firestoreService = FirestoreService();
    final storage = StorageService();
    await storage.init();

    // Initialize workout service
    final workoutService = WorkoutService(storage);

    // Check if user is already signed in, if not sign in anonymously
    if (FirebaseAuth.instance.currentUser == null) {
      try {
        final credential = await authService.signInAnonymously();
        print("Signed in anonymously with user ID: ${credential.user?.uid}");
      } catch (e) {
        print("Error signing in anonymously: $e");
      }
    }

    // For debugging: Print auth state
    final currentUser = FirebaseAuth.instance.currentUser;
    print("Initial auth state: ${currentUser != null ? 'Signed in as ${currentUser.uid}' : 'Not signed in'}");

    // Enable Firestore debug logging in development
    bool isDebugMode = true; // Set to false for production
    if (isDebugMode) {
      FirebaseFirestore.instance.settings = Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }

    // Add fake data for testing - ONLY if in debug mode
    if (isDebugMode && storage.getWorkoutPlans().isEmpty) {
      await storage.addWorkoutPlan(basicWorkoutPlan);
      for (var workout in sampleWorkouts) {
        await storage.addWorkout(workout);
      }
    }

    runApp(MyApp(
      storage: storage,
      service: workoutService,
      authService: authService,
      firestoreService: firestoreService,
    ));
  } catch (e, stackTrace) {
    print("Error during initialization: $e");
    print("Stack trace: $stackTrace");

    // Fallback to a minimal app if initialization fails
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Initialization Error', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text('Error: $e', style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: () {
                  main(); // Attempt to reinitialize
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  final StorageService storage;
  final WorkoutService service;
  final AuthService authService;
  final FirestoreService firestoreService;

  const MyApp({
    Key? key,
    required this.storage,
    required this.service,
    required this.authService,
    required this.firestoreService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WorkoutData(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupWorkoutProvider(),
        ),
        Provider.value(value: service),
        Provider.value(value: authService),
        Provider.value(value: storage),
        Provider.value(value: firestoreService),
      ],
      child: MaterialApp(
        title: 'Workout Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: AuthGate(storage: storage),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  final StorageService storage;

  const AuthGate({
    Key? key,
    required this.storage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading indicator while waiting for auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Initialize the GroupWorkoutProvider when authentication state changes
        final groupWorkoutProvider = Provider.of<GroupWorkoutProvider>(context, listen: false);
        final authService = Provider.of<AuthService>(context, listen: false);

        // Check if user is authenticated
        if (snapshot.hasData) {
          print("Auth state changed: User authenticated with ID: ${snapshot.data!.uid}");
          print("Is user anonymous? ${snapshot.data!.isAnonymous}");

          // Fetch data after authentication
          WidgetsBinding.instance.addPostFrameCallback((_) {
            try {
              groupWorkoutProvider.fetchGroupWorkouts();
              groupWorkoutProvider.fetchInvites();
            } catch (e) {
              print("Error fetching data after authentication: $e");
            }
          });

          // User is authenticated, show home screen with the current user
          return HomeScreen(user: snapshot.data!);
        } else {
          print("Auth state changed: User is not authenticated");

          // Try to sign in anonymously if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await authService.signInAnonymously();
              print("Signed in anonymously from AuthGate");
            } catch (e) {
              print("Error signing in anonymously from AuthGate: $e");
            }
          });

          // Show loading while attempting anonymous sign-in
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Preparing your workout experience...")
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late User _currentUser;
  StreamSubscription<User?>? _authSubscription;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _verifyAuthentication();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  void _verifyAuthentication() {
    print("HomeScreen accessed by user: ${_currentUser.uid} (Anonymous: ${_currentUser.isAnonymous})");
  }

  void _showJoinWorkoutDialog() {
    final TextEditingController codeController = TextEditingController();
    bool isJoining = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Join Group Workout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Enter the 6-digit code shared with you:',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: InputDecoration(
                      labelText: 'Share Code',
                      hintText: 'e.g., ABC123',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontSize: 20,
                      letterSpacing: 4,
                    ),
                    maxLength: 6,
                  ),
                  if (isJoining)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isJoining ? null : () {
                    Navigator.pop(context);
                  },
                  child: Text('CANCEL'),
                ),
                TextButton(
                  onPressed: isJoining ? null : () async {
                    final code = codeController.text.trim().toUpperCase();
                    if (code.length != 6) {
                      return;
                    }

                    setState(() {
                      isJoining = true;
                    });

                    try {
                      final provider = Provider.of<GroupWorkoutProvider>(context, listen: false);
                      await provider.joinWorkoutByShareCode(code);

                      Navigator.pop(context);

                      // Switch to Group Workouts tab
                      if (mounted) {
                        this.setState(() {
                          _selectedIndex = 1;
                        });
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Successfully joined workout!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error joining workout: $e')),
                      );
                    } finally {
                      setState(() {
                        isJoining = false;
                      });
                    }
                  },
                  child: Text('JOIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get current user
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // If authentication was lost, redirect to AuthPage
      return AuthPage();
    }

    // Use the current user directly rather than keeping state
    final isAnonymous = currentUser.isAnonymous;
    final displayName = currentUser.displayName;
    final email = currentUser.email;

    // Determine user display text with priority: displayName > email > "User"
    String userDisplayText = "User";
    if (isAnonymous) {
      userDisplayText = "Guest User";
    } else if (displayName != null && displayName.isNotEmpty) {
      userDisplayText = displayName;
    } else if (email != null && email.isNotEmpty) {
      userDisplayText = email.split('@').first;
    }

    List<Widget> _pages = [
      Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: WorkoutHistoryPage()),
              RecentPerformanceWidget(),
            ],
          ),
        ),
      ),
      GroupWorkoutListPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'My Workouts' : 'Group Workouts'),
        actions: [
          // Show user status (anonymous or email)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                userDisplayText,
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
          // If anonymous, show option to create account
          if (isAnonymous)
            IconButton(
              icon: Icon(Icons.person_add),
              tooltip: 'Create Account',
              onPressed: () {
                // Navigate to account creation page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuthPage()),
                );
              },
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              final wasAnonymous = isAnonymous;
              try {
                await FirebaseAuth.instance.signOut();

                // If user was anonymous, try to sign in anonymously again
                if (wasAnonymous) {
                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.signInAnonymously();
                    print("Signed in anonymously after sign out");
                  } catch (e) {
                    print("Error signing in anonymously after sign out: $e");
                  }
                } else {
                  if (!_isDisposed && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Signed out successfully')),
                    );
                  }
                }
              } catch (e) {
                if (!_isDisposed && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_selectedIndex == 0) {
            // On My Workouts tab - navigate to workout selection
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutSelectionPage(),
              ),
            );
          } else {
            // On Group Workouts tab - show options
            showModalBottomSheet(
              context: context,
              builder: (context) => Container(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: Icon(Icons.add),
                      title: Text('Create New Group Workout'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateGroupWorkoutPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.group_add),
                      title: Text('Join Group Workout'),
                      onTap: () {
                        Navigator.pop(context);
                        _showJoinWorkoutDialog();
                      },
                    ),
                  ],
                ),
              ),
            );
          }
        },
        child: Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'My Workouts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Group Workouts',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (mounted) {
            setState(() {
              _selectedIndex = index;
            });
          }
        },
      ),
    );
  }
}