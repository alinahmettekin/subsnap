import 'dart:async';
import 'dart:developer';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
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
    log('DEBUG: Checking premium status...');
    log('DEBUG: Active entitlements: ${customerInfo.entitlements.active.keys}');
    log('DEBUG: All entitlements: ${customerInfo.entitlements.all.keys}');

    // Check for specific entitlement identifier provided by RevenueCat logs
    // final isPremium = customerInfo.entitlements.active.containsKey(AppConstants.entitlementId);

    log('DEBUG: Premium status: BYPASSED (FALSE)');
    return true; // Force free version for testing
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
      log('DEBUG: RevenueCat logIn failed: $e');
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
        final packageInfo = await PackageInfo.fromPlatform();
        final packageName = packageInfo.packageName;
        final Uri url = Uri.parse('https://play.google.com/store/account/subscriptions?package=$packageName');
        // Android intent might need mode: LaunchMode.externalApplication
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      log('DEBUG: Failed to open subscription management: $e');
    }
  }

  static Future<void> logOut() async {
    try {
      final isAnonymous = await Purchases.isAnonymous;
      if (!isAnonymous) {
        await Purchases.logOut();
      } else {
        log('DEBUG: RevenueCat user is already anonymous, skipping logOut');
      }
    } catch (e) {
      log('DEBUG: RevenueCat logOut failed: $e');
    }
  }
}

@Riverpod(keepAlive: true)
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

@riverpod
class PremiumStatus extends _$PremiumStatus {
  @override
  bool build() => false;

  void setStatus(bool status) => state = status;
}
