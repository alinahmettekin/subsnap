import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'subscription_service.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
  User? get currentUser => _client.auth.currentUser;

  Future<void> signInWithPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String fullName) async {
    await _client.auth.signUp(email: email, password: password, data: {'full_name': fullName});
  }

  Future<void> signUpWithPassword(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await SubscriptionService.logOut();
    await _client.auth.signOut();
  }

  Future<void> signInWithGoogle() async {
    print('DEBUG: Starting Google Sign-In sequence');
    // Not: Web Client ID, Supabase Dashboard > Auth > Providers > Google kÄ±smÄ±ndan alÄ±nmalÄ±.
    const webClientId = '1094968780176-jb74d577pdoro7tpq92r61nvki048pqa.apps.googleusercontent.com';

    try {
      final googleSignIn = GoogleSignIn.instance;

      // Initialize GoogleSignIn with serverClientId (v7.x API)
      await googleSignIn.initialize(serverClientId: webClientId);

      print('DEBUG: Attempting Google authentication');

      // Authenticate user (v7.x API - only method available)
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        print('DEBUG: Google Sign-In user is null (cancelled)');
        throw 'Google giriÅŸi iptal edildi.';
      }

      print('DEBUG: Fetching authentication tokens');
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      print('DEBUG: idToken obtained: ${idToken != null}');

      if (idToken == null) {
        throw 'Google idToken alÄ±namadÄ±.';
      }

      print('DEBUG: Signing in to Supabase with idToken');
      final response = await _client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);

      print('DEBUG: Supabase sign-in response: ${response.user?.id}');
    } catch (e) {
      print('DEBUG: Google Sign-In error details: $e');
      rethrow;
    }
  }
}
