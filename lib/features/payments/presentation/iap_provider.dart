import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/features/auth/data/supabase_profile_repository.dart';

// Pro Plan Product IDs
const String proPlanMonthlyId = 'subsnap_pro_monthly';
const String proPlanYearlyId = 'subsnap_pro_yearly';

final iapProvider = NotifierProvider<IAPNotifier, IAPState>(() {
  return IAPNotifier();
});

class IAPState {
  final bool isAvailable;
  final List<ProductDetails> products;
  final bool isLoading;
  final String? errorMessage;

  IAPState({
    this.isAvailable = false,
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  IAPState copyWith({
    bool? isAvailable,
    List<ProductDetails>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return IAPState(
      isAvailable: isAvailable ?? this.isAvailable,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class IAPNotifier extends Notifier<IAPState> {
  final InAppPurchase _connection = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  @override
  IAPState build() {
    final purchaseUpdated = _connection.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: () => _subscription.cancel(),
      onError: (error) => state = state.copyWith(errorMessage: error.toString()),
    );
    _initialize();

    ref.onDispose(() {
      _subscription.cancel();
    });

    return IAPState();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    final bool available = await _connection.isAvailable();
    if (!available) {
      state = state.copyWith(isAvailable: false, isLoading: false);
      return;
    }

    const Set<String> kIds = {proPlanMonthlyId, proPlanYearlyId};
    final ProductDetailsResponse response = await _connection.queryProductDetails(kIds);

    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('❌ [IAP] Products not found: ${response.notFoundIDs}');
    }

    state = state.copyWith(
      isAvailable: true,
      products: response.productDetails,
      isLoading: false,
    );
  }

  Future<void> buyPro(ProductDetails product) async {
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: product);
    await _connection.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        state = state.copyWith(isLoading: true);
      } else {
        if (purchase.status == PurchaseStatus.error) {
          state = state.copyWith(isLoading: false, errorMessage: purchase.error?.message);
        } else if (purchase.status == PurchaseStatus.purchased || purchase.status == PurchaseStatus.restored) {
          // Verify purchase and upgrade user
          final success = await _verifyAndUpgrade(purchase);
          if (success) {
            // Success!
          }
        }

        if (purchase.pendingCompletePurchase) {
          await _connection.completePurchase(purchase);
        }
      }
    }
  }

  Future<bool> _verifyAndUpgrade(PurchaseDetails purchase) async {
    try {
      final user = ref.read(authUserProvider).value;
      if (user == null) return false;

      final profileRepo = ref.read(profileRepositoryProvider);
      if (profileRepo is SupabaseProfileRepository) {
        // In a real app, you should verify the receipt on your backend
        // For now, we'll trust the store and upgrade for 1 year
        final expiry = DateTime.now().add(const Duration(days: 365));
        await profileRepo.upgradeToPro(user.id, expiry);

        // Refresh profile
        ref.invalidate(userProfileProvider);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ [IAP] Error upgrading user: $e');
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}
