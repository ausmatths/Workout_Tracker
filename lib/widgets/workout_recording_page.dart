import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/workout_data.dart';
import '../models/exercise.dart';
import '../models/workout.dart';
import '../models/exercise_result.dart';
import '../models/workout_plan.dart';
import '../models/group_workout.dart';
import '../providers/group_workout_provider.dart';

class WorkoutRecordingPage extends StatefulWidget {
  final WorkoutPlan? plan;
  final String? groupWorkoutCode;
  final GroupWorkoutType? workoutType;

  const WorkoutRecordingPage({
    Key? key,
    this.plan,
    this.groupWorkoutCode,
    this.workoutType,
  }) : super(key: key);

  @override
  _WorkoutRecordingPageState createState() => _WorkoutRecordingPageState();
}

class _WorkoutRecordingPageState extends State<WorkoutRecordingPage> {
  final Map<Exercise, double> _exerciseOutputs = {};
  WorkoutPlan? _currentPlan;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  GroupWorkout? _groupWorkout;

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
  }

  Future<void> _initializeWorkout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // If provided directly, use the passed plan
      if (widget.plan != null) {
        _currentPlan = widget.plan;
      } else {
        // Otherwise try to get it from the workout data
        final workoutData = context.read<WorkoutData>();
        _currentPlan = workoutData.currentPlan;
      }

      // If this is a group workout, try to load the workout from Firebase
      if (widget.groupWorkoutCode != null) {
        await _loadGroupWorkout();
      }

      // Initialize all exercises with 0.0
      if (_currentPlan != null) {
        for (var exercise in _currentPlan!.exercises) {
          _exerciseOutputs[exercise] = 0.0;
        }
      }
    } catch (e) {
      _errorMessage = "Error initializing workout: $e";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadGroupWorkout() async {
    try {
      final groupWorkoutProvider = Provider.of<GroupWorkoutProvider>(context, listen: false);
      _groupWorkout = await groupWorkoutProvider.getWorkoutByShareCode(widget.groupWorkoutCode!);

      if (_groupWorkout == null) {
        throw Exception("Group workout not found");
      }

      // Load the workout plan if not already loaded
      if (_currentPlan == null) {
        // In a real app, you'd fetch the plan from Firebase or your workout provider
        // For now we'll assume the plan is already passed
        if (_groupWorkout!.results != null) {
          // TODO: Pre-populate results from previous attempts if needed
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Record Workout')),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentPlan == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Record Workout')),
        body: Center(
          child: Text('No workout plan selected'),
        ),
      );
    }

    // Determine if this is a group workout
    final bool isGroupWorkout = widget.groupWorkoutCode != null;
    final String workoutTypeText = isGroupWorkout
        ? (widget.workoutType == GroupWorkoutType.collaborative
        ? 'Collaborative'
        : 'Competitive')
        : 'Solo';

    return Scaffold(
      appBar: AppBar(
        title: Text('Record: ${_currentPlan!.name}'),
        actions: [
          if (isGroupWorkout)
            Chip(
              label: Text(workoutTypeText),
              backgroundColor: widget.workoutType == GroupWorkoutType.collaborative
                  ? Colors.green.shade100
                  : Colors.orange.shade100,
            ),
          TextButton.icon(
            icon: Icon(Icons.check),
            label: Text('Finish'),
            onPressed: _isSaving ? null : () => _recordWorkout(context),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16.0),
        itemCount: _currentPlan!.exercises.length,
        itemBuilder: (context, index) {
          final exercise = _currentPlan!.exercises[index];
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

  Future<void> _recordWorkout(BuildContext context) async {
    if (_currentPlan == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final results = _currentPlan!.exercises.map((exercise) {
        final actualOutput = _exerciseOutputs[exercise] ?? 0.0;
        return ExerciseResult.withExercise(
          exercise: exercise,
          achievedOutput: actualOutput,
        );
      }).toList();

      // For group workout, submit to Firebase
      if (widget.groupWorkoutCode != null && _groupWorkout != null) {
        final groupWorkoutProvider = Provider.of<GroupWorkoutProvider>(context, listen: false);

        // Convert results to a map
        Map<String, double> resultsMap = {};
        for (int i = 0; i < _currentPlan!.exercises.length; i++) {
          final exercise = _currentPlan!.exercises[i];
          resultsMap[exercise.name] = _exerciseOutputs[exercise] ?? 0.0;
        }

        // Submit to Firebase
        await groupWorkoutProvider.submitWorkoutResults(_groupWorkout!.id!, resultsMap);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Results submitted successfully!'))
        );
      } else {
        // For solo workout, save locally
        final workout = Workout(
          date: DateTime.now(),
          results: results,
        );

        final workoutData = context.read<WorkoutData>();
        workoutData.addWorkout(workout);
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout: $e'))
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}