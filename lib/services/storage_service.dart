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
    Hive.registerAdapter(WorkoutAdapter());
    Hive.registerAdapter(ExerciseResultAdapter());
    Hive.registerAdapter(ExerciseAdapter());
    Hive.registerAdapter(WorkoutPlanAdapter());

    // Open boxes
    await Hive.openBox<Workout>(workoutsBoxName);
    await Hive.openBox<WorkoutPlan>(plansBoxName);
  }

  Future<void> saveWorkout(Workout workout) async {
    final box = Hive.box<Workout>(workoutsBoxName);
    await box.add(workout);
  }

  List<Workout> getAllWorkouts() {
    final box = Hive.box<Workout>(workoutsBoxName);
    return box.values.toList();
  }

  Future<void> saveWorkoutPlan(WorkoutPlan plan) async {
    final box = Hive.box<WorkoutPlan>(plansBoxName);
    await box.add(plan);
  }

  List<WorkoutPlan> getAllWorkoutPlans() {
    final box = Hive.box<WorkoutPlan>(plansBoxName);
    return box.values.toList();
  }

  Future<void> clearAllData() async {
    await Hive.box<Workout>(workoutsBoxName).clear();
    await Hive.box<WorkoutPlan>(plansBoxName).clear();
  }
}