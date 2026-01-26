import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/auth/domain/entities/user_profile.dart';
import 'package:subsnap/features/auth/domain/repositories/profile_repository.dart';

class SupabaseProfileRepository implements ProfileRepository {
  final SupabaseClient _client;

  SupabaseProfileRepository(this._client);

  @override
  Future<UserProfile?> getProfile(String id) async {
    try {
      final response = await _client.from('profiles').select().eq('id', id).maybeSingle();

      if (response == null) return null;

      return UserProfile.fromMap(response);
    } catch (e) {
      debugPrint('❌ [PROFILE_REPO] Error: $e');
      return null;
    }
  }

  @override
  Future<void> updateProfile(UserProfile profile) async {
    await _client.from('profiles').upsert(profile.toMap());
  }

  Future<void> upgradeToPro(String userId, DateTime expiry) async {
    await _client.from('profiles').update({
      'is_pro': true,
      'pro_expiry': expiry.toIso8601String(),
    }).eq('id', userId);
  }
}
