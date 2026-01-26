import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/achievements/domain/entities/achievement.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievementsAsync = ref.watch(achievementsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Başarımlar'),
      ),
      body: achievementsAsync.when(
        data: (achievements) {
          if (achievements.isEmpty) {
            return const Center(child: Text('Henüz başarım bulunmuyor.'));
          }

          final earnedCount = achievements.where((a) => a.isEarned).length;
          final totalPoints = achievements.where((a) => a.isEarned).fold<int>(0, (sum, a) => sum + a.points);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
                      const SizedBox(height: 16),
                      Text(
                        '$totalPoints Puan',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$earnedCount / ${achievements.length} Başarım Tamamlandı',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final achievement = achievements[index];
                      return _AchievementTile(
                        achievement: achievement,
                        isDark: isDark,
                      );
                    },
                    childCount: achievements.length,
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Hata: $e')),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  final bool isDark;

  const _AchievementTile({
    required this.achievement,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = achievement.isEarned ? const Color(0xFF6366F1) : Colors.grey;

    return Card(
      elevation: achievement.isEarned ? 2 : 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: achievement.isEarned ? color.withValues(alpha: 0.3) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: achievement.isEarned ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconData(achievement.iconName),
            color: achievement.isEarned ? color : Colors.grey,
          ),
        ),
        title: Text(
          achievement.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: achievement.isEarned ? null : Colors.grey,
          ),
        ),
        subtitle: Text(
          achievement.description,
          style: TextStyle(
            fontSize: 12,
            color: achievement.isEarned ? null : Colors.grey,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: achievement.isEarned ? Colors.amber.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '+${achievement.points}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: achievement.isEarned ? Colors.amber.shade800 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'user_check':
        return Icons.how_to_reg;
      case 'plus_circle':
        return Icons.add_circle;
      case 'list_check':
        return Icons.checklist;
      case 'trophy':
        return Icons.emoji_events;
      default:
        return Icons.star;
    }
  }
}
