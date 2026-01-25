import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/subscriptions/domain/entities/payment.dart';

/// Kullanıcının tüm ödemelerini getir
final paymentsProvider = FutureProvider.autoDispose<List<Payment>>((ref) async {
  // Sadece user ID değiştiğinde rebuild et
  final userId = ref.watch(authUserProvider.select((state) => state.value?.id));

  if (userId == null) {
    debugPrint('❌ [PAYMENTS_PROVIDER] User is null');
    return [];
  }

  debugPrint('🔄 [PAYMENTS_PROVIDER] Fetching payments for user: $userId');

  try {
    final repo = ref.watch(paymentsRepositoryProvider);
    final results = await repo.fetchPayments(userId);
    debugPrint('✅ [PAYMENTS_PROVIDER] Found ${results.length} payments');
    return results;
  } catch (e) {
    debugPrint('❌ [PAYMENTS_PROVIDER] Error: $e');
    return [];
  }
});
