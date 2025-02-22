// test/workout_recording_page_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:workout_tracker/data/workout_data.dart';
import 'package:workout_tracker/data/storage_service.dart';
import 'package:workout_tracker/models/exercise.dart';
import 'package:workout_tracker/models/workout.dart';
import 'package:workout_tracker/models/workout_plan.dart';
import 'package:workout_tracker/widgets/workout_recording_page.dart';

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
  group('WorkoutRecordingPage', () {
    late MockStorageService mockStorage;
    late WorkoutData workoutData;

    setUp(() {
      mockStorage = MockStorageService();
      workoutData = WorkoutData(mockStorage);
    });

    testWidgets('shows exercise inputs when plan is selected',
            (WidgetTester tester) async {
          // Create a test workout plan
          final testPlan = WorkoutPlan(
            name: "Test Plan",
            exercises: [
              Exercise(
                name: "Push-ups",
                targetOutput: 20,
                unit: "repetitions",
              ),
              Exercise(
                name: "Running",
                targetOutput: 1000,
                unit: "meters",
              ),
            ],
          );

          // Set the current plan
          workoutData.selectWorkoutPlan(testPlan);

          // Build our app and trigger a frame
          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider.value(
                value: workoutData,
                child: const WorkoutRecordingPage(),
              ),
            ),
          );

          // Wait for any animations to complete
          await tester.pumpAndSettle();

          // Debug: Print all text widgets
          find.byType(Text).evaluate().forEach((element) {
            final widget = element.widget as Text;
            print('Found text: "${widget.data}"');
          });

          // Verify that the exercises are shown
          expect(find.text('Push-ups'), findsOneWidget);
          expect(find.text('Running'), findsOneWidget);

          // Verify inputs exist
          expect(find.byType(Slider), findsOneWidget);
          expect(find.byType(TextFormField), findsWidgets);
        });

    testWidgets('shows no plan selected message when no plan is set',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: ChangeNotifierProvider.value(
                value: workoutData,
                child: const WorkoutRecordingPage(),
              ),
            ),
          );

          await tester.pumpAndSettle();
          expect(find.text('No workout plan selected'), findsOneWidget);
        });

    testWidgets('can record workout', (WidgetTester tester) async {
      // Create and select a test plan
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
          home: Scaffold(
            body: ChangeNotifierProvider.value(
              value: workoutData,
              child: const WorkoutRecordingPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Record some values
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);
      await tester.drag(slider, const Offset(50.0, 0.0));
      await tester.pumpAndSettle();

      // Find and tap the Finish button in the AppBar
      final finishButton = find.text('Finish');
      expect(finishButton, findsOneWidget);
      await tester.tap(finishButton);
      await tester.pumpAndSettle();

      // Verify workout was saved
      expect(mockStorage.getWorkouts().length, 1);
    });
  });
}