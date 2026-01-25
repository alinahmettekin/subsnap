import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';

// Provides the list of subscriptions for the current user (manual refresh)
final subscriptionsProvider = FutureProvider.autoDispose<List<Subscription>>((ref) async {
  debugPrint('📥 [SUBSCRIPTIONS_PROVIDER] Başlatılıyor...');

  // Sadece user ID değiştiğinde rebuild et
  final userId = ref.watch(authUserProvider.select((state) => state.value?.id));

  if (userId == null) {
    debugPrint('❌ [SUBSCRIPTIONS_PROVIDER] Kullanıcı bulunamadı');
    return [];
  }

  debugPrint('✅ [SUBSCRIPTIONS_PROVIDER] Kullanıcı ID: $userId');

  try {
    debugPrint('📡 [SUBSCRIPTIONS_PROVIDER] Abonelikler getiriliyor...');
    final repo = ref.read(subscriptionsRepositoryProvider);
    final subscriptions = await repo.fetchSubscriptions(userId);
    debugPrint('✅ [SUBSCRIPTIONS_PROVIDER] ${subscriptions.length} abonelik bulundu');

    return subscriptions;
  } catch (e) {
    debugPrint('❌ [SUBSCRIPTIONS_PROVIDER] ERROR: $e');
    return [];
  }
});

// Computed: Total Monthly Cost
final totalMonthlyCostProvider = Provider.autoDispose<double>((ref) {
  final subsAsync = ref.watch(subscriptionsProvider);
  return subsAsync.maybeWhen(
    data: (subs) {
      double total = 0;
      for (var sub in subs) {
        switch (sub.billingCycle) {
          case BillingCycle.monthly:
            total += sub.amount;
            break;
          case BillingCycle.yearly:
            total += sub.amount / 12; // Yıllık -> aylık
            break;
          case BillingCycle.weekly:
            total += sub.amount * 4.33; // Haftalık -> aylık (ortalama 4.33 hafta/ay)
            break;
          case BillingCycle.daily:
            total += sub.amount * 30; // Günlük -> aylık (ortalama 30 gün/ay)
            break;
        }
      }
      return total;
    },
    orElse: () => 0.0,
  );
});

// Computed: Total Yearly Cost
final totalYearlyCostProvider = Provider.autoDispose<double>((ref) {
  final subsAsync = ref.watch(subscriptionsProvider);
  return subsAsync.maybeWhen(
    data: (subs) {
      double total = 0;
      for (var sub in subs) {
        switch (sub.billingCycle) {
          case BillingCycle.monthly:
            total += sub.amount * 12; // Aylık -> yıllık
            break;
          case BillingCycle.yearly:
            total += sub.amount; // Yıllık
            break;
          case BillingCycle.weekly:
            total += sub.amount * 52; // Haftalık -> yıllık (52 hafta/yıl)
            break;
          case BillingCycle.daily:
            total += sub.amount * 365; // Günlük -> yıllık (365 gün/yıl)
            break;
        }
      }
      return total;
    },
    orElse: () => 0.0,
  );
});

// Computed: Total Weekly Cost
final totalWeeklyCostProvider = Provider.autoDispose<double>((ref) {
  final subsAsync = ref.watch(subscriptionsProvider);
  return subsAsync.maybeWhen(
    data: (subs) {
      double total = 0;
      for (var sub in subs) {
        switch (sub.billingCycle) {
          case BillingCycle.monthly:
            total += sub.amount / 4.33; // Aylık -> haftalık
            break;
          case BillingCycle.yearly:
            total += sub.amount / 52; // Yıllık -> haftalık
            break;
          case BillingCycle.weekly:
            total += sub.amount; // Haftalık
            break;
          case BillingCycle.daily:
            total += sub.amount * 7; // Günlük -> haftalık (7 gün/hafta)
            break;
        }
      }
      return total;
    },
    orElse: () => 0.0,
  );
});

// Computed: Total Daily Cost
final totalDailyCostProvider = Provider.autoDispose<double>((ref) {
  final subsAsync = ref.watch(subscriptionsProvider);
  return subsAsync.maybeWhen(
    data: (subs) {
      double total = 0;
      for (var sub in subs) {
        switch (sub.billingCycle) {
          case BillingCycle.monthly:
            total += sub.amount / 30; // Aylık -> günlük (ortalama 30 gün/ay)
            break;
          case BillingCycle.yearly:
            total += sub.amount / 365; // Yıllık -> günlük (365 gün/yıl)
            break;
          case BillingCycle.weekly:
            total += sub.amount / 7; // Haftalık -> günlük (7 gün/hafta)
            break;
          case BillingCycle.daily:
            total += sub.amount; // Günlük
            break;
        }
      }
      return total;
    },
    orElse: () => 0.0,
  );
});
