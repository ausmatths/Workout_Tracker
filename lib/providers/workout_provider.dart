import 'package:flutter/foundation.dart';
import '../data/repositories/workout_repository.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';

class WorkoutProvider extends ChangeNotifier {
  final WorkoutRepository _repository;
  List<Workout> _workouts = [];
  List<WorkoutPlan> _plans = [];
  WorkoutPlan? _selectedPlan;

  WorkoutProvider(this._repository) {
    _loadInitialData();
  }

  List<Workout> get workouts => _workouts;
  List<WorkoutPlan> get plans => _plans;
  WorkoutPlan? get selectedPlan => _selectedPlan;

  Future<void> _loadInitialData() async {
    _loadWorkouts();
    _loadWorkoutPlans();
    notifyListeners();
  }

  void _loadWorkouts() {
    try {
      _workouts = _repository.getRecentWorkouts(30); // Load last 30 days
      print('Loaded ${_workouts.length} workouts');
    } catch (e) {
      print('Error loading workouts: $e');
      _workouts = [];
    }
  }

  void _loadWorkoutPlans() {
    try {
      _plans = _repository.getAllWorkoutPlans();
      print('Loaded ${_plans.length} workout plans');
    } catch (e) {
      print('Error loading workout plans: $e');
      _plans = [];
    }
  }

  void selectWorkoutPlan(WorkoutPlan plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  Future<void> saveWorkout(Workout workout) async {
    try {
      await _repository.saveWorkout(workout);
      _loadWorkouts();
      notifyListeners();
      print('Workout saved successfully');
    } catch (e) {
      print('Error saving workout: $e');
      rethrow;
    }
  }

  Future<bool> downloadWorkoutPlan(String url) async {
    try {
      final plan = await _repository.downloadWorkoutPlan(url);
      if (plan != null) {
        _loadWorkoutPlans();
        notifyListeners();
        print('Workout plan downloaded successfully');
        return true;
      }
      return false;
    } catch (e) {
      print('Error downloading workout plan: $e');
      return false;
    }
  }

  List<Workout> getWorkoutsForLastDays(int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return _workouts
        .where((workout) => workout.date.isAfter(startDate))
        .toList();
  }

  // Reload data (useful after auth state changes)
  void refreshData() {
    _loadWorkouts();
    _loadWorkoutPlans();
    notifyListeners();
    print('Workout data refreshed');
  }
}