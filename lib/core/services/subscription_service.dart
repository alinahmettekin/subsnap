import 'dart:async';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import '../utils/constants.dart';

part 'subscription_service.g.dart';

class SubscriptionService {
  static Future<void> init() async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid || Platform.isIOS) {
      configuration = PurchasesConfiguration(AppConstants.revenueCatApiKey);
      await Purchases.configure(configuration);
    }
  }

  static bool checkPremium(CustomerInfo customerInfo) {
    print('DEBUG: Checking premium status...');
    print('DEBUG: Active entitlements: ${customerInfo.entitlements.active.keys}');
    print('DEBUG: All entitlements: ${customerInfo.entitlements.all.keys}');

    // Check for specific entitlement identifier provided by RevenueCat logs
    final isPremium = customerInfo.entitlements.active.containsKey('subsnap');

    print('DEBUG: Premium status: $isPremium');
    return isPremium;
  }

  static Future<bool> isPremium() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return checkPremium(customerInfo);
    } catch (e) {
      return false;
    }
  }

  static Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      print('DEBUG: RevenueCat logIn failed: $e');
    }
  }

  static Future<void> logOut() async {
    try {
      final isAnonymous = await Purchases.isAnonymous;
      if (!isAnonymous) {
        await Purchases.logOut();
      } else {
        print('DEBUG: RevenueCat user is already anonymous, skipping logOut');
      }
    } catch (e) {
      print('DEBUG: RevenueCat logOut failed: $e');
    }
  }
}

@riverpod
Stream<bool> isPremium(Ref ref) {
  final controller = StreamController<bool>();

  // Add initial state
  SubscriptionService.isPremium().then((value) {
    if (!controller.isClosed) controller.add(value);
  });

  // Listen for updates from RevenueCat
  Purchases.addCustomerInfoUpdateListener((customerInfo) {
    if (!controller.isClosed) {
      controller.add(SubscriptionService.checkPremium(customerInfo));
    }
  });

  ref.onDispose(() {
    controller.close();
  });

  return controller.stream;
}

