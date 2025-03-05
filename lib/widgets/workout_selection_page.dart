// lib/widgets/workout_selection_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_plan.dart';
import '../models/exercise.dart'; // Added import for Exercise
import '../providers/workout_provider.dart';
import 'start_workout_page.dart';

class WorkoutSelectionPage extends StatefulWidget {
  const WorkoutSelectionPage({Key? key}) : super(key: key);

  @override
  _WorkoutSelectionPageState createState() => _WorkoutSelectionPageState();
}

class _WorkoutSelectionPageState extends State<WorkoutSelectionPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWorkoutPlans();
  }

  Future<void> _loadWorkoutPlans() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load plans from provider
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
      // Use the public refreshData method instead of the private _loadWorkoutPlans
      workoutProvider.refreshData();
    } catch (e) {
      print('Error loading workout plans: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Workout Plan'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.plans.isEmpty) {
            return _buildEmptyState();
          }

          return _buildPlansList(provider.plans);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No workout plans available',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Create or download a workout plan to get started'),
          SizedBox(height: 24),
          ElevatedButton.icon(
            icon: Icon(Icons.download),
            label: Text('Download Sample Plan'),
            onPressed: () => _downloadSamplePlan(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansList(List<WorkoutPlan> plans) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return Card(
          margin: EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () => _selectWorkoutPlan(plan),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('Exercises: ${plan.exercises.length}'),
                  SizedBox(height: 4),
                  _buildExerciseList(plan.exercises),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _selectWorkoutPlan(plan),
                        child: Text('Start Workout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExerciseList(List<dynamic> exercises) {
    // Show first 3 exercises or less
    final displayCount = exercises.length > 3 ? 3 : exercises.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < displayCount; i++)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '• ${exercises[i].name}: ${exercises[i].targetOutput} ${exercises[i].unit}',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        if (exercises.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${exercises.length - 3} more exercises',
              style: TextStyle(color: Colors.grey[700], fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  void _selectWorkoutPlan(WorkoutPlan plan) {
    // Set selected plan in provider
    final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);
    workoutProvider.selectWorkoutPlan(plan);

    // Navigate to start workout page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartWorkoutPage(
          workoutPlan: plan,
        ),
      ),
    );
  }

  Future<void> _downloadSamplePlan() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final workoutProvider = Provider.of<WorkoutProvider>(context, listen: false);

      // Sample URL to a workout plan JSON - in a real app, this would be a valid URL
      const sampleUrl = 'https://example.com/sample-workout-plan.json';
      final success = await workoutProvider.downloadWorkoutPlan(sampleUrl);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sample plan downloaded successfully')),
        );
      } else {
        throw Exception('Failed to download sample plan');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}