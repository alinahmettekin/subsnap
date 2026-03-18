import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile.dart';
import '../views/auth_wrapper.dart';

final profileServiceProvider = Provider((ref) => ProfileService(Supabase.instance.client));

class ProfileService {
  final SupabaseClient _client;

  ProfileService(this._client);

  Future<UserProfile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    
    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  Future<void> updateFullName(String userId, String fullName) async {
    await _client
        .from('profiles')
        .update({'full_name': fullName})
        .eq('id', userId);
  }
  Future<String> uploadAvatar(String userId, Uint8List imageBytes, String extension) async {
    final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = 'avatars/$fileName';

    // 1. Clean up ALL old avatars before uploading new one to keep storage clean
    await _cleanupUserAvatars(userId);

    // 2. Upload new one
    await _client.storage.from('subsnap').uploadBinary(
      path,
      imageBytes,
      fileOptions: FileOptions(contentType: 'image/$extension', upsert: true),
    );

    final String publicUrl = _client.storage.from('subsnap').getPublicUrl(path);

    // 3. Update profile with new avatar URL
    await _client.from('profiles').update({'avatar_url': publicUrl}).eq('id', userId);

    return publicUrl;
  }

  Future<void> removeAvatar(String userId) async {
    // 1. Storage'dan dosyaları temizle
    await _cleanupUserAvatars(userId);

    // 2. DB'deki avatar_url'i temizle
    await _client.from('profiles').update({'avatar_url': null}).eq('id', userId);
  }

  Future<void> _cleanupUserAvatars(String userId) async {
    try {
      final List<FileObject> objects = await _client.storage.from('subsnap').list(path: 'avatars');
      final userFiles = objects.where((obj) => obj.name.startsWith(userId)).map((obj) => 'avatars/${obj.name}').toList();

      if (userFiles.isNotEmpty) {
        await _client.storage.from('subsnap').remove(userFiles);
      }
    } catch (e) {
      // Log error but don't fail the operation
      print('DEBUG: ProfileService._cleanupUserAvatars error: $e');
    }
  }
}

class UserProfileNotifier extends AsyncNotifier<UserProfile?> {
  @override
  Future<UserProfile?> build() async {
    // Watch auth state to re-trigger build on logout
    final authState = ref.watch(authStateProvider).value;
    final user = authState?.user ?? Supabase.instance.client.auth.currentUser;
    
    if (user == null) {
      return null;
    }

    final profileService = ref.read(profileServiceProvider);
    return profileService.getProfile(user.id);
  }

  Future<void> updateFullName(String fullName) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profileService = ref.read(profileServiceProvider);
    await profileService.updateFullName(user.id, fullName);

    // Update state locally without re-fetching from DB
    state = AsyncData(state.value?.copyWith(fullName: fullName));
  }

  Future<void> updateAvatar(Uint8List imageBytes, String extension) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profileService = ref.read(profileServiceProvider);
    final publicUrl = await profileService.uploadAvatar(user.id, imageBytes, extension);

    // Update state locally
    state = AsyncData(state.value?.copyWith(avatarUrl: publicUrl));
  }

  Future<void> removeAvatar() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final profileService = ref.read(profileServiceProvider);
    await profileService.removeAvatar(user.id);

    // Update state locally
    state = AsyncData(state.value?.copyWith(clearAvatar: true));
  }
}

final userProfileProvider =
    AsyncNotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
