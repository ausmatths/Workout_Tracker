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
    await Future.wait([
      _loadWorkouts(),
      _loadWorkoutPlans(),
    ]);
  }

  Future<void> _loadWorkouts() async {
    _workouts = await _repository.getRecentWorkouts(30); // Load last 30 days
    notifyListeners();
  }

  Future<void> _loadWorkoutPlans() async {
    _plans = await _repository.getAllWorkoutPlans();
    notifyListeners();
  }

  void selectWorkoutPlan(WorkoutPlan plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  Future<void> saveWorkout(Workout workout) async {
    await _repository.saveWorkout(workout);
    await _loadWorkouts();
  }

  Future<bool> downloadWorkoutPlan(String url) async {
    final plan = await _repository.downloadWorkoutPlan(url);
    if (plan != null) {
      await _loadWorkoutPlans();
      return true;
    }
    return false;
  }

  List<Workout> getWorkoutsForLastDays(int days) {
    final startDate = DateTime.now().subtract(Duration(days: days));
    return _workouts
        .where((workout) => workout.date.isAfter(startDate))
        .toList();
  }
}