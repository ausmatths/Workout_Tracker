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
  Map<String, String> _participantNames = {};

  // Stream subscriptions to manage
  StreamSubscription<List<GroupWorkout>>? _workoutsSubscription;
  StreamSubscription<List<GroupWorkout>>? _invitesSubscription;

  List<GroupWorkout> get groupWorkouts => _groupWorkouts;
  List<GroupWorkout> get invites => _invites;
  bool get isLoading => _isLoading;
  bool get isLoadingInvites => _isLoadingInvites;
  Map<String, String> get participantNames => _participantNames;

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

          // Fetch participant names
          _fetchParticipantNames(groupWorkouts);
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

  Future<void> _fetchParticipantNames(List<GroupWorkout> workouts) async {
    if (workouts.isEmpty) return;

    try {
      // Collect all unique user IDs from participants
      Set<String> allUserIds = {};
      for (var workout in workouts) {
        allUserIds.addAll(workout.participants);
        if (workout.results != null) {
          allUserIds.addAll(workout.results!.keys);
        }
      }

      // Fetch names for these users
      if (allUserIds.isNotEmpty) {
        final names = await _firestoreService.getParticipantNames(allUserIds.toList());
        _participantNames.addAll(names);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching participant names: $e');
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

  // Create a new group workout with type
  Future<String> createGroupWorkoutWithType(
      String name,
      String workoutPlanId,
      DateTime scheduledDate,
      GroupWorkoutType type) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot create workout - not authenticated');
      throw Exception('You must be logged in to create a group workout');
    }

    final userId = _authService.currentUser!.uid;

    final workout = GroupWorkout(
      name: name,
      creatorId: userId,
      scheduledDate: scheduledDate,
      participants: [userId], // Creator is automatically a participant
      invites: [],
      workoutPlanId: workoutPlanId,
      type: type,
      results: {},
    );

    try {
      final workoutId = await _firestoreService.createGroupWorkout(workout);

      // Generate a share code for the workout
      final shareCode = await _firestoreService.generateShareCodeForWorkout(workoutId);

      // Refresh data
      fetchGroupWorkouts();

      return shareCode;
    } catch (e) {
      debugPrint('Error creating group workout: $e');
      rethrow;
    }
  }

  // Legacy method for backward compatibility
  Future<void> createGroupWorkout(GroupWorkout workout) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot create workout - not authenticated');
      return;
    }

    try {
      await _firestoreService.createGroupWorkout(workout);
      fetchGroupWorkouts();
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
      fetchGroupWorkouts();
      fetchInvites();
    } catch (e) {
      debugPrint('Error joining group workout: $e');
      rethrow;
    }
  }

  // Join a group workout by share code
  Future<void> joinWorkoutByShareCode(String shareCode) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot join workout - not authenticated');
      throw Exception('You must be logged in to join a group workout');
    }

    try {
      // Find the workout with the share code
      final workout = await _firestoreService.getGroupWorkoutByShareCode(shareCode);

      if (workout == null) {
        throw Exception('No workout found with that code');
      }

      // Check if already a participant
      if (workout.participants.contains(_authService.currentUser!.uid)) {
        throw Exception('You are already a participant in this workout');
      }

      // Join the workout
      await _firestoreService.joinGroupWorkout(workout.id!, _authService.currentUser!.uid);

      // Refresh data
      fetchGroupWorkouts();
      fetchInvites();
    } catch (e) {
      debugPrint('Error joining workout by share code: $e');
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

        final updatedWorkout = workout.copyWith(invites: updatedInvites);

        await _firestoreService.updateGroupWorkout(workoutId, updatedWorkout);
        fetchInvites();
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

  // Submit results for a group workout
  Future<void> submitWorkoutResults(String workoutId, Map<String, double> results) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot submit results - not authenticated');
      throw Exception('You must be logged in to submit workout results');
    }

    try {
      await _firestoreService.submitGroupWorkoutResults(
          workoutId,
          _authService.currentUser!.uid,
          results
      );

      // Refresh data
      fetchGroupWorkouts();
    } catch (e) {
      debugPrint('Error submitting workout results: $e');
      rethrow;
    }
  }

  // Get a specific workout by ID
  Future<GroupWorkout?> getWorkoutById(String workoutId) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot get workout - not authenticated');
      return null;
    }

    try {
      return await _firestoreService.getGroupWorkout(workoutId);
    } catch (e) {
      debugPrint('Error getting workout: $e');
      rethrow;
    }
  }

  // Get a workout by share code
  Future<GroupWorkout?> getWorkoutByShareCode(String shareCode) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot get workout - not authenticated');
      return null;
    }

    try {
      return await _firestoreService.getGroupWorkoutByShareCode(shareCode);
    } catch (e) {
      debugPrint('Error getting workout by share code: $e');
      rethrow;
    }
  }

  // Mark a workout as completed
  Future<void> markWorkoutCompleted(String workoutId) async {
    if (!isAuthenticated) {
      debugPrint('GroupWorkoutProvider: Cannot update workout - not authenticated');
      return;
    }

    try {
      await _firestoreService.markGroupWorkoutCompleted(workoutId);
      fetchGroupWorkouts();
    } catch (e) {
      debugPrint('Error marking workout as completed: $e');
      rethrow;
    }
  }

  // Get participant name by ID
  String getParticipantName(String userId) {
    if (_participantNames.containsKey(userId)) {
      return _participantNames[userId]!;
    }

    // If we don't have the name yet, return a generic name and try to fetch it
    final currentUserId = _authService.currentUser?.uid;
    if (userId == currentUserId) {
      return 'You';
    }

    return 'User ${userId.substring(0, 5)}';
  }

  // Important: clean up subscriptions when the provider is disposed
  @override
  void dispose() {
    _workoutsSubscription?.cancel();
    _invitesSubscription?.cancel();
    super.dispose();
  }
}