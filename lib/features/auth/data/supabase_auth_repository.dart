import 'package:subsnap/core/constants/supabase_keys.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/auth/domain/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
    StreamSubscription? subscription;
    try {
      // 1. Initialize Google Sign In (Native) - serverClientId zorunlu!
      await GoogleSignIn.instance.initialize(
        serverClientId: SupabaseKeys.googleWebClientId,
      );

      // 2. ÖNEMLİ: Authentication event listener'ı ÖNCE kur
      final completer = Completer<void>();
      bool isCompleted = false;

      subscription = GoogleSignIn.instance.authenticationEvents.listen(
        (event) async {
          if (isCompleted) return; // Duplicate event'leri önle

          final GoogleSignInAccount? user = switch (event) {
            GoogleSignInAuthenticationEventSignIn() => event.user,
            GoogleSignInAuthenticationEventSignOut() => null,
          };

          if (user != null) {
            try {
              isCompleted = true;
              
              debugPrint('✅ Native Google Sign-In başarılı: ${user.email}');

              // 3. Google'dan kullanıcı bilgilerini al
              final email = user.email;
              if (email.isEmpty) {
                subscription?.cancel();
                completer.completeError('Google hesabından email alınamadı.');
                return;
              }
              
              // Display name: Google'dan gelen veya email'den türet
              final displayName = (user.displayName?.trim().isNotEmpty == true) 
                  ? user.displayName!.trim() 
                  : email.split('@')[0];
              
              // Avatar URL: Google'dan gelen fotoğraf varsa kullan, yoksa dicebear'dan default oluştur
              final photoUrl = user.photoUrl;
              final avatarUrl = (photoUrl != null && photoUrl.isNotEmpty)
                  ? photoUrl
                  : 'https://api.dicebear.com/9.x/avataaars/svg?seed=${email.hashCode.abs()}';

              // 4. Supabase'de bu email ile kullanıcı var mı kontrol et
              // Google kullanıcıları için özel bir password pattern kullan
              final googlePassword = _generateSecurePassword(email);
              
              try {
                // Önce mevcut kullanıcıyla giriş yapmayı dene
                await _client.auth.signInWithPassword(
                  email: email,
                  password: googlePassword,
                );
                debugPrint('✅ Mevcut Google kullanıcı ile giriş yapıldı: $email');
                
                // Mevcut kullanıcı için profil bilgilerini kontrol et ve güncelle
                final currentUserAfterSignIn = _client.auth.currentUser;
                if (currentUserAfterSignIn != null) {
                  try {
                    // Mevcut profili kontrol et
                    final existingProfile = await _client
                        .from('profiles')
                        .select()
                        .eq('id', currentUserAfterSignIn.id)
                        .maybeSingle();
                    
                    // Eğer profil yoksa veya displayName boşsa, güncelle
                    if (existingProfile == null || 
                        (existingProfile['display_name'] as String? ?? '').trim().isEmpty) {
                      await _client.from('profiles').upsert({
                        'id': currentUserAfterSignIn.id,
                        'email': email,
                        'display_name': displayName,
                        'avatar_url': avatarUrl,
                      });
                      debugPrint('✅ Mevcut kullanıcı profili güncellendi: $email');
                    }
                  } catch (e) {
                    debugPrint('⚠️ Mevcut profil kontrolü/güncelleme hatası: $e');
                  }
                }
              } catch (signInError) {
                // Eğer "Invalid login credentials" hatası alırsak, kullanıcı yok demektir
                // Veya kullanıcı normal email/password ile kayıt olmuş olabilir
                final errorStr = signInError.toString().toLowerCase();
                if (errorStr.contains('invalid login') || 
                    errorStr.contains('invalid credentials') ||
                    errorStr.contains('email not confirmed')) {
                  // Kullanıcı yoksa veya farklı bir password ile kayıtlıysa, yeni oluştur
                  debugPrint('ℹ️ Kullanıcı bulunamadı veya farklı password, yeni Google kullanıcı oluşturuluyor: $email');
                  try {
                    await _client.auth.signUp(
                      email: email,
                      password: googlePassword,
                      data: {
                        'full_name': displayName,
                        'avatar_url': avatarUrl,
                      },
                    );
                    debugPrint('✅ Yeni Google kullanıcı oluşturuldu: $email');
                  } catch (signUpError) {
                    // Eğer kullanıcı zaten varsa (başka bir yöntemle kayıt olmuşsa)
                    // Email confirmation gerekebilir, bu durumda tekrar sign-in dene
                    debugPrint('⚠️ Sign-up hatası, kullanıcı zaten var olabilir: $signUpError');
                    // Tekrar sign-in dene (belki email confirmation gerekiyordu)
                    await _client.auth.signInWithPassword(
                      email: email,
                      password: googlePassword,
                    );
                  }
                } else {
                  // Beklenmeyen bir hata
                  rethrow;
                }
              }

              // 5. Profile'ı güncelle - Google ile giriş yapan kullanıcılar için default bilgileri set et
              final currentUser = _client.auth.currentUser;
              if (currentUser != null) {
                try {
                  // Profile'ı upsert et - displayName ve avatarUrl mutlaka set edilmeli
                  await _client.from('profiles').upsert({
                    'id': currentUser.id,
                    'email': email,
                    'display_name': displayName, // Mutlaka dolu olmalı
                    'avatar_url': avatarUrl, // Geçerli bir URL olmalı
                  });
                  debugPrint('✅ Profile güncellendi: $email (displayName: $displayName)');
                } catch (e) {
                  debugPrint('⚠️ Profile güncellenirken hata: $e');
                  // Hata olsa bile devam et, trigger zaten oluşturmuş olabilir
                }
              }

              subscription?.cancel();
              if (!completer.isCompleted) {
                completer.complete();
              }
            } catch (e) {
              subscription?.cancel();
              if (!completer.isCompleted) {
                completer.completeError(e);
              }
            }
          } else {
            isCompleted = true;
            subscription?.cancel();
            if (!completer.isCompleted) {
              completer.completeError('Kullanıcı giriş yapmayı iptal etti');
            }
          }
        },
        onError: (error) {
          isCompleted = true;
          subscription?.cancel();
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        },
      );

      // 3. Listener kurulduktan SONRA authenticate çağrısını yap
      // authenticate() çağrısı native pencereyi açar, event listener sonucu yakalar
      await GoogleSignIn.instance.authenticate();

      // 4. Timeout ekle (30 saniye) - event'in gelmesini bekle
      await completer.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          subscription?.cancel();
          throw TimeoutException('Google giriş işlemi zaman aşımına uğradı. Lütfen tekrar deneyin.');
        },
      );
    } on TimeoutException {
      rethrow;
    } catch (e) {
      subscription?.cancel();
      debugPrint('❌ [AUTH_REPO] Google Sign-In Error: $e');
      rethrow;
    }
  }

  // Google kullanıcıları için güvenli, deterministik password oluştur
  // Aynı email için her zaman aynı password'ü üretir (ama kullanıcı bunu bilmez)
  // Supabase maksimum 72 karakter password kabul eder
  String _generateSecurePassword(String email) {
    // Email ve sabit bir secret kullanarak deterministik bir hash oluştur
    final secret = 'subsnap_google_auth_secret_2024'; // Uygulama için sabit secret
    final input = '$email$secret';
    
    // SHA256 hash kullan (daha güvenli)
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    
    // Hex kullanarak daha uzun ve güvenli bir password oluşturalım
    final hex = digest.toString(); // SHA256 hex = 64 karakter (her zaman 64)
    
    // Hex'ten ilk 60 karakteri al
    final password = hex.substring(0, 60); // 60 karakter
    
    // En az bir büyük harf, küçük harf, sayı ve özel karakter olduğundan emin ol
    // Hex zaten sayı ve küçük harf içerir, büyük harf ve özel karakter ekleyelim
    return '${password}G!'; // 62 karakter - Supabase limitinin altında
  }

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Kullanıcı bulunamadı');
    }

    try {
      final userId = currentUser.id;
      
      debugPrint('🗑️ [AUTH_REPO] Kullanıcı hesabı siliniyor: $userId');
      
      // Profile'ı sil - cascade delete sayesinde otomatik olarak:
      // - subscriptions silinir (subscriptions -> profiles on delete cascade)
      // - payments silinir (payments -> subscriptions on delete cascade)
      // - user_achievements silinir (user_achievements -> profiles on delete cascade)
      await _client.from('profiles').delete().eq('id', userId);
      debugPrint('✅ [AUTH_REPO] Profil silindi (cascade delete ile tüm ilgili veriler otomatik silindi)');

      // Kısa bir delay ekle - dialog'un kapanması için zaman ver
      await Future.delayed(const Duration(milliseconds: 200));

      // Kullanıcıyı çıkış yaptır (bu router'ı tetikleyecek ve login'e yönlendirecek)
      await _client.auth.signOut();
      
      debugPrint('✅ [AUTH_REPO] Kullanıcı hesabı başarıyla silindi');
    } catch (e) {
      debugPrint('❌ [AUTH_REPO] Hesap silme hatası: $e');
      rethrow;
    }
  }
}
