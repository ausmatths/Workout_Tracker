import 'package:hive/hive.dart';
import 'exercise_result.dart';

part 'workout.g.dart';

@HiveType(typeId: 2)
class Workout extends HiveObject {
  @HiveField(0)
  final DateTime date;

  @HiveField(1)
  final List<ExerciseResult> results;

  @HiveField(2)
  String? userId;

  Workout({
    required this.date,
    required this.results,
    this.userId,
  });

  int get successfulResultsCount =>
      results.where((result) => result.isSuccessful).length;
}