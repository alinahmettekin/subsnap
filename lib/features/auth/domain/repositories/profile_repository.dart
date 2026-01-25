import 'package:subsnap/features/auth/domain/entities/user_profile.dart';

abstract class ProfileRepository {
  Future<UserProfile?> getProfile(String id);
  Future<void> updateProfile(UserProfile profile);
}
