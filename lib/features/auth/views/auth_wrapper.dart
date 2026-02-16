import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscriptions/views/navigation_container.dart';
import 'landing_view.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    // Listen for session changes to sync RevenueCat
    ref.listen(authStateProvider, (previous, next) {
      next.whenData((session) {
        if (session != null) {
          SubscriptionService.logIn(session.user.id);
        } else {
          SubscriptionService.logOut();
        }
      });
    });

    return authState.when(
      data: (session) {
        if (session != null) {
          return const NavigationContainer();
        }
        return const LandingView();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => const LandingView(),
    );
  }
}

final authStateProvider = StreamProvider((ref) {
  return ref.watch(authServiceProvider).authStateChanges.map((event) => event.session);
});
