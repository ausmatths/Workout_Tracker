import '../models/exercise.dart';
import '../models/exercise_result.dart';
import '../models/workout.dart';
import '../models/workout_plan.dart';

final basicWorkoutPlan = WorkoutPlan(
  name: 'Basic Workout',
  exercises: [
    Exercise(name: 'Push-ups', targetOutput: 20, unit: 'repetitions'),
    Exercise(name: 'Plank', targetOutput: 60, unit: 'seconds'),
    Exercise(name: 'Running', targetOutput: 1000, unit: 'meters'),
  ],
);

// Create some sample workout results
final sampleWorkouts = [
  Workout(
    date: DateTime.now().subtract(Duration(days: 1)),
    results: [
      ExerciseResult.withExercise(
        exercise: basicWorkoutPlan.exercises[0],
        achievedOutput: 22.0,
      ),
      ExerciseResult.withExercise(
        exercise: basicWorkoutPlan.exercises[1],
        achievedOutput: 45.0,
      ),
      ExerciseResult.withExercise(
        exercise: basicWorkoutPlan.exercises[2],
        achievedOutput: 1200.0,
      ),
    ],
  ),
  Workout(
    date: DateTime.now().subtract(Duration(days: 3)),
    results: [
      ExerciseResult.withExercise(
        exercise: basicWorkoutPlan.exercises[0],
        achievedOutput: 18.0,
      ),
      ExerciseResult.withExercise(
        exercise: basicWorkoutPlan.exercises[1],
        achievedOutput: 65.0,
      ),
      ExerciseResult.withExercise(
        exercise: basicWorkoutPlan.exercises[2],
        achievedOutput: 950.0,
      ),
    ],
  ),
];