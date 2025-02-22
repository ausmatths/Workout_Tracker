// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/data/storage_service.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/exercise_result.dart';
import 'package:workout_tracker/models/workout.dart';
import 'package:workout_tracker/models/workout_plan.dart';
import 'package:workout_tracker/widgets/workout_recording_page.dart';
import 'package:workout_tracker/widgets/workout_details.dart';
import 'package:workout_tracker/widgets/recent_performance_widget.dart';

class MockStorageService implements StorageService {
  List<WorkoutPlan> _plans = [];
  List<Workout> _workouts = [];

  @override
  Future<void> init() async {}

  @override
  List<WorkoutPlan> getWorkoutPlans() => _plans;

  @override
  Future<void> addWorkoutPlan(WorkoutPlan plan) async {
    _plans.add(plan);
  }

  @override
  Future<void> addWorkout(Workout workout) async {
    _workouts.add(workout);
  }

  @override
  List<Workout> getWorkouts() => _workouts;

  @override
  Future<void> deleteWorkout(int index) async {
    if (index < _workouts.length) {
      _workouts.removeAt(index);
    }
  }

  @override
  Future<void> deleteWorkoutPlan(int index) async {
    if (index < _plans.length) {
      _plans.removeAt(index);
    }
  }

  @override
  Future<void> clearAll() async {
    _plans.clear();
    _workouts.clear();
  }
}

void main() {
  group('App Widgets Tests', () {
    late MockStorageService mockStorage;
    late WorkoutData workoutData;

    setUp(() {
      mockStorage = MockStorageService();
      workoutData = WorkoutData(mockStorage);
    });

    testWidgets('WorkoutRecordingPage shows exercise inputs', (tester) async {
      final testPlan = WorkoutPlan(
        name: "Test Plan",
        exercises: [
          Exercise(
            name: "Push-ups",
            targetOutput: 20,
            unit: "repetitions",
          ),
        ],
      );

      workoutData.selectWorkoutPlan(testPlan);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: workoutData,
            child: const WorkoutRecordingPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Push-ups'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('WorkoutDetails shows workout information', (tester) async {
      final exercise = Exercise(
        name: "Push-ups",
        targetOutput: 20,
        unit: "repetitions",
      );

      final workout = Workout(
        date: DateTime.now(),
        results: [
          ExerciseResult(
            exercise: exercise,
            actualOutput: 25,
            isSuccessful: true,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: WorkoutDetails(workout: workout),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Push-ups'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('RecentPerformanceWidget shows performance data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: workoutData,
            child: const RecentPerformanceWidget(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Recent Performance'), findsOneWidget);
      expect(find.text('Last 7 Days'), findsOneWidget);
    });
  });
}