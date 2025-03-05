import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/group_workout.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get groupWorkouts => _firestore.collection('group_workouts');

  // Check if authenticated before accessing Firestore
  bool _ensureAuthenticated() {
    if (_auth.currentUser == null) {
      debugPrint('FirestoreService: User is not authenticated. Cannot access Firestore.');
      return false;
    }
    return true;
  }

  // Create user profile
  Future<void> createUserProfile(String userId, UserProfile profile) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    return users.doc(userId).set(profile.toMap());
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    final doc = await users.doc(userId).get();
    if (doc.exists) {
      return UserProfile.fromMap({
        'id': userId,
        ...doc.data() as Map<String, dynamic>
      });
    }
    return null;
  }

  // Get user by email
  Future<UserProfile?> getUserByEmail(String email) async {
    if (_auth.currentUser == null) {
      debugPrint('FirestoreService: User is not authenticated. Cannot lookup email.');
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    debugPrint('Looking up user by email: $email');

    try {
      // Make sure email is trimmed and lowercased for consistent lookup
      final cleanEmail = email.trim().toLowerCase();

      final querySnapshot = await users
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      debugPrint('Email lookup results: ${querySnapshot.docs.length} documents found');

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      debugPrint('Found user with ID: ${doc.id} for email: $email');

      return UserProfile.fromMap({
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>
      });
    } catch (e) {
      debugPrint('Error looking up user by email: $e');
      rethrow;
    }
  }

  // Create group workout
  Future<String> createGroupWorkout(GroupWorkout workout) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    final docRef = await groupWorkouts.add(workout.toMap());
    return docRef.id;
  }

  // Get group workout by ID
  Future<GroupWorkout?> getGroupWorkout(String id) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    final doc = await groupWorkouts.doc(id).get();
    if (doc.exists) {
      return GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Update group workout
  Future<void> updateGroupWorkout(String id, GroupWorkout workout) {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    return groupWorkouts.doc(id).update(workout.toMap());
  }

  // Get group workouts for user
  Stream<List<GroupWorkout>> getGroupWorkoutsForUser(String userId, {bool useSecureQuery = false}) {
    if (!_ensureAuthenticated()) {
      // Return empty stream if not authenticated
      return Stream.value([]);
    }

    debugPrint('Getting group workouts for user: $userId (useSecureQuery: $useSecureQuery)');

    // Always use the secure query now for better performance and security
    return groupWorkouts
        .where('participants', arrayContains: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      debugPrint('Fetched ${snapshot.docs.length} group workouts');
      return snapshot.docs
          .map((doc) => GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Get group workout invites for user
  Stream<List<GroupWorkout>> getGroupWorkoutInvitesForUser(String userId, {bool useSecureQuery = false}) {
    if (!_ensureAuthenticated()) {
      // Return empty stream if not authenticated
      return Stream.value([]);
    }

    debugPrint('Getting group workout invites for user: $userId (useSecureQuery: $useSecureQuery)');

    // Always use the secure query now for better performance and security
    return groupWorkouts
        .where('invites', arrayContains: userId)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      debugPrint('Fetched ${snapshot.docs.length} group workout invites');
      return snapshot.docs
          .map((doc) => GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  // Join group workout
  Future<void> joinGroupWorkout(String workoutId, String userId) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    // Remove from invites and add to participants
    return groupWorkouts.doc(workoutId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'invites': FieldValue.arrayRemove([userId])
    });
  }

  // Invite users to group workout
  Future<void> inviteToGroupWorkout(String workoutId, List<String> userIds) {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    return groupWorkouts.doc(workoutId).update({
      'invites': FieldValue.arrayUnion(userIds)
    });
  }

  // Submit results for a group workout
  Future<void> submitGroupWorkoutResults(
      String workoutId, String userId, Map<String, double> results) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    // Update just this user's results
    return groupWorkouts.doc(workoutId).update({
      'results.$userId': results,
    });
  }

  // Get group workout by share code
  Future<GroupWorkout?> getGroupWorkoutByShareCode(String shareCode) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    try {
      debugPrint('Looking up workout by share code: $shareCode');
      final querySnapshot = await groupWorkouts
          .where('shareCode', isEqualTo: shareCode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        debugPrint('No workout found with share code: $shareCode');
        return null;
      }

      final doc = querySnapshot.docs.first;
      debugPrint('Found workout with ID: ${doc.id} for share code: $shareCode');
      return GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      debugPrint('Error getting workout by share code: $e');
      rethrow;
    }
  }

  // Generate unique share code for a group workout
  Future<String> generateShareCodeForWorkout(String workoutId) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    // Generate a unique 6-character code
    final random = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Excluded confusing chars
    String code;
    bool isUnique = false;

    do {
      code = String.fromCharCodes(
          Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
      );

      final querySnapshot = await groupWorkouts
          .where('shareCode', isEqualTo: code)
          .limit(1)
          .get();

      isUnique = querySnapshot.docs.isEmpty;
    } while (!isUnique);

    // Update the workout with the share code
    await groupWorkouts.doc(workoutId).update({'shareCode': code});
    return code;
  }

  // Mark a group workout as completed
  Future<void> markGroupWorkoutCompleted(String workoutId) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    return groupWorkouts.doc(workoutId).update({
      'isCompleted': true
    });
  }

  // Get all participants' names for a group workout
  Future<Map<String, String>> getParticipantNames(List<String> userIds) async {
    if (!_ensureAuthenticated()) {
      throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated'
      );
    }

    Map<String, String> names = {};

    // Batch get all users
    if (userIds.isNotEmpty) {
      // Split into chunks of 10 for batching (Firestore limit)
      for (int i = 0; i < userIds.length; i += 10) {
        final end = (i + 10 < userIds.length) ? i + 10 : userIds.length;
        final chunk = userIds.sublist(i, end);

        try {
          final snapshots = await Future.wait(
              chunk.map((id) => users.doc(id).get())
          );

          for (final doc in snapshots) {
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['displayName'] ?? 'User ${doc.id.substring(0, 5)}';
              names[doc.id] = name;
            }
          }
        } catch (e) {
          debugPrint('Error fetching user names: $e');
        }
      }
    }

    return names;
  }
}