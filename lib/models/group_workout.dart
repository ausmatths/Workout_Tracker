import 'package:cloud_firestore/cloud_firestore.dart';
import 'workout.dart';

class GroupWorkout {
  final String? id;
  final String name;
  final String creatorId;
  final DateTime scheduledDate;
  final List<String> participants;
  final List<String> invites;
  final String workoutPlanId;
  final bool isCompleted;

  GroupWorkout({
    this.id,
    required this.name,
    required this.creatorId,
    required this.scheduledDate,
    required this.participants,
    required this.invites,
    required this.workoutPlanId,
    this.isCompleted = false,
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
    };
  }

  factory GroupWorkout.fromMap(Map<String, dynamic> map, String docId) {
    return GroupWorkout(
      id: docId,
      name: map['name'] ?? '',
      creatorId: map['creatorId'] ?? '',
      scheduledDate: (map['scheduledDate'] as Timestamp).toDate(),
      participants: List<String>.from(map['participants'] ?? []),
      invites: List<String>.from(map['invites'] ?? []),
      workoutPlanId: map['workoutPlanId'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
    );
  }
}