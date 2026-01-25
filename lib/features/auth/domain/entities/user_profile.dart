class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    };
  }
}
