import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/achievements/domain/entities/achievement.dart';
import 'package:subsnap/features/achievements/domain/repositories/achievements_repository.dart';

class SupabaseAchievementsRepository implements AchievementsRepository {
  final SupabaseClient _client;

  SupabaseAchievementsRepository(this._client);

  @override
  Future<List<Achievement>> getAchievements(String userId) async {
    try {
      debugPrint('📡 [ACHIEVEMENTS_REPO] Fetching achievements for user: $userId');
      // Fetch all achievements
      final achievementsResponse = await _client.from('achievements').select().order('points', ascending: true);

      // Fetch user earned achievements
      final userEarnedResponse = await _client.from('user_achievements').select().eq('user_id', userId);

      final List<Map<String, dynamic>> achievements = List<Map<String, dynamic>>.from(achievementsResponse);
      final List<Map<String, dynamic>> earned = List<Map<String, dynamic>>.from(userEarnedResponse);

      debugPrint('✅ [ACHIEVEMENTS_REPO] Total: ${achievements.length}, Earned: ${earned.length}');

      return achievements.map((a) {
        final earnedData = earned.where((e) => e['achievement_id'] == a['id']).firstOrNull;
        return Achievement.fromMap(a,
            earnedAt: earnedData != null ? DateTime.parse(earnedData['earned_at'] as String) : null);
      }).toList();
    } catch (e) {
      debugPrint('❌ [ACHIEVEMENTS_REPO] Fetch Error: $e');
      return [];
    }
  }

  @override
  Future<Achievement?> earnAchievement(String userId, String achievementId) async {
    try {
      debugPrint('🎯 [ACHIEVEMENTS_REPO] Attempting to earn: $achievementId for user: $userId');

      // 1. Check if already earned
      final existing = await _client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      if (existing != null) {
        debugPrint('ℹ️ [ACHIEVEMENTS_REPO] Achievement already earned');
        return null;
      }

      // 2. Insert new achievement
      await _client.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': achievementId,
      });

      debugPrint('✅ [ACHIEVEMENTS_REPO] Achievement $achievementId awarded');

      // 3. Fetch achievement details to return
      final achievementData = await _client.from('achievements').select().eq('id', achievementId).single();
      return Achievement.fromMap(achievementData, earnedAt: DateTime.now());
    } catch (e) {
      debugPrint('❌ [ACHIEVEMENTS_REPO] Earn Error ($achievementId): $e');
      return null;
    }
  }

  @override
  Future<List<Achievement>> checkAndAwardSubscriptionAchievements(String userId, int subCount) async {
    debugPrint('🧐 [ACHIEVEMENTS_REPO] Checking sub achievements. Count: $subCount');
    final List<Achievement> newlyEarned = [];

    if (subCount >= 1) {
      final a = await earnAchievement(userId, 'first_sub');
      if (a != null) newlyEarned.add(a);
    }
    if (subCount >= 5) {
      final a = await earnAchievement(userId, 'five_subs');
      if (a != null) newlyEarned.add(a);
    }
    if (subCount >= 10) {
      final a = await earnAchievement(userId, 'ten_subs');
      if (a != null) newlyEarned.add(a);
    }

    return newlyEarned;
  }

  @override
  Future<Achievement?> checkAndAwardProfileAchievement(String userId) async {
    debugPrint('🧐 [ACHIEVEMENTS_REPO] Checking profile achievement for: $userId');
    return await earnAchievement(userId, 'profile_setup');
  }
}
