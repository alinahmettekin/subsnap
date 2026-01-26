class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final int points;
  final DateTime? earnedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.points,
    this.earnedAt,
  });

  bool get isEarned => earnedAt != null;

  factory Achievement.fromMap(Map<String, dynamic> map, {DateTime? earnedAt}) {
    return Achievement(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      iconName: map['icon_name'] as String,
      points: map['points'] as int? ?? 0,
      earnedAt: earnedAt,
    );
  }
}
