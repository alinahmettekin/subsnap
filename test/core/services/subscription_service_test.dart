import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:subsnap/core/services/subscription_service.dart';

class MockCustomerInfo extends Fake implements CustomerInfo {
  final MockEntitlementInfos _entitlements;
  MockCustomerInfo(this._entitlements);

  @override
  EntitlementInfos get entitlements => _entitlements;
}

class MockEntitlementInfos extends Fake implements EntitlementInfos {
  @override
  final Map<String, EntitlementInfo> active;
  @override
  final Map<String, EntitlementInfo> all;

  MockEntitlementInfos(this.active, this.all);
}

class MockEntitlementInfo extends Fake implements EntitlementInfo {
  @override
  final String identifier;

  MockEntitlementInfo(this.identifier);
}

void main() {
  group('SubscriptionService.checkPremium', () {
    test('returns true when "subsnap" entitlement is active', () {
      final mockEntitlement = MockEntitlementInfo('subsnap');
      final activeEntitlements = {'subsnap': mockEntitlement};
      final allEntitlements = {'subsnap': mockEntitlement};

      final mockEntitlements = MockEntitlementInfos(activeEntitlements, allEntitlements);
      final customerInfo = MockCustomerInfo(mockEntitlements);

      final result = SubscriptionService.checkPremium(customerInfo);

      expect(result, isTrue);
    });

    test('returns false when "subsnap" entitlement is not active', () {
      final mockEntitlement = MockEntitlementInfo('other');
      final activeEntitlements = {'other': mockEntitlement};
      final allEntitlements = {'other': mockEntitlement, 'subsnap': mockEntitlement};

      final mockEntitlements = MockEntitlementInfos(activeEntitlements, allEntitlements);
      final customerInfo = MockCustomerInfo(mockEntitlements);

      final result = SubscriptionService.checkPremium(customerInfo);

      expect(result, isFalse);
    });

    test('returns false when active entitlements are empty', () {
      final mockEntitlements = MockEntitlementInfos({}, {});
      final customerInfo = MockCustomerInfo(mockEntitlements);

      final result = SubscriptionService.checkPremium(customerInfo);

      expect(result, isFalse);
    });
  });
}
