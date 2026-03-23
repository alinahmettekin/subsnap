import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../utils/constants.dart';

import '../../features/auth/providers/profile_provider.dart';

part 'subscription_service.g.dart';

class SubscriptionService {
  static Future<void> init() async {
    // Only log errors in production for better performance
    await Purchases.setLogLevel(LogLevel.error);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(AppConstants.revenueCatApiKey);
      await Purchases.configure(configuration);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(AppConstants.revenueCatAppleApiKey);
      await Purchases.configure(configuration);
    }
  }

  static bool checkPremium(CustomerInfo customerInfo) {
    bool isPremium = customerInfo.entitlements.active.containsKey(AppConstants.entitlementId);
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
      debugPrint('❌ RevenueCat logIn failed: $e');
    }
  }

  static Future<void> manageSubscriptions() async {
    try {
      if (Platform.isIOS) {
        final Uri url = Uri.parse('https://apps.apple.com/account/subscriptions');
        if (await canLaunchUrl(url)) {
          await launchUrl(url);
        }
      } else if (Platform.isAndroid) {
        // Hardcoded package name as we're removing package_info_plus
        const packageName = 'com.aatstdio.subsnap';
        final Uri url = Uri.parse('https://play.google.com/store/account/subscriptions?package=$packageName');
        // Android intent might need mode: LaunchMode.externalApplication
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('❌ Failed to open subscription management: $e');
    }
  }

  static Future<void> logOut() async {
    try {
      final isAnonymous = await Purchases.isAnonymous;
      if (!isAnonymous) {
        await Purchases.logOut();
      }
    } catch (e) {
      debugPrint('❌ RevenueCat logOut failed: $e');
    }
  }
}

@Riverpod(keepAlive: true)
Stream<bool> isPremium(Ref ref) {
  final controller = StreamController<bool>();

  // Watch DB profile premium status
  final userProfile = ref.watch(userProfileProvider).value;
  final dbPremium = userProfile?.isSpecialPremium ?? false;

  // Function to determine final premium status
  bool getFinalPremium(bool rcPremium) => dbPremium || rcPremium;

  // Initial check from RevenueCat
  SubscriptionService.isPremium().then((rcValue) {
    if (!controller.isClosed) controller.add(getFinalPremium(rcValue));
  });

  // Listen for RevenueCat updates
  void listener(CustomerInfo customerInfo) {
    if (!controller.isClosed) {
      controller.add(getFinalPremium(SubscriptionService.checkPremium(customerInfo)));
    }
  }
  
  Purchases.addCustomerInfoUpdateListener(listener);

  ref.onDispose(() {
    controller.close();
  });

  return controller.stream;
}

@riverpod
class PremiumStatus extends _$PremiumStatus {
  @override
  bool build() => false;

  void setStatus(bool status) => state = status;
}
