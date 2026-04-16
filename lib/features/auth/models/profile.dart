class UserProfile {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final bool isSpecialPremium;
  final bool notificationsEnabled;

  UserProfile({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.isSpecialPremium = false,
    this.notificationsEnabled = true,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      isSpecialPremium: json['is_special_remium'] ?? false,
      notificationsEnabled: json['notifications_enabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_special_remium': isSpecialPremium,
      'notifications_enabled': notificationsEnabled,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    bool? isSpecialPremium,
    bool? notificationsEnabled,
    bool clearAvatar = false,
  }) {
    return UserProfile(
      id: id,
      fullName: fullName ?? this.fullName,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      isSpecialPremium: isSpecialPremium ?? this.isSpecialPremium,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
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
