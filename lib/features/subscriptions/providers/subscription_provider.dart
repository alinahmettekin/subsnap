import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';

part 'subscription_provider.g.dart';

class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository(this._client);

  Future<List<Subscription>> getSubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('subscriptions')
        .select()
        .eq('user_id', userId)
        .order('next_payment_date', ascending: true);

    return (response as List).map((json) => Subscription.fromJson(json)).toList();
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await _client.from('categories').select().order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> _ensureProfileExists() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
      if (response == null) {
        await _client.from('profiles').insert({
          'id': user.id,
          'full_name': user.userMetadata?['full_name'] ?? 'User',
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      // Silently ignore or log - preventing profile creation shouldn't always block
      print('DEBUG: Profile check/creation failed: $e');
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    await _ensureProfileExists();
    await _client.from('subscriptions').insert(subscription.toJson());
  }

  Future<void> deleteSubscription(String id) async {
    await _client.from('subscriptions').delete().eq('id', id);
  }

  Future<void> deleteSubscriptionWithPayments(String id) async {
    // First delete all payments associated with this subscription
    await _client.from('payments').delete().eq('subscription_id', id);
    // Then delete the subscription itself
    await _client.from('subscriptions').delete().eq('id', id);
  }
}

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(Supabase.instance.client);
}

@riverpod
Future<List<Subscription>> subscriptions(Ref ref) async {
  return ref.watch(subscriptionRepositoryProvider).getSubscriptions();
}

@riverpod
Future<List<Map<String, dynamic>>> categories(Ref ref) async {
  return ref.watch(subscriptionRepositoryProvider).getCategories();
}
