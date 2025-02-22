import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../data/workout_data.dart';
import 'workout_details.dart';
import 'workout_recording_page.dart';
import 'download_workout_page.dart';

class WorkoutHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout History'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _showDownloadPage(context),
          ),
        ],
      ),
      body: Consumer<WorkoutData>(
        builder: (context, workoutData, child) {
          if (workoutData.workouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'No workouts recorded yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showDownloadPage(context),
                    child: Text('Download a Workout Plan'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: workoutData.workouts.length,
            itemBuilder: (context, index) {
              final workout = workoutData.workouts[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(DateFormat('yyyy-MM-dd').format(workout.date)),
                  subtitle: Text(
                    'Results: ${workout.results.length}, Successful: ${workout.successfulResultsCount}',
                  ),
                  trailing: Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetails(workout: workout),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _startNewWorkout(context),
        child: Icon(Icons.add),
        tooltip: 'Start New Workout',
      ),
    );
  }

  void _showDownloadPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DownloadWorkoutPage()),
    );
  }

  void _startNewWorkout(BuildContext context) {
    final workoutData = context.read<WorkoutData>();

    if (workoutData.availablePlans.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('No Workout Plans'),
          content: Text('Please download a workout plan before starting a workout.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _showDownloadPage(context);
              },
              child: Text('Download Plan'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }

    if (workoutData.availablePlans.length == 1) {
      workoutData.selectWorkoutPlan(workoutData.availablePlans.first);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => WorkoutRecordingPage()),
      );
      return;
    }

    // Show plan selection dialog if multiple plans are available
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select Workout Plan'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: workoutData.availablePlans.length,
            itemBuilder: (context, index) {
              final plan = workoutData.availablePlans[index];
              return ListTile(
                title: Text(plan.name),
                subtitle: Text('${plan.exercises.length} exercises'),
                onTap: () {
                  workoutData.selectWorkoutPlan(plan);
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WorkoutRecordingPage()),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}