import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/workout.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import 'storage_service.dart';

class WorkoutData extends ChangeNotifier {
  final StorageService _storage;
  List<Workout> _workouts = [];
  WorkoutPlan? _currentPlan;
  List<WorkoutPlan> _availablePlans = [];

  WorkoutData(this._storage) {
    _loadData();
  }

  List<Workout> get workouts => List.unmodifiable(_workouts);
  WorkoutPlan? get currentPlan => _currentPlan;
  List<WorkoutPlan> get availablePlans => List.unmodifiable(_availablePlans);

  void _loadData() {
    _workouts = _storage.getWorkouts()
      ..sort((a, b) => b.date.compareTo(a.date));
    _availablePlans = _storage.getWorkoutPlans();
    notifyListeners();
  }

  String? _validateWorkoutPlan(Map<String, dynamic> json) {
    if (!json.containsKey('name')) {
      return 'Missing "name" field';
    }
    if (!json.containsKey('exercises')) {
      return 'Missing "exercises" field';
    }
    if (!(json['exercises'] is List)) {
      return '"exercises" must be a list';
    }

    final exercises = json['exercises'] as List;
    for (var i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      if (!(exercise is Map<String, dynamic>)) {
        return 'Exercise at index $i must be an object';
      }
      if (!exercise.containsKey('name')) {
        return 'Exercise at index $i is missing "name"';
      }
      if (!exercise.containsKey('target')) {
        return 'Exercise at index $i is missing "target"';
      }
      if (!exercise.containsKey('unit')) {
        return 'Exercise at index $i is missing "unit"';
      }

      // Validate target is a number
      if (!(exercise['target'] is num)) {
        return 'Exercise "$i" target must be a number';
      }

      // Validate unit is one of the allowed values
      final unit = exercise['unit'].toString().toLowerCase();
      if (!['meters', 'seconds', 'repetitions'].contains(unit)) {
        return 'Exercise "$i" has invalid unit. Must be "meters", "seconds", or "repetitions"';
      }
    }

    return null; // No errors found
  }

  Future<bool> downloadWorkoutPlan(String url) async {
    try {
      print('Downloading from URL: $url');
      final response = await http.get(Uri.parse(url));

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        print('Failed to download: Status code ${response.statusCode}');
        return false;
      }

      final jsonData = json.decode(response.body);

      // Validate JSON structure
      final error = _validateWorkoutPlan(jsonData);
      if (error != null) {
        print('Validation error: $error');
        return false;
      }

      final exercises = (jsonData['exercises'] as List).map((e) => Exercise(
        name: e['name'],
        targetOutput: (e['target'] as num).toDouble(),
        unit: e['unit'],
      )).toList();

      final workoutPlan = WorkoutPlan(
        name: jsonData['name'],
        exercises: exercises,
      );

      await _storage.addWorkoutPlan(workoutPlan);
      _loadData();
      return true;
    } catch (e, stackTrace) {
      print('Error downloading workout plan: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  void selectWorkoutPlan(WorkoutPlan plan) {
    _currentPlan = plan;
    notifyListeners();
  }

  Future<void> addWorkout(Workout workout) async {
    await _storage.addWorkout(workout);
    _loadData();
  }

  List<Workout> getRecentWorkouts(int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return _workouts.where((w) => w.date.isAfter(startDate)).toList();
  }
}