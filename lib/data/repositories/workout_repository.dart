import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../storage_service.dart';
import '../../models/workout.dart';
import '../../models/workout_plan.dart';
import '../../models/exercise.dart';

class WorkoutRepository {
  final StorageService _storage;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  WorkoutRepository(this._storage);

  // Get current user ID
  String get userId => _auth.currentUser?.uid ?? '';

  // Check if a plan or workout belongs to current user
  bool _isUserData(dynamic item) {
    return item.userId == userId || item.userId == null || item.userId?.isEmpty == true;
  }

  // Workout Plans
  List<WorkoutPlan> getAllWorkoutPlans() {
    // Get only plans associated with the current user
    return _storage.getWorkoutPlans()
        .where(_isUserData)
        .toList();
  }

  Future<WorkoutPlan?> downloadWorkoutPlan(String url) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to download workout plan');
      }

      final jsonData = json.decode(response.body);

      // Create exercises from JSON
      final exercises = (jsonData['exercises'] as List).map((e) => Exercise(
        name: e['name'],
        targetOutput: (e['targetOutput'] as num).toDouble(),
        unit: e['unit'],
      )).toList();

      // Create workout plan with user ID
      final workoutPlan = WorkoutPlan(
        name: jsonData['name'],
        exercises: exercises,
        userId: userId, // Associate with current user
      );

      // Save to storage
      await _storage.addWorkoutPlan(workoutPlan);

      print('Downloaded workout plan for user: $userId');
      return workoutPlan;
    } catch (e) {
      print('Error downloading workout plan: $e');
      return null;
    }
  }

  // Workouts
  List<Workout> getAllWorkouts() {
    // Get only workouts associated with the current user
    return _storage.getWorkouts()
        .where(_isUserData)
        .toList();
  }

  List<Workout> getRecentWorkouts(int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return _storage.getWorkouts()
        .where((workout) =>
    _isUserData(workout) &&
        workout.date.isAfter(startDate))
        .toList();
  }

  Future<void> saveWorkout(Workout workout) async {
    // Ensure workout has the current user ID
    workout.userId = userId;
    print('Saving workout for user: $userId');
    await _storage.addWorkout(workout);
  }

  Future<void> deleteWorkout(int index) async {
    // Make sure we're only deleting user's own workouts
    final workouts = getAllWorkouts();
    if (index >= 0 && index < workouts.length) {
      final targetWorkout = workouts[index];
      print('Deleting workout for user: ${targetWorkout.userId}');
      await _storage.deleteWorkout(_storage.getWorkouts().indexOf(targetWorkout));
    }
  }

  Future<void> deleteWorkoutPlan(int index) async {
    // Make sure we're only deleting user's own workout plans
    final plans = getAllWorkoutPlans();
    if (index >= 0 && index < plans.length) {
      final targetPlan = plans[index];
      print('Deleting workout plan for user: ${targetPlan.userId}');
      await _storage.deleteWorkoutPlan(_storage.getWorkoutPlans().indexOf(targetPlan));
    }
  }
}