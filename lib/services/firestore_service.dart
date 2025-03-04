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
  Stream<List<GroupWorkout>> getGroupWorkoutsForUser(String userId) {
    if (!_ensureAuthenticated()) {
      // Return empty stream if not authenticated
      return Stream.value([]);
    }

    return groupWorkouts
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Get group workout invites for user
  Stream<List<GroupWorkout>> getGroupWorkoutInvitesForUser(String userId) {
    if (!_ensureAuthenticated()) {
      // Return empty stream if not authenticated
      return Stream.value([]);
    }

    return groupWorkouts
        .where('invites', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
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
}