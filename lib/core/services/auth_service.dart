import 'dart:developer';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/constants.dart';
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
    log('DEBUG: Starting Google Sign-In sequence');
    // Not: Web Client ID, Supabase Dashboard > Auth > Providers > Google kısmından alınmalı.
    const webClientId = AppConstants.googleWebClientId;
    log('DEBUG: Using Web Client ID: $webClientId');

    try {
      final googleSignIn = GoogleSignIn.instance;

      // Force disconnect and sign out to clear potentially stuck tokens
      try {
        await googleSignIn.disconnect();
        await googleSignIn.signOut();
      } catch (_) {}

      // Initialize with serverClientId
      // Note: scopes are configured via Google Cloud Console or defaults (email, profile)
      await googleSignIn.initialize(serverClientId: webClientId);
      log('DEBUG: Attempting Google authentication with initialized instance...');

      // Use authenticate() as signIn() is deprecated/removed in v7
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        log('DEBUG: Google Sign-In canceled by user.');
        return;
      }

      log('DEBUG: User authenticated: ${googleUser.email}');
      log('DEBUG: Fetching authentication tokens...');

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;

      log('DEBUG: idToken obtained: ${idToken != null ? "YES (Length: ${idToken.length})" : "NO"}');

      if (idToken == null) {
        throw 'Google idToken alınamadı.';
      }

      _logJwtDebug(idToken);

      log('DEBUG: Signing in to Supabase with idToken');
      // Supabase signInWithIdToken usually requires idToken.

      final response = await _client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken);

      log('DEBUG: Supabase sign-in response User ID: ${response.user?.id}');
    } on PlatformException catch (e, stack) {
      log('CRITICAL: Google Sign-In PlatformException!');
      log('Code: ${e.code}');
      log('Message: ${e.message}');
      log('Stacktrace: $stack');

      // Return user-friendly error for common Google Sign In errors
      if (e.code == 'network_error') {
        throw 'Lütfen internet bağlantınızı kontrol edin.';
      } else if (e.code == 'sign_in_canceled') {
        throw 'Giriş işlemi iptal edildi.';
      }

      throw 'Play hizmetleri ile ilgili bir hata oldu.';
    } catch (e, stack) {
      log('CRITICAL: General Google Sign-In error details: $e');
      log('Stacktrace: $stack');

      final errorStr = e.toString();
      // Check for specific Supabase/Google Auth errors
      if (errorStr.contains('AuthApiException') ||
          errorStr.contains('Bad ID token') ||
          errorStr.contains('Google idToken alınamadı')) {
        throw 'Play hizmetleri ile ilgili bir hata oldu.';
      }

      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    try {
      await _client.rpc('delete_user_account');
      await signOut();
    } catch (e) {
      log('Error deleting account: $e');
      rethrow;
    }
  }

  void _logJwtDebug(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        log('DEBUG: Token is not a valid JWT (3 parts expected).');
        return;
      }
      var payload = parts[1];
      // Normalize base64
      switch (payload.length % 4) {
        case 0:
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      log('DEBUG: --- JWT ANALYSIS ---');
      log('DEBUG: AUD (Audience): ${payloadMap['aud']}');
      log('DEBUG: ISS (Issuer):   ${payloadMap['iss']}');
      log('DEBUG: IAT (Issued At): ${DateTime.fromMillisecondsSinceEpoch((payloadMap['iat'] as int) * 1000)}');
      log('DEBUG: EXP (Expiration): ${DateTime.fromMillisecondsSinceEpoch((payloadMap['exp'] as int) * 1000)}');
      log('DEBUG: ---------------------');
    } catch (e) {
      log('DEBUG: Could not decode JWT for debug: $e');
    }
  }
}
