import 'package:hive/hive.dart';
import 'exercise.dart';

part 'exercise_result.g.dart';

@HiveType(typeId: 1)
class ExerciseResult extends HiveObject {
  @HiveField(0)
  final Exercise exercise;

  @HiveField(1)
  final double actualOutput;

  @HiveField(2)
  final bool isSuccessful;

  ExerciseResult({
    required this.exercise,
    required this.actualOutput,
    required this.isSuccessful,
  });

  factory ExerciseResult.withExercise({
    required Exercise exercise,
    required double achievedOutput,
  }) {
    return ExerciseResult(
      exercise: exercise,
      actualOutput: achievedOutput,
      isSuccessful: achievedOutput >= exercise.targetOutput,
    );
  }
}