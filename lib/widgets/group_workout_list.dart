import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_workout_provider.dart';
import '../models/group_workout.dart';
import 'create_group_workout.dart';

class GroupWorkoutListPage extends StatefulWidget {
  @override
  _GroupWorkoutListPageState createState() => _GroupWorkoutListPageState();
}

class _GroupWorkoutListPageState extends State<GroupWorkoutListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Fetch data when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GroupWorkoutProvider>(context, listen: false).fetchGroupWorkouts();
      Provider.of<GroupWorkoutProvider>(context, listen: false).fetchInvites();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            Tab(text: 'Invitations'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkoutList(),
          _buildInvitationsList(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => CreateGroupWorkoutPage(),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildWorkoutList() {
    final provider = Provider.of<GroupWorkoutProvider>(context);

    if (provider.isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (provider.groupWorkouts.isEmpty) {
      return Center(
        child: Text('No group workouts yet. Create one!'),
      );
    }

    return ListView.builder(
      itemCount: provider.groupWorkouts.length,
      itemBuilder: (ctx, i) {
        final workout = provider.groupWorkouts[i];
        return _buildWorkoutItem(workout);
      },
    );
  }

  Widget _buildInvitationsList() {
    final provider = Provider.of<GroupWorkoutProvider>(context);

    if (provider.isLoadingInvites) {
      return Center(child: CircularProgressIndicator());
    }

    if (provider.invites.isEmpty) {
      return Center(
        child: Text('No invitations'),
      );
    }

    return ListView.builder(
      itemCount: provider.invites.length,
      itemBuilder: (ctx, i) {
        final invite = provider.invites[i];
        return _buildInviteItem(invite);
      },
    );
  }

  Widget _buildWorkoutItem(GroupWorkout workout) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: ListTile(
        title: Text(workout.name),
        subtitle: Text(
          'Date: ${workout.scheduledDate.toString().substring(0, 16)}\nParticipants: ${workout.participants.length}',
        ),
        trailing: Icon(Icons.fitness_center),
        onTap: () {
          // Navigate to workout details
        },
      ),
    );
  }

  Widget _buildInviteItem(GroupWorkout invite) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: ListTile(
        title: Text(invite.name),
        subtitle: Text(
          'Date: ${invite.scheduledDate.toString().substring(0, 16)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.check, color: Colors.green),
              onPressed: () => _acceptInvite(invite.id!),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.red),
              onPressed: () => _declineInvite(invite.id!),
            ),
          ],
        ),
        onTap: () {
          // Show invite details
        },
      ),
    );
  }

  void _acceptInvite(String workoutId) {
    Provider.of<GroupWorkoutProvider>(context, listen: false)
        .joinGroupWorkout(workoutId);
  }

  void _declineInvite(String workoutId) {
    Provider.of<GroupWorkoutProvider>(context, listen: false)
        .declineInvite(workoutId);
  }
}