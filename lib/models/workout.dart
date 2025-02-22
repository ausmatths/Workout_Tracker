import 'package:hive/hive.dart';
import 'exercise_result.dart';

part 'workout.g.dart';

@HiveType(typeId: 2)
class Workout extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final List<ExerciseResult> results;

  Workout({
    required this.date,
    required this.results,
  });

  int get successfulResultsCount =>
      results.where((result) => result.isSuccessful).length;
}