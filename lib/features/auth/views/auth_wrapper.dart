import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../main.dart' show navigatorKey;
import '../../../core/services/auth_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscriptions/views/navigation_container.dart';
import 'landing_view.dart';
import 'reset_password_view.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  late final StreamSubscription<AuthState> _authSubscription;
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isPasswordRecovery = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
    _initAuthListener();
  }

  Future<void> _initDeepLinks() async {
    // Uygulama kapalıyken gelen link (kez açılış)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        debugPrint('DEBUG: Initial link: $initialLink');
        _handleLink(initialLink);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }

    // Uygulama açıkken gelen linkler
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        debugPrint('DEBUG: Incoming link: $uri');
        _handleLink(uri);
      },
      onError: (e) => debugPrint('Link error: $e'),
    );
  }

  void _handleLink(Uri uri) {
    // Fragment (#) içindeki parametreleri de kontrol et
    final fragment = uri.fragment;
    final queryParams = Uri.splitQueryString(fragment.isNotEmpty ? fragment : uri.query);
    final type = queryParams['type'];
    final error = queryParams['error'] ?? uri.queryParameters['error'];
    final errorCode = queryParams['error_code'] ?? uri.queryParameters['error_code'];

    debugPrint('DEBUG: Link type param: $type, error: $error, errorCode: $errorCode');

    if (error != null) {
      // Link hatalı veya süresi dolmuş
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = navigatorKey.currentContext;
        if (ctx != null && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(
                errorCode == 'otp_expired'
                    ? 'Şifre sıfırlama bağlantısı süresi dolmuş. Lütfen yeni bir bağlantı talep edin.'
                    : 'Geçersiz bağlantı. Lütfen tekrar deneyin.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      });
      return;
    }

    if (type == 'recovery') {
      if (mounted) setState(() => _isPasswordRecovery = true);
    }
  }

  void _initAuthListener() {
    _authSubscription = ref.read(authServiceProvider).authStateChanges.listen((data) {
      debugPrint('DEBUG STEP 1: Auth Event received: ${data.event}');
      debugPrint('DEBUG STEP 2: mounted=$mounted, _isPasswordRecovery=$_isPasswordRecovery');

      if (data.session != null) {
        SubscriptionService.logIn(data.session!.user.id);
      } else {
        SubscriptionService.logOut();
      }

      if (data.event == AuthChangeEvent.passwordRecovery) {
        debugPrint('DEBUG STEP 3: passwordRecovery caught! Calling setState...');
        // Pop all routes back to root so AuthWrapper's ResetPasswordView becomes visible
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
        if (mounted) {
          setState(() => _isPasswordRecovery = true);
          debugPrint('DEBUG STEP 4: setState called, _isPasswordRecovery=$_isPasswordRecovery');
        } else {
          debugPrint('DEBUG STEP 3b: NOT mounted! Cannot setState!');
        }
      } else if (data.event == AuthChangeEvent.userUpdated && _isPasswordRecovery) {
        if (mounted) setState(() => _isPasswordRecovery = false);
      } else if (data.event == AuthChangeEvent.signedOut) {
        if (mounted) setState(() => _isPasswordRecovery = false);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG BUILD: _isPasswordRecovery=$_isPasswordRecovery');
    if (_isPasswordRecovery) {
      debugPrint('DEBUG BUILD: Showing ResetPasswordView');
      return const ResetPasswordView();
    }

    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (session) {
        if (session != null) {
          return const NavigationContainer();
        }
        return const LandingView();
      },
      // Stream takılırsa veya hata olursa sonsuz spinner yerine direkt LandingView
      loading: () => const LandingView(),
      error: (error, stack) => const LandingView(),
    );
  }
}

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges.map((event) => event.session);
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
