import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/workout_data.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/exercise_result.dart';
import '../models/workout_plan.dart';

class WorkoutRecordingPage extends StatefulWidget {
  const WorkoutRecordingPage({Key? key}) : super(key: key);

  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  final Map<Exercise, double> _exerciseOutputs = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final workoutData = context.read<WorkoutData>();
      final currentPlan = workoutData.currentPlan;

      if (currentPlan != null) {
        // Initialize all exercises with 0.0
        for (var exercise in currentPlan.exercises) {
          _exerciseOutputs[exercise] = 0.0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutData>(
      builder: (context, workoutData, child) {
        final WorkoutPlan? currentPlan = workoutData.currentPlan;

        if (currentPlan == null) {
          return Scaffold(
            appBar: AppBar(title: Text('Record Workout')),
            body: Center(
              child: Text('No workout plan selected'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Record: ${currentPlan.name}'),
            actions: [
              TextButton.icon(
                icon: Icon(Icons.check),
                label: Text('Finish'),
                onPressed: () => _recordWorkout(context),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          body: ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: currentPlan.exercises.length,
            itemBuilder: (context, index) {
              final exercise = currentPlan.exercises[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16.0),
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Target: ${exercise.targetOutput} ${exercise.unit}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 16),
                      _buildInput(exercise),
                      if (_exerciseOutputs[exercise] != null &&
                          _exerciseOutputs[exercise]! >= exercise.targetOutput)
                        Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Target achieved!',
                                style: TextStyle(color: Colors.green),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInput(Exercise exercise) {
    switch (exercise.unit.toLowerCase()) {
      case 'seconds':
        return TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Time in seconds',
            border: OutlineInputBorder(),
            suffixText: 'seconds',
          ),
          initialValue: _exerciseOutputs[exercise]?.toString() ?? '0',
          onChanged: (value) {
            setState(() {
              _exerciseOutputs[exercise] = double.tryParse(value) ?? 0.0;
            });
          },
        );

      case 'meters':
        return TextFormField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Distance in meters',
            border: OutlineInputBorder(),
            suffixText: 'meters',
          ),
          initialValue: _exerciseOutputs[exercise]?.toString() ?? '0',
          onChanged: (value) {
            setState(() {
              _exerciseOutputs[exercise] = double.tryParse(value) ?? 0.0;
            });
          },
        );

      case 'repetitions':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('0'),
                Text('${exercise.targetOutput.toInt() * 2}'),
              ],
            ),
            Slider(
              value: _exerciseOutputs[exercise] ?? 0.0,
              min: 0,
              max: exercise.targetOutput * 2,
              divisions: exercise.targetOutput.toInt() * 2,
              label: (_exerciseOutputs[exercise] ?? 0.0).round().toString(),
              onChanged: (value) {
                setState(() {
                  _exerciseOutputs[exercise] = value;
                });
              },
            ),
            Center(
              child: Text(
                '${(_exerciseOutputs[exercise] ?? 0.0).round()} repetitions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        );

      default:
        return Text('Unsupported unit type: ${exercise.unit}');
    }
  }

  void _recordWorkout(BuildContext context) {
    final workoutData = context.read<WorkoutData>();
    final currentPlan = workoutData.currentPlan;

    if (currentPlan == null) return;

    final results = currentPlan.exercises.map((exercise) {
      final actualOutput = _exerciseOutputs[exercise] ?? 0.0;
      return ExerciseResult.withExercise(
        exercise: exercise,
        achievedOutput: actualOutput,
      );
    }).toList();

    final workout = Workout(
      date: DateTime.now(),
      results: results,
    );

    workoutData.addWorkout(workout);
    Navigator.pop(context);
  }
}