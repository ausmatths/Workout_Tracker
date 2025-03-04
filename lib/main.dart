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

          // User is authenticated, show home screen
          return HomeScreen();
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
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _verifyAuthentication();
  }

  void _verifyAuthentication() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("WARNING: HomeScreen accessed without authentication!");
    } else {
      print("HomeScreen accessed by user: ${user.uid} (Anonymous: ${user.isAnonymous})");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is still authenticated
    if (FirebaseAuth.instance.currentUser == null) {
      // If authentication was lost, redirect to AuthPage
      return AuthPage();
    }

    // Get current user
    final user = FirebaseAuth.instance.currentUser!;
    final isAnonymous = user.isAnonymous;

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
                isAnonymous
                    ? 'Guest User'
                    : (user.email?.split('@').first ?? 'User'),
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
              try {
                await FirebaseAuth.instance.signOut();

                // If user was anonymous, try to sign in anonymously again
                if (isAnonymous) {
                  try {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    await authService.signInAnonymously();
                    print("Signed in anonymously after sign out");
                  } catch (e) {
                    print("Error signing in anonymously after sign out: $e");
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Signed out successfully')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: $e')),
                );
              }
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
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
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}