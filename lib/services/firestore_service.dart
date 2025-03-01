import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/group_workout.dart';
import '../models/user_profile.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get users => _firestore.collection('users');
  CollectionReference get groupWorkouts => _firestore.collection('group_workouts');

  // Create user profile
  Future<void> createUserProfile(String userId, UserProfile profile) {
    return users.doc(userId).set(profile.toMap());
  }

  // Get user profile
  Future<UserProfile?> getUserProfile(String userId) async {
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
    final querySnapshot = await users
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null;
    }

    final doc = querySnapshot.docs.first;
    return UserProfile.fromMap({
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>
    });
  }

  // Create group workout
  Future<String> createGroupWorkout(GroupWorkout workout) async {
    final docRef = await groupWorkouts.add(workout.toMap());
    return docRef.id;
  }

  // Get group workout by ID
  Future<GroupWorkout?> getGroupWorkout(String id) async {
    final doc = await groupWorkouts.doc(id).get();
    if (doc.exists) {
      return GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  // Update group workout
  Future<void> updateGroupWorkout(String id, GroupWorkout workout) {
    return groupWorkouts.doc(id).update(workout.toMap());
  }

  // Get group workouts for user
  Stream<List<GroupWorkout>> getGroupWorkoutsForUser(String userId) {
    return groupWorkouts
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Get group workout invites for user
  Stream<List<GroupWorkout>> getGroupWorkoutInvitesForUser(String userId) {
    return groupWorkouts
        .where('invites', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => GroupWorkout.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  // Join group workout
  Future<void> joinGroupWorkout(String workoutId, String userId) async {
    // Remove from invites and add to participants
    return groupWorkouts.doc(workoutId).update({
      'participants': FieldValue.arrayUnion([userId]),
      'invites': FieldValue.arrayRemove([userId])
    });
  }

  // Invite users to group workout
  Future<void> inviteToGroupWorkout(String workoutId, List<String> userIds) {
    return groupWorkouts.doc(workoutId).update({
      'invites': FieldValue.arrayUnion(userIds)
    });
  }
}