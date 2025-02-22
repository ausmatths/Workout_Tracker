import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import '../data/storage_service.dart';

class WorkoutService {
  final StorageService _storage;

  WorkoutService(this._storage);

  // Workout Plans
  List<WorkoutPlan> getWorkoutPlans() {
    return _storage.getWorkoutPlans();
  }

  Future<bool> downloadWorkoutPlan(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download workout plan');
      }

      final jsonData = json.decode(response.body);
      final exercises = (jsonData['exercises'] as List)
          .map((e) => Exercise(
        name: e['name'],
        targetOutput: (e['targetOutput'] as num).toDouble(),
        unit: e['unit'],
      ))
          .toList();

      final workoutPlan = WorkoutPlan(
        name: jsonData['name'],
        exercises: exercises,
      );

      await _storage.addWorkoutPlan(workoutPlan);
      return true;
    } catch (e) {
      print('Error downloading workout plan: $e');
      return false;
    }
  }

  // Workouts
  List<Workout> getWorkouts() {
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

  Future<void> clearAll() async {
    await _storage.clearAll();
  }
}