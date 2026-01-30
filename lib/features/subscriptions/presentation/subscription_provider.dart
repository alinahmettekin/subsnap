import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:subsnap/features/subscriptions/data/subscription_service.dart';

final isProUserProvider = StateProvider<bool>((ref) => false);

final offeringsProvider = FutureProvider<List<Package>>((ref) async {
  return await SubscriptionService.getPackages();
});

// A provider to initialize subscription status on app start or user login
final subscriptionInitializerProvider = FutureProvider<void>((ref) async {
  final isPro = await SubscriptionService.getIsPro();
  ref.read(isProUserProvider.notifier).state = isPro;
});
