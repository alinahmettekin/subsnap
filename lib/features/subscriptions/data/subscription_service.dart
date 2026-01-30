import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // TODO: Replace with your actual RevenueCat API keys
  static const _apiKeyIOS = 'appl_place_your_ios_api_key_here';
  static const _apiKeyAndroid = 'goog_place_your_android_api_key_here';

  static const _entitlementID = 'pro_access';

  static Future<void> init(String? appUserId) async {
    await Purchases.setLogLevel(LogLevel.debug);

    PurchasesConfiguration configuration;
    if (Platform.isAndroid) {
      configuration = PurchasesConfiguration(_apiKeyAndroid);
    } else if (Platform.isIOS) {
      configuration = PurchasesConfiguration(_apiKeyIOS);
    } else {
      // Handle other platforms if necessary or return
      return;
    }

    if (appUserId != null) {
      configuration.appUserID = appUserId;
    }

    await Purchases.configure(configuration);
  }

  static Future<List<Package>> getPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        return offerings.current!.availablePackages;
      }
    } on PlatformException catch (e) {
      debugPrint('Error fetching offerings: $e');
    }
    return [];
  }

  static Future<bool> purchasePackage(Package package) async {
    try {
      CustomerInfo customerInfo = await Purchases.purchasePackage(package);
      return customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        debugPrint("Purchase error: $e");
      }
      return false;
    }
  }

  static Future<bool> getIsPro() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> restorePurchases() async {
    try {
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      return customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } catch (e) {
      return false;
    }
  }
}
