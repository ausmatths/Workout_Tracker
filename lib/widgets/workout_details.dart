import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/workout.dart';
import '../services/workout_service.dart';

class WorkoutDetails extends StatelessWidget {
  final Workout workout;
  final int? index; // Optional index for deletion

  const WorkoutDetails({
    Key? key,
    required this.workout,
    this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Debug logging
    debugPrint('Building WorkoutDetails for date: ${DateFormat('yyyy-MM-dd').format(workout.date)}');
    debugPrint('Workout has ${workout.results.length} exercise results');

    // Calculate success rate with null safety
    final successRate = workout.results.isNotEmpty
        ? (workout.successfulResultsCount / workout.results.length * 100).toStringAsFixed(1)
        : '0.0';

    return Scaffold(
      appBar: AppBar(
        title: Text('Workout on ${DateFormat('yyyy-MM-dd').format(workout.date)}'),
        actions: [
          // Add delete option if index is provided
          if (index != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _confirmDelete(context),
              tooltip: 'Delete workout',
            ),
        ],
      ),
      body: workout.results.isEmpty
          ? _buildEmptyState(context)
          : Column(
        children: [
          // Summary card
          Card(
            margin: EdgeInsets.all(16),
            elevation: 4,
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
                    'Success rate: $successRate%',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getSuccessRateColor(double.parse(successRate)),
                    ),
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
                try {
                  final result = workout.results[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(
                        result.exercise.name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
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
                } catch (e) {
                  // Handle potential errors in the workout data
                  debugPrint('Error rendering exercise result at index $index: $e');
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.amber.shade100,
                    child: ListTile(
                      title: Text('Error displaying exercise'),
                      subtitle: Text('There was a problem with this exercise data'),
                      trailing: Icon(Icons.error_outline, color: Colors.amber),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget for empty state when no results are available
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No exercise results available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This workout has no recorded exercises',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog before deleting
  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Workout?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true && index != null) {
      try {
        final workoutService = Provider.of<WorkoutService>(context, listen: false);
        await workoutService.deleteWorkout(index!);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Workout deleted successfully')),
        );

        Navigator.of(context).pop(); // Return to previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting workout: $e')),
        );
      }
    }
  }

  // Get color based on success rate
  Color _getSuccessRateColor(double rate) {
    if (rate >= 80) {
      return Colors.green;
    } else if (rate >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}