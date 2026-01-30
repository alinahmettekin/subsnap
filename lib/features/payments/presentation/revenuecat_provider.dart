import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:subsnap/core/constants/revenuecat_config.dart';
import 'package:subsnap/core/providers.dart';

/// Syncs RevenueCat with auth user. Call logIn when user logs in.
final revenuecatAuthSyncProvider = Provider<void>((ref) {
  final authAsync = ref.watch(authUserProvider);
  final initialUser = authAsync.asData?.value;
  if (initialUser != null) {
    Purchases.logIn(initialUser.id); // Fire and forget for initial load
  }
  ref.listen(authUserProvider, (prev, next) async {
    final user = next.asData?.value;
    if (user != null) {
      try {
        await Purchases.logIn(user.id);
        if (kDebugMode) debugPrint('✅ [RevenueCat] Logged in user: ${user.id}');
      } catch (e) {
        if (kDebugMode) debugPrint('❌ [RevenueCat] logIn error: $e');
      }
    }
  });
});

/// Provider for RevenueCat customer info (subscription status).
final customerInfoProvider = StreamProvider<CustomerInfo?>((ref) async* {
  ref.watch(revenuecatAuthSyncProvider);
  try {
    final controller = StreamController<CustomerInfo?>.broadcast();
    void listener(CustomerInfo info) => controller.add(info);

    Purchases.addCustomerInfoUpdateListener(listener);

    ref.onDispose(() {
      Purchases.removeCustomerInfoUpdateListener(listener);
      controller.close();
    });

    final info = await Purchases.getCustomerInfo();
    controller.add(info);

    yield* controller.stream;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('❌ [RevenueCat] customerInfoProvider error: $e');
      debugPrint('$st');
    }
    yield null;
  }
});

/// Whether the user has active SubSnap Pro entitlement.
final hasProProvider = Provider<bool>((ref) {
  final info = ref.watch(customerInfoProvider).value;
  if (info == null) return false;
  return info.entitlements.all[RevenueCatConfig.proEntitlementId]?.isActive ?? false;
});

/// Async version for loading states.
final hasProAsyncProvider = FutureProvider<bool>((ref) async {
  final info = await Purchases.getCustomerInfo();
  return info.entitlements.all[RevenueCatConfig.proEntitlementId]?.isActive ?? false;
});
