import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_workout_provider.dart';
import '../providers/workout_provider.dart';

class JoinGroupWorkoutPage extends StatefulWidget {
  @override
  _JoinGroupWorkoutPageState createState() => _JoinGroupWorkoutPageState();
}

class _JoinGroupWorkoutPageState extends State<JoinGroupWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  String _shareCode = '';
  bool _isJoining = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Group Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Enter the workout code shared by your friend:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 24),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Workout Code',
                  hintText: 'e.g., ABC123',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.characters,
                style: TextStyle(
                  fontSize: 24,
                  letterSpacing: 4,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a workout code';
                  }
                  if (value.length != 6) {
                    return 'Workout code should be 6 characters';
                  }
                  return null;
                },
                onSaved: (value) {
                  _shareCode = value!.toUpperCase();
                },
              ),
              if (_errorMessage.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red),
                ),
              ],
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isJoining ? null : _joinWorkout,
                child: _isJoining
                    ? CircularProgressIndicator()
                    : Text('Join Workout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _joinWorkout() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _formKey.currentState!.save();
    setState(() {
      _isJoining = true;
      _errorMessage = '';
    });

    try {
      final groupWorkoutProvider = Provider.of<GroupWorkoutProvider>(context, listen: false);
      await groupWorkoutProvider.joinWorkoutByShareCode(_shareCode);

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully joined workout!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }
}