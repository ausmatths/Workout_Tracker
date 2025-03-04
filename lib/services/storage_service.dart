import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import '../models/exercise_result.dart';

class StorageService {
  static const String workoutsBoxName = 'workouts';
  static const String plansBoxName = 'workout_plans';
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();

      // Register adapters if they haven't been registered already
      if (!Hive.isAdapterRegistered(WorkoutAdapter().typeId)) {
        Hive.registerAdapter(WorkoutAdapter());
      }
      if (!Hive.isAdapterRegistered(ExerciseResultAdapter().typeId)) {
        Hive.registerAdapter(ExerciseResultAdapter());
      }
      if (!Hive.isAdapterRegistered(ExerciseAdapter().typeId)) {
        Hive.registerAdapter(ExerciseAdapter());
      }
      if (!Hive.isAdapterRegistered(WorkoutPlanAdapter().typeId)) {
        Hive.registerAdapter(WorkoutPlanAdapter());
      }

      // Open boxes
      await Hive.openBox<Workout>(workoutsBoxName);
      await Hive.openBox<WorkoutPlan>(plansBoxName);

      _isInitialized = true;
      debugPrint('Hive storage initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Hive storage: $e');
      rethrow;
    }
  }

  Future<void> addWorkout(Workout workout) async {
    try {
      final box = Hive.box<Workout>(workoutsBoxName);
      await box.add(workout);
      debugPrint('Workout added successfully'); // Removed reference to workout properties
    } catch (e) {
      debugPrint('Error adding workout: $e');
      rethrow;
    }
  }

  List<Workout> getWorkouts() {
    try {
      final box = Hive.box<Workout>(workoutsBoxName);
      return box.values.toList();
    } catch (e) {
      debugPrint('Error getting workouts: $e');
      return [];
    }
  }

  Future<void> addWorkoutPlan(WorkoutPlan plan) async {
    try {
      final box = Hive.box<WorkoutPlan>(plansBoxName);
      await box.add(plan);
      // Check if the name property exists before trying to use it
      debugPrint('Workout plan added successfully: ${plan.name ?? "Unknown"}');
    } catch (e) {
      debugPrint('Error adding workout plan: $e');
      rethrow;
    }
  }

  List<WorkoutPlan> getWorkoutPlans() {
    try {
      final box = Hive.box<WorkoutPlan>(plansBoxName);
      return box.values.toList();
    } catch (e) {
      debugPrint('Error getting workout plans: $e');
      return [];
    }
  }

  Future<void> clearAllData() async {
    try {
      await Hive.box<Workout>(workoutsBoxName).clear();
      await Hive.box<WorkoutPlan>(plansBoxName).clear();
      debugPrint('All data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  // Close boxes when app is closed
  Future<void> close() async {
    try {
      await Hive.close();
      _isInitialized = false;
      debugPrint('Hive storage closed successfully');
    } catch (e) {
      debugPrint('Error closing Hive storage: $e');
    }
  }
}