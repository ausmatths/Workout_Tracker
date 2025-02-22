import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/workout.dart';

class WorkoutDetails extends StatelessWidget {
  final Workout workout;

  const WorkoutDetails({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Workout on ${DateFormat('yyyy-MM-dd').format(workout.date)}'),
      ),
      body: Column(
        children: [
          // Summary card
          Card(
            margin: EdgeInsets.all(16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Total exercises: ${workout.results.length}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Successful exercises: ${workout.successfulResultsCount}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    'Success rate: ${(workout.successfulResultsCount / workout.results.length * 100).toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
          // Exercise results list
          Expanded(
            child: ListView.builder(
              itemCount: workout.results.length,
              itemBuilder: (context, index) {
                final result = workout.results[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(result.exercise.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target: ${result.exercise.targetOutput} ${result.exercise.unit}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Achieved: ${result.actualOutput} ${result.exercise.unit}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          result.isSuccessful ? Icons.check_circle : Icons.cancel,
                          color: result.isSuccessful ? Colors.green : Colors.red,
                        ),
                        Text(
                          result.isSuccessful ? 'Success' : 'Failed',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: result.isSuccessful ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}