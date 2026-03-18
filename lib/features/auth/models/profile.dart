class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final bool isPremium;

  UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.isPremium = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      isPremium: json['is_premium'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_premium': isPremium,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    bool? isPremium,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      isPremium: isPremium ?? this.isPremium,
    );
  }

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) {
      return fullName!;
    }
    // "user324234" pattern based on ID (shortened)
    return 'user${id.substring(0, 6)}';
  }
}
