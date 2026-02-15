import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/features/subscriptions/providers/subscription_provider.dart';
import 'package:subsnap/features/payments/services/payment_service.dart';
import 'package:subsnap/features/cards/services/card_service.dart';
import 'package:subsnap/features/cards/providers/card_provider.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';
import 'package:subsnap/features/subscriptions/models/service.dart';
import 'package:subsnap/features/payments/models/payment.dart';
import 'package:subsnap/features/cards/models/card.dart';

// Manual Mock for SubscriptionRepository
class MockSubscriptionRepository implements SubscriptionRepository {
  int getSubscriptionsCallCount = 0;
  int getServicesCallCount = 0;
  int getCategoriesCallCount = 0;

  @override
  Future<List<Subscription>> getSubscriptions() async {
    getSubscriptionsCallCount++;
    return [];
  }

  @override
  Future<List<Service>> getServices() async {
    getServicesCallCount++;
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    getCategoriesCallCount++;
    return [];
  }

  @override
  Future<void> addSubscription(Subscription subscription) async {}
  @override
  Future<void> cancelSubscription(String id) async {}
  @override
  Future<void> deleteSubscription(String id) async {}
  @override
  Future<void> deleteSubscriptionWithPayments(String id) async {}
  @override
  Future<void> restoreSubscription(String id) async {}
  @override
  Future<void> updateSubscription(Subscription subscription) async {}
  @override
  Future<void> updateSubscriptionDate(String id, DateTime newDate) async {}
  @override
  Future<List<Subscription>> getAllSubscriptions() async => [];
  @override
  Future<List<Subscription>> getArchivedSubscriptions() async => [];
}

// Manual Mock for PaymentService
class MockPaymentService implements PaymentService {
  int getPaymentsCallCount = 0;

  @override
  Future<List<Payment>> getPayments({bool history = false}) async {
    getPaymentsCallCount++;
    return [];
  }

  @override
  Future<void> createPayment(Payment payment) async {}
  @override
  Future<void> deletePayment(String paymentId) async {}
  @override
  Future<void> markAsPaid(String paymentId) async {}
  @override
  Future<void> markAsUnpaid(String paymentId) async {}
}

// Manual Mock for CardService
class MockCardService implements CardService {
  int getCardsCallCount = 0;

  @override
  Future<List<PaymentCard>> getCards() async {
    getCardsCallCount++;
    return [];
  }

  @override
  Future<void> addCard(PaymentCard card) async {}
  @override
  Future<bool> canAddCard() async => true;
  @override
  Future<void> deleteCard(String id) async {}
  @override
  Future<PaymentCard?> getCardById(String id) async => null;
}

void main() {
  group('Dashboard Data Fetching Tests', () {
    test('Services should be fetched only ONCE (Cached)', () async {
      final mockRepo = MockSubscriptionRepository();
      final container = ProviderContainer(overrides: [subscriptionRepositoryProvider.overrideWithValue(mockRepo)]);

      // 1. Initial read
      await container.read(servicesProvider.future);
      expect(mockRepo.getServicesCallCount, 1, reason: 'First fetch should call repo');

      // 2. Second read immediately
      await container.read(servicesProvider.future);
      expect(mockRepo.getServicesCallCount, 1, reason: 'Second fetch should be cached');

      // 3. Read after delay (simulating navigation back)
      await Future.delayed(const Duration(seconds: 1)); // Cached forever
      await container.read(servicesProvider.future);
      expect(mockRepo.getServicesCallCount, 1, reason: 'Services should be KeepAlive cached');
    });

    test('Categories should be fetched only ONCE (Cached)', () async {
      final mockRepo = MockSubscriptionRepository();
      final container = ProviderContainer(overrides: [subscriptionRepositoryProvider.overrideWithValue(mockRepo)]);

      // 1. Initial read
      await container.read(categoriesProvider.future);
      expect(mockRepo.getCategoriesCallCount, 1, reason: 'First fetch should call repo');

      // 2. Second read immediately
      await container.read(categoriesProvider.future);
      expect(mockRepo.getCategoriesCallCount, 1, reason: 'Second fetch should be cached');

      // 3. Read after delay
      await Future.delayed(const Duration(seconds: 1));
      await container.read(categoriesProvider.future);
      expect(mockRepo.getCategoriesCallCount, 1, reason: 'Categories should be KeepAlive cached');
    });

    test('Cards should be fetched only ONCE (Cached)', () async {
      final mockService = MockCardService();
      final container = ProviderContainer(overrides: [cardServiceProvider.overrideWithValue(mockService)]);

      // 1. Initial read
      await container.read(cardsProvider.future);
      expect(mockService.getCardsCallCount, 1, reason: 'First fetch should call service');

      // 2. Second read immediately
      await container.read(cardsProvider.future);
      expect(mockService.getCardsCallCount, 1, reason: 'Second fetch should be cached');

      // 3. Read after delay
      await Future.delayed(const Duration(seconds: 1));
      await container.read(cardsProvider.future);
      expect(mockService.getCardsCallCount, 1, reason: 'Cards should be KeepAlive cached');
    });

    test('Subscriptions should refresh every 5 seconds (Polling)', () async {
      final mockRepo = MockSubscriptionRepository();
      final container = ProviderContainer(overrides: [subscriptionRepositoryProvider.overrideWithValue(mockRepo)]);

      // 1. Initial
      final sub1 = container.read(subscriptionsProvider.future);
      await sub1;
      expect(mockRepo.getSubscriptionsCallCount, 1);

      // 2. Immediate re-read
      final sub2 = container.read(subscriptionsProvider.future);
      await sub2;
      expect(mockRepo.getSubscriptionsCallCount, 1, reason: 'Should be cached immediately');

      // Invalidate manually to verify refresh capability (simulates timer)
      container.invalidate(subscriptionsProvider);
      await container.read(subscriptionsProvider.future);
      expect(mockRepo.getSubscriptionsCallCount, 2);
    });

    test('Payment History should refresh every 5 seconds (Polling)', () async {
      final mockService = MockPaymentService();
      final container = ProviderContainer(overrides: [paymentServiceProvider.overrideWithValue(mockService)]);

      // 1. Initial
      await container.read(paymentHistoryProvider.future);
      expect(mockService.getPaymentsCallCount, 1);

      // 2. Immediate re-read
      await container.read(paymentHistoryProvider.future);
      expect(mockService.getPaymentsCallCount, 1);

      // Invalidate manually
      container.invalidate(paymentHistoryProvider);
      await container.read(paymentHistoryProvider.future);
      expect(mockService.getPaymentsCallCount, 2);
    });
  });
}
