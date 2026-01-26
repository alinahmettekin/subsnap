class UserProfile {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final bool isPro;
  final DateTime? proExpiry;

  UserProfile({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.isPro = false,
    this.proExpiry,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['display_name'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      isPro: map['is_pro'] as bool? ?? false,
      proExpiry: map['pro_expiry'] != null ? DateTime.parse(map['pro_expiry'] as String) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'is_pro': isPro,
      'pro_expiry': proExpiry?.toIso8601String(),
    };
  }

  bool get hasActivePro {
    if (isPro) return true;
    if (proExpiry == null) return false;
    // 3-day grace period
    final gracePeriodEnd = proExpiry!.add(const Duration(days: 3));
    return DateTime.now().isBefore(gracePeriodEnd);
  }
}
