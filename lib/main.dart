import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/workout_data.dart';
import 'data/storage_service.dart';
import 'data/fake_data.dart';
import 'services/workout_service.dart';
import 'widgets/workout_history_page.dart';
import 'widgets/recent_performance_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = StorageService();
  await storage.init();

  // Initialize service
  final workoutService = WorkoutService(storage);

  // Add fake data for testing
  if (storage.getWorkoutPlans().isEmpty) {
    await storage.addWorkoutPlan(basicWorkoutPlan);
    for (var workout in sampleWorkouts) {
      await storage.addWorkout(workout);
    }
  }

  runApp(MyApp(storage: storage, service: workoutService));
}

class MyApp extends StatelessWidget {
  final StorageService storage;
  final WorkoutService service;

  const MyApp({
    Key? key,
    required this.storage,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => WorkoutData(storage),
        ),
        Provider.value(value: service),
      ],
      child: MaterialApp(
        title: 'Workout Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(child: WorkoutHistoryPage()),
                RecentPerformanceWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}