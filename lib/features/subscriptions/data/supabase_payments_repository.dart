import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/subscriptions/domain/entities/payment.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/payments_repository.dart';

class SupabasePaymentsRepository implements PaymentsRepository {
  final SupabaseClient _client;

  SupabasePaymentsRepository(this._client);

  @override
  Future<List<Payment>> fetchPayments(String userId) async {
    try {
      debugPrint('💳 [PAYMENTS_REPO] Abonelikler getiriliyor (user_id: $userId)');
      // Önce kullanıcının aboneliklerini al
      final subscriptionsResponse = await _client.from('subscriptions').select('id').eq('user_id', userId);

      if (subscriptionsResponse.isEmpty) {
        debugPrint('⚠️ [PAYMENTS_REPO] Abonelik bulunamadı, boş dönülüyor');
        return [];
      }

      final subscriptionIds =
          (subscriptionsResponse as List).map((e) => (e as Map)['id']?.toString()).whereType<String>().toList();

      if (subscriptionIds.isEmpty) {
        return [];
      }

      debugPrint('💳 [PAYMENTS_REPO] ${subscriptionIds.length} abonelik için ödemeler isteniyor');

      // Standard filter: use .inFilter() or .filter('col', 'in', list)
      final response = await _client
          .from('payments')
          .select()
          .inFilter('subscription_id', subscriptionIds) // Correct usage
          .order('payment_date', ascending: false);

      final data = response as List<dynamic>;
      final payments = data
          .map((e) {
            try {
              return Payment.fromMap(e as Map<String, dynamic>);
            } catch (e) {
              debugPrint('❌ [PAYMENTS_REPO] Parse hatası: $e');
              return null;
            }
          })
          .whereType<Payment>()
          .toList();

      debugPrint('✅ [PAYMENTS_REPO] ${payments.length} ödeme bulundu');
      return payments;
    } catch (e, stack) {
      debugPrint('❌ [PAYMENTS_REPO] fetchPayments hatası: $e');
      debugPrint('Stack: $stack');
      return [];
    }
  }

  @override
  Future<List<Payment>> fetchPaymentsBySubscription(String subscriptionId) async {
    try {
      final response = await _client
          .from('payments')
          .select()
          .eq('subscription_id', subscriptionId)
          .order('payment_date', ascending: false);

      final data = response as List<dynamic>;
      return data
          .map((e) {
            try {
              return Payment.fromMap(e as Map<String, dynamic>);
            } catch (e) {
              return null;
            }
          })
          .whereType<Payment>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<void> createPayment(Payment payment) async {
    try {
      debugPrint('💳 [PAYMENTS_REPO] Ödeme kaydı oluşturuluyor...');
      debugPrint('   📅 Tarih: ${payment.paymentDate}');
      debugPrint('   💰 Tutar: ${payment.amount} ${payment.currency}');
      debugPrint('   🔗 Abonelik ID: ${payment.subscriptionId}');
      debugPrint('   🆔 Ödeme ID: ${payment.id}');

      await _client.from('payments').insert(payment.toMap());
      debugPrint('✅ [PAYMENTS_REPO] Ödeme kaydı başarıyla oluşturuldu');
    } catch (e, stackTrace) {
      debugPrint('❌ [PAYMENTS_REPO] Ödeme kaydı oluşturma hatası!');
      debugPrint('❌ [PAYMENTS_REPO] Ödeme ID: ${payment.id}');
      debugPrint('❌ [PAYMENTS_REPO] Abonelik ID: ${payment.subscriptionId}');
      debugPrint('❌ [PAYMENTS_REPO] Hata mesajı: $e');
      debugPrint('❌ [PAYMENTS_REPO] Hata tipi: ${e.runtimeType}');
      debugPrint('❌ [PAYMENTS_REPO] Stack trace: $stackTrace');
      throw Exception('Failed to create payment: $e');
    }
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    try {
      await _client.from('payments').delete().eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }
}
