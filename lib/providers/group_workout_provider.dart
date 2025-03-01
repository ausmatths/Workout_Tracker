import 'package:flutter/foundation.dart';
import '../models/group_workout.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class GroupWorkoutProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  List<GroupWorkout> _groupWorkouts = [];
  List<GroupWorkout> _invites = [];
  bool _isLoading = false;
  bool _isLoadingInvites = false;

  List<GroupWorkout> get groupWorkouts => _groupWorkouts;
  List<GroupWorkout> get invites => _invites;
  bool get isLoading => _isLoading;
  bool get isLoadingInvites => _isLoadingInvites;

  Future<void> fetchGroupWorkouts() async {
    if (_authService.currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    _firestoreService
        .getGroupWorkoutsForUser(_authService.currentUser!.uid)
        .listen((groupWorkouts) {
      _groupWorkouts = groupWorkouts;
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> fetchInvites() async {
    if (_authService.currentUser == null) return;

    _isLoadingInvites = true;
    notifyListeners();

    _firestoreService
        .getGroupWorkoutInvitesForUser(_authService.currentUser!.uid)
        .listen((invites) {
      _invites = invites;
      _isLoadingInvites = false;
      notifyListeners();
    });
  }

  Future<void> createGroupWorkout(GroupWorkout workout) async {
    await _firestoreService.createGroupWorkout(workout);
  }

  Future<void> joinGroupWorkout(String workoutId) async {
    if (_authService.currentUser == null) return;

    await _firestoreService.joinGroupWorkout(
        workoutId, _authService.currentUser!.uid);
  }

  Future<void> declineInvite(String workoutId) async {
    if (_authService.currentUser == null) return;

    // Remove user from invites list
    final workout = await _firestoreService.getGroupWorkout(workoutId);
    if (workout != null) {
      final updatedInvites = workout.invites
          .where((id) => id != _authService.currentUser!.uid)
          .toList();

      final updatedWorkout = GroupWorkout(
        id: workout.id,
        name: workout.name,
        creatorId: workout.creatorId,
        scheduledDate: workout.scheduledDate,
        participants: workout.participants,
        invites: updatedInvites,
        workoutPlanId: workout.workoutPlanId,
        isCompleted: workout.isCompleted,
      );

      await _firestoreService.updateGroupWorkout(workoutId, updatedWorkout);
    }
  }

  Future<void> inviteUsersToWorkout(String workoutId, List<String> emails) async {
    // Get user IDs from emails
    List<String> userIds = [];

    for (String email in emails) {
      final user = await _firestoreService.getUserByEmail(email);
      if (user != null) {
        userIds.add(user.id);
      }
    }

    if (userIds.isNotEmpty) {
      await _firestoreService.inviteToGroupWorkout(workoutId, userIds);
    }
  }
}