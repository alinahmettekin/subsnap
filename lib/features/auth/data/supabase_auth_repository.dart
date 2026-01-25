import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/auth/domain/auth_repository.dart';
import 'dart:async';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository(this._client);

  @override
  Stream<String?> get authStateChanges => _client.auth.onAuthStateChange.map((event) => event.session?.user.id);

  @override
  String? get currentUser => _client.auth.currentUser?.id;

  @override
  Future<void> signUpWithEmail(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
    );
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
