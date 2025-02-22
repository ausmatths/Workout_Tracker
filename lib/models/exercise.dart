import 'package:hive/hive.dart';

part 'exercise.g.dart';

@HiveType(typeId: 0)
class Exercise extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double targetOutput;

  @HiveField(2)
  final String unit;

  Exercise({
    required this.name,
    required this.targetOutput,
    required this.unit,
  });
}