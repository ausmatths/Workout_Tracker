import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../models/group_workout.dart';
import '../providers/workout_provider.dart';
import '../providers/group_workout_provider.dart';
import 'workout_recording_page.dart';

class StartWorkoutPage extends StatefulWidget {
  final WorkoutPlan workoutPlan;

  const StartWorkoutPage({Key? key, required this.workoutPlan}) : super(key: key);

  @override
  _StartWorkoutPageState createState() => _StartWorkoutPageState();
}

class _StartWorkoutPageState extends State<StartWorkoutPage> {
  WorkoutMode _selectedMode = WorkoutMode.solo;
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Start Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selected Plan: ${widget.workoutPlan.name}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            Text(
              'Choose Workout Mode:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            _buildModeSelection(),
            SizedBox(height: 24),
            _getModeDescription(),
            Spacer(),
            ElevatedButton(
              onPressed: _isCreating ? null : _startWorkout,
              child: _isCreating
                  ? CircularProgressIndicator()
                  : Text('Start Workout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Column(
      children: [
        RadioListTile<WorkoutMode>(
          title: Text('Solo Workout'),
          value: WorkoutMode.solo,
          groupValue: _selectedMode,
          onChanged: (value) {
            setState(() {
              _selectedMode = value!;
            });
          },
        ),
        RadioListTile<WorkoutMode>(
          title: Text('Collaborative Group Workout'),
          value: WorkoutMode.collaborative,
          groupValue: _selectedMode,
          onChanged: (value) {
            setState(() {
              _selectedMode = value!;
            });
          },
        ),
        RadioListTile<WorkoutMode>(
          title: Text('Competitive Group Workout'),
          value: WorkoutMode.competitive,
          groupValue: _selectedMode,
          onChanged: (value) {
            setState(() {
              _selectedMode = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _getModeDescription() {
    switch (_selectedMode) {
      case WorkoutMode.solo:
        return Text(
          'Solo workouts are saved locally on your device. Your results will be visible only to you.',
        );
      case WorkoutMode.collaborative:
        return Text(
          'Collaborative workouts allow multiple participants to contribute to a shared goal. Everyone\'s output gets added together for each exercise.',
        );
      case WorkoutMode.competitive:
        return Text(
          'Competitive workouts allow you to compete with others. Each person\'s output is recorded separately and used for ranking.',
        );
    }
  }

  Future<void> _startWorkout() async {
    setState(() {
      _isCreating = true;
    });

    try {
      if (_selectedMode == WorkoutMode.solo) {
        // Start a solo workout
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutRecordingPage(
              plan: widget.workoutPlan,
            ),
          ),
        );
      } else {
        // Create a group workout
        final groupWorkoutProvider = Provider.of<GroupWorkoutProvider>(context, listen: false);

        final workoutType = _selectedMode == WorkoutMode.collaborative
            ? GroupWorkoutType.collaborative
            : GroupWorkoutType.competitive;

        final shareCode = await groupWorkoutProvider.createGroupWorkoutWithType(
          '${widget.workoutPlan.name} Workout',
          widget.workoutPlan.name, // Using name instead of ID
          DateTime.now(),
          workoutType,
        );

        // Show success message with share code
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Group workout created!'),
                SizedBox(height: 4),
                Text('Share code: $shareCode', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                // Copy to clipboard functionality would go here
              },
            ),
            duration: Duration(seconds: 10),
          ),
        );

        // Navigate to recording page with group workout info
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WorkoutRecordingPage(
              plan: widget.workoutPlan,
              groupWorkoutCode: shareCode,
              workoutType: workoutType,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating workout: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

enum WorkoutMode {
  solo,
  collaborative,
  competitive,
}