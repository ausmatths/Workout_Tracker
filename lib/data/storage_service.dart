import 'package:hive_flutter/hive_flutter.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import '../models/exercise_result.dart';

class StorageService {
  static const String workoutsBoxName = 'workouts';
  static const String plansBoxName = 'workout_plans';

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(ExerciseResultAdapter());
    Hive.registerAdapter(WorkoutAdapter());
    Hive.registerAdapter(WorkoutPlanAdapter());

    // Open boxes
    await Hive.openBox<Workout>(workoutsBoxName);
    await Hive.openBox<WorkoutPlan>(plansBoxName);
  }

  // Workout methods
  Future<void> addWorkout(Workout workout) async {
    final box = Hive.box<Workout>(workoutsBoxName);
    await box.add(workout);
  }

  List<Workout> getWorkouts() {
    final box = Hive.box<Workout>(workoutsBoxName);
    return box.values.toList();
  }

  Future<void> deleteWorkout(int index) async {
    final box = Hive.box<Workout>(workoutsBoxName);
    await box.deleteAt(index);
  }

  // Workout Plan methods
  Future<void> addWorkoutPlan(WorkoutPlan plan) async {
    final box = Hive.box<WorkoutPlan>(plansBoxName);
    await box.add(plan);
  }

  List<WorkoutPlan> getWorkoutPlans() {
    final box = Hive.box<WorkoutPlan>(plansBoxName);
    return box.values.toList();
  }

  Future<void> deleteWorkoutPlan(int index) async {
    final box = Hive.box<WorkoutPlan>(plansBoxName);
    await box.deleteAt(index);
  }

  Future<void> clearAll() async {
    await Hive.box<Workout>(workoutsBoxName).clear();
    await Hive.box<WorkoutPlan>(plansBoxName).clear();
  }
}