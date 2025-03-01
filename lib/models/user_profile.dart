class UserProfile {
  final String id;
  final String displayName;
  final String email;
  final String? photoUrl;
  final List<String> friends;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.friends = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'friends': friends,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'],
      friends: List<String>.from(map['friends'] ?? []),
    );
  }
}