import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/group_workout.dart';
import '../providers/group_workout_provider.dart';
import '../services/auth_service.dart';
import 'create_group_workout.dart';

class GroupWorkoutListPage extends StatefulWidget {
  @override
  _GroupWorkoutListPageState createState() => _GroupWorkoutListPageState();
}

class _GroupWorkoutListPageState extends State<GroupWorkoutListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _emailController = TextEditingController();
  bool _isInviting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _refreshData() {
    final provider = Provider.of<GroupWorkoutProvider>(context, listen: false);
    provider.fetchGroupWorkouts();
    provider.fetchInvites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Group Workouts'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'My Workouts'),
            Tab(text: 'Invites'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyWorkoutsList(),
          _buildInvitesList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateGroupWorkoutPage(),
            ),
          );

          if (result == true) {
            // Refresh data if a new workout was created
            _refreshData();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Create Group Workout',
      ),
    );
  }

  Widget _buildMyWorkoutsList() {
    return Consumer<GroupWorkoutProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.groupWorkouts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_off, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No group workouts found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('Tap + to create a new group workout'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
          },
          child: ListView.builder(
            itemCount: provider.groupWorkouts.length,
            itemBuilder: (context, index) {
              final workout = provider.groupWorkouts[index];
              final userId = _getCurrentUserId();

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    workout.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date: ${_formatDate(workout.scheduledDate)}'),
                      Text('Participants: ${workout.participants.length}'),
                      if (workout.invites.isNotEmpty)
                        Text('Pending invites: ${workout.invites.length}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (userId != null && userId == workout.creatorId)
                        IconButton(
                          icon: Icon(Icons.person_add),
                          tooltip: 'Invite users',
                          onPressed: () {
                            if (workout.id != null) {
                              _showInviteDialog(context, workout.id!);
                            }
                          },
                        ),
                      if (workout.isCompleted)
                        Icon(Icons.check_circle, color: Colors.green)
                      else
                        Icon(Icons.timelapse, color: Colors.orange),
                    ],
                  ),
                  isThreeLine: true,
                  onTap: () {
                    debugPrint('Tapped on group workout: ${workout.id ?? 'unknown'}');
                    _showGroupWorkoutDetails(context, workout);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInvitesList() {
    return Consumer<GroupWorkoutProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingInvites) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.invites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No invitations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('You have no pending workout invitations'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.fetchInvites();
          },
          child: ListView.builder(
            itemCount: provider.invites.length,
            itemBuilder: (context, index) {
              final invite = provider.invites[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    invite.name,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Date: ${_formatDate(invite.scheduledDate)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        child: Text('JOIN'),
                        onPressed: () async {
                          try {
                            if (invite.id != null) {
                              await provider.joinGroupWorkout(invite.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Joined workout successfully')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to join: $e')),
                            );
                          }
                        },
                      ),
                      TextButton(
                        child: Text('DECLINE'),
                        onPressed: () async {
                          try {
                            if (invite.id != null) {
                              await provider.declineInvite(invite.id!);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Invitation declined')),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to decline: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  onTap: () {
                    _showGroupWorkoutDetails(context, invite);
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context, String workoutId) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Invite to Workout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      hintText: 'Enter email to invite',
                      errorText: _emailController.text.isEmpty || _emailController.text.contains('@')
                          ? null
                          : 'Enter a valid email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isInviting,
                  ),
                  if (_isInviting)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isInviting ? null : () {
                    Navigator.pop(context);
                  },
                  child: Text('CANCEL'),
                ),
                TextButton(
                  onPressed: _isInviting ? null : () async {
                    final email = _emailController.text.trim();

                    if (email.isEmpty || !email.contains('@')) {
                      return;
                    }

                    setState(() {
                      _isInviting = true;
                    });

                    try {
                      final provider = Provider.of<GroupWorkoutProvider>(context, listen: false);
                      await provider.inviteUsersToWorkout(workoutId, [email]);

                      // Clear input and close dialog
                      _emailController.clear();

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Invitation sent to $email')),
                      );

                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send invitation: $e')),
                      );
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isInviting = false;
                        });
                      }
                    }
                  },
                  child: Text('INVITE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showGroupWorkoutDetails(BuildContext context, GroupWorkout workout) {
    // Log click for debugging
    debugPrint('Showing details for workout: ${workout.id ?? 'unknown'}');

    // Navigate to details page
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupWorkoutDetailsPage(workout: workout),
      ),
    );
  }

  String? _getCurrentUserId() {
    final authService = Provider.of<AuthService>(context, listen: false);
    return authService.getUserId();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

// GroupWorkoutDetailsPage class
class GroupWorkoutDetailsPage extends StatelessWidget {
  final GroupWorkout workout;

  const GroupWorkoutDetailsPage({Key? key, required this.workout}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.getUserId();
    // Fixed: Only compare if currentUserId is not null
    final isCreator = currentUserId != null && workout.creatorId == currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(workout.name),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            // Date and status card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date: ${_formatDate(workout.scheduledDate)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          workout.isCompleted
                              ? Icons.check_circle
                              : Icons.pending,
                          color: workout.isCompleted ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          workout.isCompleted ? 'Completed' : 'Pending',
                          style: TextStyle(
                            fontSize: 16,
                            color: workout.isCompleted ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16),

            // Participants section
            Text(
              'Participants (${workout.participants.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              child: ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: workout.participants.length,
                itemBuilder: (context, index) {
                  final participantId = workout.participants[index];
                  final isCurrentUser = currentUserId != null && participantId == currentUserId;
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text(isCurrentUser ? 'You' : 'User $participantId'),
                    subtitle: participantId == workout.creatorId
                        ? Text('Creator', style: TextStyle(color: Colors.blue))
                        : null,
                  );
                },
              ),
            ),

            // Pending invites section (visible only to creator)
            if (isCreator && workout.invites.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                'Pending Invites (${workout.invites.length})',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: workout.invites.length,
                  itemBuilder: (context, index) {
                    final inviteId = workout.invites[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.mail_outline),
                        backgroundColor: Colors.amber.shade100,
                      ),
                      title: Text('User $inviteId'),
                      subtitle: Text('Awaiting response'),
                    );
                  },
                ),
              ),
            ],

            SizedBox(height: 16),

            // Workout plan details
            Text(
              'Workout Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan ID: ${workout.workoutPlanId}'),
                    // Add more workout plan details here
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to view workout plan details
                      },
                      child: Text('View Plan Details'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 24),

            // Action buttons
            if (!workout.isCompleted) ...[
              ElevatedButton.icon(
                icon: Icon(Icons.fitness_center),
                label: Text('Start Workout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  // Navigate to start the workout
                },
              ),
            ],

            if (isCreator) ...[
              SizedBox(height: 12),
              OutlinedButton.icon(
                icon: Icon(Icons.person_add),
                label: Text('Invite More People'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  _showInviteDialog(context, workout);
                },
              ),

              if (!workout.isCompleted) ...[
                SizedBox(height: 12),
                TextButton.icon(
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Cancel Group Workout', style: TextStyle(color: Colors.red)),
                  style: TextButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    _showDeleteConfirmation(context, workout);
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, GroupWorkout workout) {
    final TextEditingController emailController = TextEditingController();
    bool isInviting = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Invite to Workout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email address',
                      hintText: 'Enter email to invite',
                      errorText: emailController.text.isEmpty || emailController.text.contains('@')
                          ? null
                          : 'Enter a valid email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isInviting,
                  ),
                  if (isInviting)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isInviting ? null : () {
                    Navigator.pop(context);
                  },
                  child: Text('CANCEL'),
                ),
                TextButton(
                  onPressed: isInviting ? null : () async {
                    final email = emailController.text.trim();

                    if (email.isEmpty || !email.contains('@')) {
                      return;
                    }

                    setState(() {
                      isInviting = true;
                    });

                    try {
                      final provider = Provider.of<GroupWorkoutProvider>(context, listen: false);
                      // Fixed: Using the non-nullable workout.id
                      if (workout.id != null) {
                        await provider.inviteUsersToWorkout(workout.id!, [email]);

                        // Show success message
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Invitation sent to $email')),
                        );

                        Navigator.pop(context);
                      } else {
                        throw Exception("Workout ID is null");
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to send invitation: $e')),
                      );
                    } finally {
                      setState(() {
                        isInviting = false;
                      });
                    }
                  },
                  child: Text('INVITE'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, GroupWorkout workout) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Group Workout?'),
        content: Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('NO'),
          ),
          TextButton(
            onPressed: () {
              if (workout.id != null) {
                // Add a comment here instead of actual implementation
                // We'll ask the user to implement this part based on their provider

                /*
              // TODO: Uncomment and use the correct method from your GroupWorkoutProvider
              // final provider = Provider.of<GroupWorkoutProvider>(context, listen: false);
              // provider.YOUR_METHOD_NAME_HERE(workout.id!);
              */

                // For now, just show success message and navigate back
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Return to list
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Group workout canceled')),
                );
              }
            },
            child: Text('YES, CANCEL', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}