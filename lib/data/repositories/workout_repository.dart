import 'dart:convert';
import 'package:http/http.dart' as http;
import '../storage_service.dart';
import '../../models/workout.dart';
import '../../models/workout_plan.dart';
import '../../models/exercise.dart';

class WorkoutRepository {
  final StorageService _storage;

  WorkoutRepository(this._storage);

  // Workout Plans
  List<WorkoutPlan> getAllWorkoutPlans() {
    return _storage.getWorkoutPlans();
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

      // Create workout plan
      final workoutPlan = WorkoutPlan(
        name: jsonData['name'],
        exercises: exercises,
      );

      // Save to storage
      await _storage.addWorkoutPlan(workoutPlan);

      return workoutPlan;
    } catch (e) {
      print('Error downloading workout plan: $e');
      return null;
    }
  }

  // Workouts
  List<Workout> getAllWorkouts() {
    return _storage.getWorkouts();
  }

  List<Workout> getRecentWorkouts(int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return _storage.getWorkouts()
        .where((workout) => workout.date.isAfter(startDate))
        .toList();
  }

  Future<void> saveWorkout(Workout workout) async {
    await _storage.addWorkout(workout);
  }

  Future<void> deleteWorkout(int index) async {
    await _storage.deleteWorkout(index);
  }

  Future<void> deleteWorkoutPlan(int index) async {
    await _storage.deleteWorkoutPlan(index);
  }
}