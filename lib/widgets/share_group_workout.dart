// lib/widgets/share_group_workout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_plan.dart';
import '../models/group_workout.dart';
import 'workout_recording_page.dart';

class ShareGroupWorkoutPage extends StatelessWidget {
  final WorkoutPlan workoutPlan;
  final String shareCode;
  final bool isCollaborative;

  const ShareGroupWorkoutPage({
    Key? key,
    required this.workoutPlan,
    required this.shareCode,
    required this.isCollaborative,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Share Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isCollaborative ? Icons.group_work : Icons.emoji_events,
              size: 72,
              color: Theme.of(context).primaryColor,
            ),
            SizedBox(height: 24),
            Text(
              isCollaborative
                  ? 'New Collaborative Workout Created!'
                  : 'New Competition Created!',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Share this code with others to join:',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            _buildShareCodeDisplay(context),
            SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutRecordingPage(
                      plan: workoutPlan,
                      groupWorkoutCode: shareCode,
                      workoutType: isCollaborative
                          ? GroupWorkoutType.collaborative
                          : GroupWorkoutType.competitive,
                    ),
                  ),
                );
              },
              child: Text('Start Your Workout'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareCodeDisplay(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: shareCode));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code copied to clipboard')),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              shareCode,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.copy),
          ],
        ),
      ),
    );
  }
}