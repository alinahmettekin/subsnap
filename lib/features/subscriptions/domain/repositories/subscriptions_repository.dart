import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';

abstract class SubscriptionsRepository {
  /// Fetches all subscriptions for a given [userId].
  /// Fetches all subscriptions for a given [userId] as a real-time stream.
  Stream<List<Subscription>> getSubscriptions(String userId);

  /// Fetches all subscriptions for a given [userId] (one-time fetch, not stream).
  Future<List<Subscription>> fetchSubscriptions(String userId);


  /// adds a new [subscription].
  Future<void> addSubscription(Subscription subscription);

  /// Updates an existing [subscription].
  Future<void> updateSubscription(Subscription subscription);

  /// Deletes a subscription by its [id].
  Future<void> deleteSubscription(String id);
}
