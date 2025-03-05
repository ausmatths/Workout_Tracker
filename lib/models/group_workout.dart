import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout.dart';

enum GroupWorkoutType {
  collaborative,
  competitive
}

class GroupWorkout {
  final String? id;
  final String name;
  final String creatorId;
  final DateTime scheduledDate;
  final List<String> participants;
  final List<String> invites;
  final String workoutPlanId;
  final bool isCompleted;
  final GroupWorkoutType type; // New field for workout type
  final Map<String, Map<String, double>>? results; // User ID -> {Exercise ID -> Result}
  final String? shareCode; // For sharing with others

  GroupWorkout({
    this.id,
    required this.name,
    required this.creatorId,
    required this.scheduledDate,
    required this.participants,
    required this.invites,
    required this.workoutPlanId,
    this.isCompleted = false,
    this.type = GroupWorkoutType.competitive, // Default to competitive
    this.results,
    this.shareCode,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'creatorId': creatorId,
      'scheduledDate': Timestamp.fromDate(scheduledDate),
      'participants': participants,
      'invites': invites,
      'workoutPlanId': workoutPlanId,
      'isCompleted': isCompleted,
      'type': type.toString(), // Store enum as string
      'results': results ?? {},
      'shareCode': shareCode,
    };
  }

  factory GroupWorkout.fromMap(Map<String, dynamic> map, String docId) {
    // Parse the workout type from string
    GroupWorkoutType workoutType = GroupWorkoutType.competitive;
    if (map['type'] != null) {
      try {
        workoutType = GroupWorkoutType.values.firstWhere(
              (e) => e.toString() == map['type'],
          orElse: () => GroupWorkoutType.competitive,
        );
      } catch (e) {
        // Default to competitive if parsing fails
      }
    }

    // Convert string results back to Map
    Map<String, Map<String, double>> parsedResults = {};
    if (map['results'] != null) {
      (map['results'] as Map).forEach((userId, exercises) {
        parsedResults[userId.toString()] = {};
        (exercises as Map).forEach((exerciseId, result) {
          parsedResults[userId]![exerciseId.toString()] = (result is num) ? result.toDouble() : 0.0;
        });
      });
    }

    return GroupWorkout(
      id: docId,
      name: map['name'] ?? '',
      creatorId: map['creatorId'] ?? '',
      scheduledDate: map['scheduledDate'] is Timestamp
          ? (map['scheduledDate'] as Timestamp).toDate()
          : DateTime.now(),
      participants: List<String>.from(map['participants'] ?? []),
      invites: List<String>.from(map['invites'] ?? []),
      workoutPlanId: map['workoutPlanId'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      type: workoutType,
      results: parsedResults,
      shareCode: map['shareCode'],
    );
  }

  // Helper methods for result calculations
  double getTotalResultForExercise(String exerciseId) {
    double total = 0;
    results?.forEach((userId, exercises) {
      if (exercises.containsKey(exerciseId)) {
        total += exercises[exerciseId]!;
      }
    });
    return total;
  }

  // Get user ranking for competitive workouts (1-based, where 1 is best)
  int getUserRankingForExercise(String userId, String exerciseId) {
    if (results == null || !results!.containsKey(userId) || !results![userId]!.containsKey(exerciseId)) {
      return participants.length; // Last place if no result
    }

    double userResult = results![userId]![exerciseId]!;
    int rank = 1;

    for (var otherUserId in results!.keys) {
      if (otherUserId != userId &&
          results![otherUserId]!.containsKey(exerciseId) &&
          results![otherUserId]![exerciseId]! > userResult) {
        rank++;
      }
    }

    return rank;
  }

  // Get overall user ranking (based on sum of results)
  int getUserOverallRanking(String userId) {
    if (results == null || !results!.containsKey(userId)) {
      return participants.length; // Last place if no results
    }

    double userTotal = 0;
    results![userId]!.forEach((_, value) => userTotal += value);

    int rank = 1;
    for (var otherUserId in results!.keys) {
      if (otherUserId != userId) {
        double otherTotal = 0;
        results![otherUserId]!.forEach((_, value) => otherTotal += value);

        if (otherTotal > userTotal) {
          rank++;
        }
      }
    }

    return rank;
  }

  // Create a copy of this group workout with updated fields
  GroupWorkout copyWith({
    String? id,
    String? name,
    String? creatorId,
    DateTime? scheduledDate,
    List<String>? participants,
    List<String>? invites,
    String? workoutPlanId,
    bool? isCompleted,
    GroupWorkoutType? type,
    Map<String, Map<String, double>>? results,
    String? shareCode,
  }) {
    return GroupWorkout(
      id: id ?? this.id,
      name: name ?? this.name,
      creatorId: creatorId ?? this.creatorId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      participants: participants ?? this.participants,
      invites: invites ?? this.invites,
      workoutPlanId: workoutPlanId ?? this.workoutPlanId,
      isCompleted: isCompleted ?? this.isCompleted,
      type: type ?? this.type,
      results: results ?? this.results,
      shareCode: shareCode ?? this.shareCode,
    );
  }
}