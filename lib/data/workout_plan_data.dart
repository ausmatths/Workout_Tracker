import '../models/workout_plan.dart';
import '../models/exercise.dart';

WorkoutPlan sampleWorkoutPlan = WorkoutPlan(
  name: 'Full Body Workout',
  exercises: [
    Exercise(name: 'Push-ups', targetOutput: 10, unit: 'repetitions'),
    Exercise(name: 'Plank', targetOutput: 60, unit: 'seconds'),
    Exercise(name: 'Run', targetOutput: 1000, unit: 'meters'),
    Exercise(name: 'Squats', targetOutput: 15, unit: 'repetitions'),
    Exercise(name: 'Bicep Curls', targetOutput: 12, unit: 'repetitions'),
    Exercise(name: 'Jumping Jacks', targetOutput: 30, unit: 'seconds'),
    Exercise(name: 'Swim', targetOutput: 200, unit: 'meters'),
  ],
);
