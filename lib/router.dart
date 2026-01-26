import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/auth/presentation/login_screen.dart';
import 'package:subsnap/features/auth/presentation/profile_setup_screen.dart';
import 'package:subsnap/features/dashboard/presentation/dashboard_screen.dart';
import 'package:subsnap/features/layout/main_layout.dart';
import 'package:subsnap/features/settings/presentation/settings_screen.dart';
import 'package:subsnap/features/payments/presentation/payments_screen.dart';
import 'package:subsnap/features/subscriptions/presentation/add_subscription_screen.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription_template.dart';
import 'package:subsnap/features/analytics/presentation/analytics_screen.dart';
import 'package:subsnap/features/payments/presentation/paywall_screen.dart';
import 'package:subsnap/features/achievements/presentation/achievements_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Auth state değişikliklerini dinle ve router'ı refresh et
  // ref.listen provider'ın yeniden çalışmasını tetiklemez, sadece değişiklik olduğunda callback çalıştırır
  final refreshListenable = ValueNotifier<int>(0);

  ref.listen(authUserProvider, (_, __) {
    refreshListenable.value++;
  });

  ref.listen(userProfileProvider, (_, __) {
    refreshListenable.value++;
  });

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: false,
    refreshListenable: refreshListenable,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/setup-profile',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            redirect: (context, state) => '/home/dashboard',
          ),
          GoRoute(
            path: '/home/dashboard',
            builder: (context, state) => const DashboardScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) {
                  final template = state.extra as SubscriptionTemplate?;
                  return AddSubscriptionScreen(template: template);
                },
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final sub = state.extra as Subscription?;
                  if (sub == null) {
                    return const DashboardScreen();
                  }
                  return AddSubscriptionScreen(subscriptionToEdit: sub);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/home/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/home/analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/home/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/home/settings/edit-profile',
            builder: (context, state) => const ProfileSetupScreen(isEdit: true),
          ),
          GoRoute(
            path: '/home/settings/paywall',
            builder: (context, state) => const PaywallScreen(),
          ),
          GoRoute(
            path: '/home/settings/achievements',
            builder: (context, state) => const AchievementsScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      try {
        final authState = ref.read(authUserProvider);

        final currentPath = state.matchedLocation.isEmpty ? state.uri.path : state.matchedLocation;
        final uriPath = state.uri.path;
        debugPrint('🔄 [ROUTER] Redirect check: matched=$currentPath, uri=$uriPath');

        final isLoading = authState.isLoading;
        final hasUser = authState.value != null;
        final isLoginRoute = currentPath == '/login' || uriPath == '/login';
        final isSetupRoute = currentPath == '/setup-profile' || uriPath == '/setup-profile';
        final isHomeRoute = currentPath.startsWith('/home') || uriPath.startsWith('/home');

        if (isLoading) {
          if (isHomeRoute || isSetupRoute) return null;
          return null;
        }

        if (!hasUser) {
          if (isLoginRoute) return null;
          return '/login';
        }

        // Eğer kullanıcı varsa profil durumunu kontrol et
        final profileAsync = ref.read(userProfileProvider);

        // ÖNEMLİ: Eğer profil hala yükleniyorsa yönlendirme yapma, bekle.
        if (profileAsync.isLoading) {
          debugPrint('⏳ [ROUTER] Profile is loading, wait...');
          return null;
        }

        final profile = profileAsync.value;
        final needsSetup = profile == null || (profile.displayName?.trim().isEmpty ?? true);

        debugPrint('👤 [ROUTER] Profile state: needsSetup=$needsSetup, name="${profile?.displayName}"');

        if (needsSetup && !isSetupRoute) {
          debugPrint('⚠️ [ROUTER] Incomplete profile -> Redirect to /setup-profile');
          return '/setup-profile';
        }

        if (!needsSetup && isSetupRoute) {
          debugPrint('✅ [ROUTER] Profile complete -> Redirect to /home/dashboard');
          return '/home/dashboard';
        }

        if (isLoginRoute) {
          debugPrint('✅ [ROUTER] Already logged in -> Redirect to /home/dashboard');
          return '/home/dashboard';
        }

        return null;
      } catch (e) {
        debugPrint('❌ [ROUTER] Redirect error: $e');
        return null;
      }
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
});
