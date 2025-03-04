import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import '../data/storage_service.dart';
import '../services/auth_service.dart';

class WorkoutService {
  final StorageService _storage;
  final AuthService? _authService; // Optional for backward compatibility

  WorkoutService(this._storage, [this._authService]);

  // Check if user is authenticated
  bool get isAuthenticated => _authService?.isAuthenticated() ?? true;

  // Log operation with authentication status
  void _logOperation(String operation) {
    if (_authService != null) {
      debugPrint('WorkoutService: $operation (Auth: ${isAuthenticated ? 'Yes' : 'No'})');
    }
  }

  // Workout Plans
  List<WorkoutPlan> getWorkoutPlans() {
    _logOperation('Getting workout plans');
    try {
      return _storage.getWorkoutPlans();
    } catch (e) {
      debugPrint('Error getting workout plans: $e');
      return [];
    }
  }

  Future<bool> downloadWorkoutPlan(String url) async {
    _logOperation('Downloading workout plan');
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download workout plan (Status: ${response.statusCode})');
      }

      final jsonData = json.decode(response.body);
      if (jsonData == null || !jsonData.containsKey('exercises') || !jsonData.containsKey('name')) {
        throw Exception('Invalid workout plan format');
      }

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
      debugPrint('Workout plan downloaded and saved: ${workoutPlan.name}');
      return true;
    } catch (e) {
      debugPrint('Error downloading workout plan: $e');
      return false;
    }
  }

  // Workouts
  List<Workout> getWorkouts() {
    _logOperation('Getting all workouts');
    try {
      return _storage.getWorkouts();
    } catch (e) {
      debugPrint('Error getting workouts: $e');
      return [];
    }
  }

  List<Workout> getRecentWorkouts(int days) {
    _logOperation('Getting recent workouts for last $days days');
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));
      return _storage.getWorkouts()
          .where((workout) => workout.date.isAfter(startDate))
          .toList();
    } catch (e) {
      debugPrint('Error getting recent workouts: $e');
      return [];
    }
  }

  Future<void> saveWorkout(Workout workout) async {
    _logOperation('Saving workout');
    try {
      await _storage.addWorkout(workout);
      debugPrint('Workout saved successfully');
    } catch (e) {
      debugPrint('Error saving workout: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkout(int index) async {
    _logOperation('Deleting workout at index $index');
    try {
      await _storage.deleteWorkout(index);
      debugPrint('Workout deleted successfully');
    } catch (e) {
      debugPrint('Error deleting workout: $e');
      rethrow;
    }
  }

  Future<void> clearAll() async {
    _logOperation('Clearing all data');
    try {
      await _storage.clearAll();
      debugPrint('All data cleared successfully');
    } catch (e) {
      debugPrint('Error clearing data: $e');
      rethrow;
    }
  }

  // Get workout by index
  Workout? getWorkoutByIndex(int index) {
    _logOperation('Getting workout by index: $index');
    try {
      final workouts = _storage.getWorkouts();
      if (index >= 0 && index < workouts.length) {
        return workouts[index];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting workout by index: $e');
      return null;
    }
  }

  // Search workouts - adjust based on what properties your Workout model has
  List<Workout> searchWorkouts(String query) {
    _logOperation('Searching workouts: $query');
    try {
      final lowerQuery = query.toLowerCase();
      return _storage.getWorkouts().where((workout) {
        // Update this to use the actual properties of your Workout model
        final searchableText = workout.toString().toLowerCase();
        return searchableText.contains(lowerQuery);
      }).toList();
    } catch (e) {
      debugPrint('Error searching workouts: $e');
      return [];
    }
  }
}