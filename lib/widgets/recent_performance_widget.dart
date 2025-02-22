import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/workout_data.dart';

class RecentPerformanceWidget extends StatelessWidget {
  const RecentPerformanceWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<WorkoutData>(
          builder: (context, workoutData, child) {
            final recentWorkouts = workoutData.getRecentWorkouts(7); // Last 7 days
            final totalWorkouts = recentWorkouts.length;
            final totalExercises = recentWorkouts.fold<int>(
              0,
                  (sum, workout) => sum + workout.results.length,
            );
            final successfulExercises = recentWorkouts.fold<int>(
              0,
                  (sum, workout) => sum + workout.successfulResultsCount,
            );
            final successRate = totalExercises > 0
                ? (successfulExercises / totalExercises * 100).toStringAsFixed(1)
                : '0.0';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.trending_up,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Performance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      'Last 7 Days',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Workouts',
                      value: totalWorkouts.toString(),
                      icon: Icons.fitness_center,
                    ),
                    _StatItem(
                      label: 'Exercises',
                      value: totalExercises.toString(),
                      icon: Icons.local_fire_department,
                    ),
                    _StatItem(
                      label: 'Success Rate',
                      value: '$successRate%',
                      icon: Icons.task_alt,
                    ),
                  ],
                ),
                if (totalWorkouts == 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'No workouts recorded in the last 7 days',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}