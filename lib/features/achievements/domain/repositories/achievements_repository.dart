import 'package:subsnap/features/achievements/domain/entities/achievement.dart';

abstract class AchievementsRepository {
  Future<List<Achievement>> getAchievements(String userId);
  Future<Achievement?> earnAchievement(String userId, String achievementId);
  Future<List<Achievement>> checkAndAwardSubscriptionAchievements(String userId, int subCount);
  Future<Achievement?> checkAndAwardProfileAchievement(String userId);
}
