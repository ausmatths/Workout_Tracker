// lib/widgets/create_group_workout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_workout.dart';
import '../providers/group_workout_provider.dart';
import '../services/auth_service.dart';
import '../data/storage_service.dart';

class CreateGroupWorkoutPage extends StatefulWidget {
  @override
  _CreateGroupWorkoutPageState createState() => _CreateGroupWorkoutPageState();
}

class _CreateGroupWorkoutPageState extends State<CreateGroupWorkoutPage> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _workoutPlanId = '';
  DateTime _scheduledDate = DateTime.now();
  List<String> _inviteEmails = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storage = Provider.of<StorageService>(context, listen: false);
    final workoutPlans = storage.getWorkoutPlans();

    if (workoutPlans.isNotEmpty && _workoutPlanId.isEmpty) {
      // Get first workout plan - adapt this to your model structure
      _workoutPlanId = workoutPlans.first.name; // Use name or another unique identifier
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Group Workout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Workout Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name for the workout';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _name = value!;
                  },
                ),
                SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(labelText: 'Workout Plan'),
                  value: _workoutPlanId.isNotEmpty ? _workoutPlanId : null,
                  items: workoutPlans.map((workoutPlan) {
                    return DropdownMenuItem(
                      value: workoutPlan.name, // Use name or another unique identifier
                      child: Text(workoutPlan.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _workoutPlanId = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a workout plan';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Scheduled Date: ${_scheduledDate.toString().substring(0, 16)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        // Keep the existing date picker code
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _scheduledDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(_scheduledDate),
                          );
                          if (time != null) {
                            setState(() {
                              _scheduledDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Text('Select Date/Time'),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text('Invite Friends (Enter email addresses)'),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _inviteEmails.length + 1,
                  itemBuilder: (ctx, index) {
                    if (index == _inviteEmails.length) {
                      return TextButton(
                        onPressed: () {
                          setState(() {
                            _inviteEmails.add('');
                          });
                        },
                        child: Text('Add Email'),
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration: InputDecoration(labelText: 'Email ${index + 1}'),
                            initialValue: _inviteEmails[index],
                            onChanged: (value) {
                              _inviteEmails[index] = value;
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _inviteEmails.removeAt(index);
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 30),
                if (_isLoading)
                  CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) {
                        return;
                      }
                      _formKey.currentState!.save();

                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final userId = authService.currentUser!.uid;
                        final groupWorkout = GroupWorkout(
                          name: _name,
                          creatorId: userId,
                          scheduledDate: _scheduledDate,
                          participants: [userId],
                          invites: [],
                          workoutPlanId: _workoutPlanId,
                        );

                        final provider = Provider.of<GroupWorkoutProvider>(context, listen: false);
                        // Store the workout
                        provider.createGroupWorkout(groupWorkout);

                        // Invite users (you would need the workout ID, but it's not available here)
                        // if (_inviteEmails.isNotEmpty) {
                        //   await provider.inviteUsersToWorkout(
                        //     workoutId,
                        //     _inviteEmails.where((email) => email.isNotEmpty).toList(),
                        //   );
                        // }

                        Navigator.of(context).pop();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating workout: ${e.toString()}')),
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    child: Text('Create Group Workout'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}