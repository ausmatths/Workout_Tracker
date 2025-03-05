// lib/widgets/group_workout_results_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_workout.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart';
import '../providers/group_workout_provider.dart';
import '../providers/workout_provider.dart';
import '../services/auth_service.dart';

class GroupWorkoutResultsPage extends StatefulWidget {
  final String workoutId;

  const GroupWorkoutResultsPage({
    Key? key,
    required this.workoutId,
  }) : super(key: key);

  @override
  _GroupWorkoutResultsPageState createState() => _GroupWorkoutResultsPageState();
}

class _GroupWorkoutResultsPageState extends State<GroupWorkoutResultsPage> {
  bool _isLoading = true;
  GroupWorkout? _workout;
  WorkoutPlan? _workoutPlan;
  String? _userId;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadWorkoutData();
  }

  Future<void> _loadWorkoutData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Get current user ID
      final authService = Provider.of<AuthService>(context, listen: false);
      _userId = authService.currentUser?.uid;

      // Get group workout
      final groupWorkoutProvider = Provider.of<GroupWorkoutProvider>(context, listen: false);
      _workout = await groupWorkoutProvider.getWorkoutById(widget.workoutId);

      if (_workout == null) {
        throw Exception('Workout not found');
      }

      // Get workout plan
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

      // Since getWorkoutPlanById isn't defined, we need to get it by name
      _workoutPlan = workoutProvider.plans.firstWhere(
            (plan) => plan.name == _workout!.workoutPlanId,
        orElse: () => throw Exception('Workout plan not found'),
      );

      if (_workoutPlan == null) {
        throw Exception('Workout plan not found');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading workout: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Workout Results')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Workout Results')),
        body: Center(
          child: Text(_errorMessage, style: TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_workout == null || _workoutPlan == null || _userId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Workout Results')),
        body: Center(
          child: Text('Could not load workout data'),
        ),
      );
    }

    final isCollaborative = _workout!.type == GroupWorkoutType.collaborative;

    return Scaffold(
      appBar: AppBar(
        title: Text(isCollaborative ? 'Team Results' : 'Competition Results'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isCollaborative),
            SizedBox(height: 24),
            Text(
              'Participants: ${_workout!.participants.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 16),
            if (isCollaborative)
              _buildCollaborativeResults()
            else
              _buildCompetitiveResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCollaborative) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _workout!.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 8),
            Text(
              '${_workoutPlan!.name} - ${isCollaborative ? 'Collaborative' : 'Competitive'} Workout',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(
              'Date: ${_formatDate(_workout!.scheduledDate)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborativeResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Team Results',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 16),
        ...List.generate(_workoutPlan!.exercises.length, (index) {
          final exercise = _workoutPlan!.exercises[index];
          // Using exercise name as ID since Exercise doesn't have an id property
          final exerciseId = exercise.name;
          final totalResult = _workout!.getTotalResultForExercise(exerciseId);

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Target: ${exercise.targetOutput} ${exercise.unit}'),
                      Text(
                        'Team Total: ${totalResult.toStringAsFixed(1)} ${exercise.unit}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: totalResult >= exercise.targetOutput
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  if (_workout!.results != null &&
                      _workout!.results!.containsKey(_userId) &&
                      _workout!.results![_userId]!.containsKey(exerciseId))
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Your contribution: ${(_workout!.results![_userId]![exerciseId] ?? 0).toStringAsFixed(1)} ${exercise.unit}',
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: 24),
        _buildTeamSummary(),
      ],
    );
  }

  Widget _buildCompetitiveResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Competition Results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'Your Overall Rank: ${_workout!.getUserOverallRanking(_userId!)}/${_workout!.participants.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        ...List.generate(_workoutPlan!.exercises.length, (index) {
          final exercise = _workoutPlan!.exercises[index];
          // Using exercise name as ID
          final exerciseId = exercise.name;

          final hasResult = _workout!.results != null &&
              _workout!.results!.containsKey(_userId) &&
              _workout!.results![_userId]!.containsKey(exerciseId);

          final userResult = hasResult ? _workout!.results![_userId]![exerciseId] : 0.0;
          final userRank = _workout!.getUserRankingForExercise(_userId!, exerciseId);

          return Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          exercise.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRankColor(userRank),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Rank: $userRank/${_workout!.participants.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text('Target: ${exercise.targetOutput} ${exercise.unit}'),
                  SizedBox(height: 4),
                  Text(
                    'Your result: ${hasResult && userResult != null ? userResult.toStringAsFixed(1) : "Not recorded"} ${exercise.unit}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Top Performers:', style: TextStyle(fontWeight: FontWeight.w500)),
                  SizedBox(height: 8),
                  _buildTopPerformersForExercise(exerciseId),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTopPerformersForExercise(String exerciseId) {
    // Get all results for this exercise
    Map<String, double> exerciseResults = {};
    if (_workout!.results != null) {
      _workout!.results!.forEach((userId, results) {
        if (results.containsKey(exerciseId)) {
          exerciseResults[userId] = results[exerciseId]!;
        }
      });
    }

    // Sort by result (descending)
    final sortedEntries = exerciseResults.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 3 or all if less than 3
    final topPerformers = sortedEntries.take(3).toList();

    if (topPerformers.isEmpty) {
      return Text('No results recorded yet');
    }

    return Column(
      children: topPerformers.asMap().entries.map((entry) {
        final index = entry.key;
        final userId = entry.value.key;
        final result = entry.value.value;
        final isCurrentUser = userId == _userId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _getMedalColor(index),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                isCurrentUser ? 'You' : 'User ${userId.substring(0, 6)}',
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              Spacer(),
              Text(
                '${result.toStringAsFixed(1)} ${_workoutPlan!.exercises.firstWhere((e) => e.name == exerciseId).unit}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTeamSummary() {
    // Count total exercises with successful results
    int totalExercises = _workoutPlan!.exercises.length;
    int completedExercises = 0;

    for (var exercise in _workoutPlan!.exercises) {
      // Use exercise name as ID
      double totalResult = _workout!.getTotalResultForExercise(exercise.name);
      if (totalResult >= exercise.targetOutput) {
        completedExercises++;
      }
    }

    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Team Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Total participants: ${_workout!.participants.length}'),
            SizedBox(height: 4),
            Text(
              'Targets reached: $completedExercises of $totalExercises',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: completedExercises == totalExercises ? Colors.green : null,
              ),
            ),
            SizedBox(height: 4),
            LinearProgressIndicator(
              value: totalExercises > 0 ? completedExercises / totalExercises : 0,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                completedExercises == totalExercises ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return Colors.amber.shade700; // Gold
    if (rank == 2) return Colors.blueGrey.shade400; // Silver
    if (rank == 3) return Colors.brown.shade400; // Bronze
    return Colors.grey.shade600;
  }

  Color _getMedalColor(int position) {
    if (position == 0) return Colors.amber.shade700; // Gold
    if (position == 1) return Colors.blueGrey.shade400; // Silver
    if (position == 2) return Colors.brown.shade400; // Bronze
    return Colors.grey.shade600;
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}