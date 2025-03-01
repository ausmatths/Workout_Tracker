import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/workout_data.dart';
import 'data/storage_service.dart';
import 'data/fake_data.dart';
import 'services/workout_service.dart';
import 'services/auth_service.dart';
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

    final storage = StorageService();
    await storage.init();

    // Initialize service
    final workoutService = WorkoutService(storage);
    final authService = AuthService();

    // Add fake data for testing
    if (storage.getWorkoutPlans().isEmpty) {
      await storage.addWorkoutPlan(basicWorkoutPlan);
      for (var workout in sampleWorkouts) {
        await storage.addWorkout(workout);
      }
    }

    runApp(MyApp(
      storage: storage,
      service: workoutService,
      authService: authService,
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

  const MyApp({
    Key? key,
    required this.storage,
    required this.service,
    required this.authService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WorkoutData(storage),
        ),
        ChangeNotifierProvider(
          create: (_) => GroupWorkoutProvider(),  // Removed the authService parameter
        ),
        Provider.value(value: service),
        Provider.value(value: authService),
        Provider.value(value: storage),
      ],
      child: MaterialApp(
        title: 'Workout Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: AuthWrapper(storage: storage),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  final StorageService storage;

  const AuthWrapper({
    Key? key,
    required this.storage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<dynamic>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          return HomeScreen();
        }

        return AuthPage();
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
  Widget build(BuildContext context) {
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