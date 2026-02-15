import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription.dart';
import '../models/service.dart';

part 'subscription_provider.g.dart';

class SubscriptionRepository {
  final SupabaseClient _client;

  SubscriptionRepository(this._client);

  Future<List<Subscription>> getSubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['active', 'trial'])
          .order('next_payment_date', ascending: true);

      final data = (response as List).map((json) => Subscription.fromJson(json)).toList();
      log('DEBUG: Fetched ${data.length} active subscriptions');
      return data;
    } catch (e) {
      log('DEBUG: Error fetching subscriptions: $e');
      return [];
    }
  }

  Future<List<Subscription>> getArchivedSubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'cancelled')
          .order('updated_at', ascending: false);

      final data = (response as List).map((json) => Subscription.fromJson(json)).toList();
      log('DEBUG: Fetched ${data.length} archived subscriptions');
      return data;
    } catch (e) {
      log('DEBUG: Error fetching archived subscriptions: $e');
      return [];
    }
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client.from('subscriptions').select().eq('user_id', userId);

      final data = (response as List).map((json) => Subscription.fromJson(json)).toList();
      return data;
    } catch (e) {
      log('DEBUG: Error fetching all subscriptions: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _client.from('categories').select().order('name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      log('DEBUG: Error fetching categories: $e');
      return [];
    }
  }

  Future<List<Service>> getServices() async {
    try {
      final response = await _client.from('services').select().order('name', ascending: true);
      return (response as List).map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      log('DEBUG: Error fetching services: $e');
      return [];
    }
  }

  Future<void> addSubscription(Subscription subscription) async {
    log('DEBUG: Adding subscription: ${subscription.toJson()}');
    try {
      await _client.from('subscriptions').insert(subscription.toJson());
      log('DEBUG: Subscription added successfully');
    } catch (e) {
      log('DEBUG: Error adding subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _client.from('subscriptions').update({'status': 'cancelled'}).eq('id', id);
    } catch (e) {
      log('DEBUG: Error deleting subscription: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscriptionWithPayments(String id) async {
    try {
      await _client.from('subscriptions').delete().eq('id', id);
    } catch (e) {
      log('DEBUG: Error deleting subscription with payments: $e');
      rethrow;
    }
  }

  Future<void> updateSubscription(Subscription subscription) async {
    log('DEBUG: Updating subscription: ${subscription.toJson()}');
    try {
      await _client.from('subscriptions').update(subscription.toJson()).eq('id', subscription.id);
      log('DEBUG: Subscription updated successfully');
    } catch (e) {
      log('DEBUG: Error updating subscription: $e');
      rethrow;
    }
  }

  Future<void> updateSubscriptionDate(String id, DateTime newDate) async {
    try {
      await _client
          .from('subscriptions')
          .update({'next_payment_date': newDate.toIso8601String(), 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      log('Error updating subscription date: $e');
      rethrow;
    }
  }

  Future<void> restoreSubscription(String id) async {
    try {
      await _client.from('subscriptions').update({'status': 'active'}).eq('id', id);
    } catch (e) {
      log('DEBUG: Error restoring subscription: $e');
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
SubscriptionRepository subscriptionRepository(Ref ref) {
  return SubscriptionRepository(Supabase.instance.client);
}

@riverpod
Future<List<Subscription>> subscriptions(Ref ref) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(seconds: 5), () {
    link.close();
  });
  ref.onDispose(() => timer.cancel());

  return ref.watch(subscriptionRepositoryProvider).getSubscriptions();
}

@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> categories(Ref ref) async {
  return ref.watch(subscriptionRepositoryProvider).getCategories();
}

@Riverpod(keepAlive: true)
Future<List<Service>> services(Ref ref) async {
  return ref.watch(subscriptionRepositoryProvider).getServices();
}

final archivedSubscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getArchivedSubscriptions();
});

final allSubscriptionsProvider = FutureProvider<List<Subscription>>((ref) async {
  return ref.watch(subscriptionRepositoryProvider).getAllSubscriptions();
});
