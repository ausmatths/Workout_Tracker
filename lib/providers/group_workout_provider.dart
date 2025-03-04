import 'dart:async';
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

  // Stream subscriptions to manage
  StreamSubscription<List<GroupWorkout>>? _workoutsSubscription;
  StreamSubscription<List<GroupWorkout>>? _invitesSubscription;

  List<GroupWorkout> get groupWorkouts => _groupWorkouts;
  List<GroupWorkout> get invites => _invites;
  bool get isLoading => _isLoading;
  bool get isLoadingInvites => _isLoadingInvites;

  // Check authentication status
  bool get isAuthenticated => _authService.currentUser != null;

  Future<void> fetchGroupWorkouts() async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot fetch workouts - not authenticated');
      _groupWorkouts = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Cancel any existing subscription
      await _workoutsSubscription?.cancel();

      // Create new subscription
      _workoutsSubscription = _firestoreService
          .getGroupWorkoutsForUser(_authService.currentUser!.uid)
          .listen(
            (groupWorkouts) {
          _groupWorkouts = groupWorkouts;
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error fetching group workouts: $error');
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Exception setting up group workouts listener: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvites() async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot fetch invites - not authenticated');
      _invites = [];
      notifyListeners();
      return;
    }

    _isLoadingInvites = true;
    notifyListeners();

    try {
      // Cancel any existing subscription
      await _invitesSubscription?.cancel();

      // Create new subscription
      _invitesSubscription = _firestoreService
          .getGroupWorkoutInvitesForUser(_authService.currentUser!.uid)
          .listen(
            (invites) {
          _invites = invites;
          _isLoadingInvites = false;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('Error fetching invites: $error');
          _isLoadingInvites = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Exception setting up invites listener: $e');
      _isLoadingInvites = false;
      notifyListeners();
    }
  }

  Future<void> createGroupWorkout(GroupWorkout workout) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot create workout - not authenticated');
      return;
    }

    try {
      await _firestoreService.createGroupWorkout(workout);
    } catch (e) {
      debugPrint('Error creating group workout: $e');
      rethrow;
    }
  }

  Future<void> joinGroupWorkout(String workoutId) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot join workout - not authenticated');
      return;
    }

    try {
      await _firestoreService.joinGroupWorkout(
          workoutId, _authService.currentUser!.uid);
    } catch (e) {
      debugPrint('Error joining group workout: $e');
      rethrow;
    }
  }

  Future<void> declineInvite(String workoutId) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot decline invite - not authenticated');
      return;
    }

    try {
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
    } catch (e) {
      debugPrint('Error declining invite: $e');
      rethrow;
    }
  }

  Future<void> inviteUsersToWorkout(String workoutId, List<String> emails) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot invite users - not authenticated');
      throw Exception('You must be logged in to invite users');
    }

    // Log the attempt with details for debugging
    debugPrint('Attempting to invite users to workout $workoutId: ${emails.join(', ')}');

    try {
      // Check if the workout exists first
      final workout = await _firestoreService.getGroupWorkout(workoutId);
      if (workout == null) {
        debugPrint('Workout not found: $workoutId');
        throw Exception('Workout not found');
      }

      // Only allow creator to invite users
      if (workout.creatorId != _authService.currentUser!.uid) {
        debugPrint('Only the creator can invite users to this workout');
        throw Exception('Only the creator can invite users');
      }

      // Get user IDs from emails
      List<String> userIds = [];
      List<String> notFoundEmails = [];

      for (String email in emails) {
        debugPrint('Looking up user for email: $email');
        final user = await _firestoreService.getUserByEmail(email);
        if (user != null) {
          userIds.add(user.id);
          debugPrint('Found user ID: ${user.id} for email: $email');
        } else {
          notFoundEmails.add(email);
          debugPrint('No user found for email: $email');
        }
      }

      if (userIds.isEmpty) {
        throw Exception('No registered users found for the provided emails');
      }

      // Remove users who are already participants or invited
      userIds = userIds.where((id) =>
      !workout.participants.contains(id) &&
          !workout.invites.contains(id)
      ).toList();

      if (userIds.isEmpty) {
        throw Exception('All users are already participants or invited');
      }

      // Send the invitations
      debugPrint('Inviting users to workout: ${userIds.join(', ')}');
      await _firestoreService.inviteToGroupWorkout(workoutId, userIds);

      // Fetch updated data
      fetchGroupWorkouts();

      // Return message about not found users
      if (notFoundEmails.isNotEmpty) {
        debugPrint('Some users not found: ${notFoundEmails.join(', ')}');
      }
    } catch (e) {
      debugPrint('Error inviting users to workout: $e');
      rethrow;
    }
  }

  // Important: clean up subscriptions when the provider is disposed
  @override
  void dispose() {
    _workoutsSubscription?.cancel();
    _invitesSubscription?.cancel();
    super.dispose();
  }
}