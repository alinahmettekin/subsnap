import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';
import 'package:subsnap/features/subscriptions/domain/repositories/subscriptions_repository.dart';

class SupabaseSubscriptionsRepository implements SubscriptionsRepository {
  final SupabaseClient _client;

  SupabaseSubscriptionsRepository(this._client);

  @override
  Stream<List<Subscription>> getSubscriptions(String userId) {
    return _client
        .from('subscriptions')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('next_payment_date', ascending: true)
        .map((data) => data.map((e) => Subscription.fromMap(e)).toList());
  }

  @override
  Future<List<Subscription>> fetchSubscriptions(String userId) async {
    try {
      debugPrint('📡 [SUBSCRIPTIONS_REPO] Abonelikler getiriliyor (user_id: $userId)');
      final response = await _client
          .from('subscriptions')
          .select('*, categories(name)')
          .eq('user_id', userId)
          .order('next_payment_date', ascending: true);
      
      if (response.isEmpty) {
        debugPrint('⚠️ [SUBSCRIPTIONS_REPO] Response null döndü');
        return [];
      }
      
      final data = response as List<dynamic>;
      debugPrint('✅ [SUBSCRIPTIONS_REPO] ${data.length} kayıt bulundu');
      
      final subscriptions = data.map((e) {
        try {
          return Subscription.fromMap(e as Map<String, dynamic>);
        } catch (e, stackTrace) {
          debugPrint('❌ [SUBSCRIPTIONS_REPO] Subscription parse hatası: $e');
          debugPrint('❌ [SUBSCRIPTIONS_REPO] Stack trace: $stackTrace');
          debugPrint('❌ [SUBSCRIPTIONS_REPO] Raw data: $e');
          return null;
        }
      }).whereType<Subscription>().toList();
      
      debugPrint('✅ [SUBSCRIPTIONS_REPO] ${subscriptions.length} abonelik başarıyla parse edildi');
      return subscriptions;
    } catch (e, stackTrace) {
      debugPrint('❌ [SUBSCRIPTIONS_REPO] KRİTİK HATA!');
      debugPrint('❌ [SUBSCRIPTIONS_REPO] Hata mesajı: $e');
      debugPrint('❌ [SUBSCRIPTIONS_REPO] Hata tipi: ${e.runtimeType}');
      debugPrint('❌ [SUBSCRIPTIONS_REPO] Stack trace: $stackTrace');
      // Return empty list on error instead of crashing
      return [];
    }
  }

  @override
  Future<void> addSubscription(Subscription subscription) async {
    try {
      await _client.from('subscriptions').insert(subscription.toMap());
    } catch (e) {
      // Re-throw with more context
      throw Exception('Failed to add subscription: $e');
    }
  }

  @override
  Future<void> updateSubscription(Subscription subscription) async {
    try {
      debugPrint('📝 [SUBSCRIPTIONS_REPO] Abonelik güncelleniyor: ${subscription.name} (ID: ${subscription.id})');
      await _client.from('subscriptions').update(subscription.toMap()).eq('id', subscription.id);
      debugPrint('✅ [SUBSCRIPTIONS_REPO] Abonelik başarıyla güncellendi');
    } catch (e, stackTrace) {
      debugPrint('❌ [SUBSCRIPTIONS_REPO] Abonelik güncelleme hatası!');
      debugPrint('❌ [SUBSCRIPTIONS_REPO] Abonelik: ${subscription.name} (ID: ${subscription.id})');
      debugPrint('❌ [SUBSCRIPTIONS_REPO] Hata mesajı: $e');
      debugPrint('❌ [SUBSCRIPTIONS_REPO] Hata tipi: ${e.runtimeType}');
      debugPrint('❌ [SUBSCRIPTIONS_REPO] Stack trace: $stackTrace');
      // Re-throw with more context
      throw Exception('Failed to update subscription: $e');
    }
  }

  @override
  Future<void> deleteSubscription(String id) async {
    await _client.from('subscriptions').delete().eq('id', id);
  }

}
