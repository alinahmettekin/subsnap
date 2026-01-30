import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:subsnap/features/payments/presentation/revenuecat_provider.dart';

/// Paywall screen using RevenueCat Paywall.
/// Displays the current offering from RevenueCat Dashboard.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: PaywallView(
          onDismiss: () => Navigator.of(context).pop(),
          onPurchaseCompleted: (CustomerInfo customerInfo, StoreTransaction storeTransaction) {
            ref.invalidate(customerInfoProvider);
            Navigator.of(context).pop();
          },
          onRestoreCompleted: (CustomerInfo customerInfo) {
            ref.invalidate(customerInfoProvider);
            Navigator.of(context).pop();
          },
          onRestoreError: (PurchasesError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Geri yükleme hatası: ${error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
          onPurchaseError: (PurchasesError error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Satın alma hatası: ${error.message}'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ),
    );
  }
}
