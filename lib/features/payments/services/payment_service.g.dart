// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(paymentService)
final paymentServiceProvider = PaymentServiceProvider._();

final class PaymentServiceProvider
    extends $FunctionalProvider<PaymentService, PaymentService, PaymentService>
    with $Provider<PaymentService> {
  PaymentServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentServiceHash();

  @$internal
  @override
  $ProviderElement<PaymentService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PaymentService create(Ref ref) {
    return paymentService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PaymentService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PaymentService>(value),
    );
  }
}

String _$paymentServiceHash() => r'ade536f3c332913b7fe0775069a87cb805be598c';

@ProviderFor(upcomingPayments)
final upcomingPaymentsProvider = UpcomingPaymentsProvider._();

final class UpcomingPaymentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Payment>>,
          List<Payment>,
          FutureOr<List<Payment>>
        >
    with $FutureModifier<List<Payment>>, $FutureProvider<List<Payment>> {
  UpcomingPaymentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingPaymentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingPaymentsHash();

  @$internal
  @override
  $FutureProviderElement<List<Payment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Payment>> create(Ref ref) {
    return upcomingPayments(ref);
  }
}

String _$upcomingPaymentsHash() => r'55d62591b381e4076cd978b8b85ee7ab38e4d0c0';

@ProviderFor(paymentHistory)
final paymentHistoryProvider = PaymentHistoryProvider._();

final class PaymentHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Payment>>,
          List<Payment>,
          FutureOr<List<Payment>>
        >
    with $FutureModifier<List<Payment>>, $FutureProvider<List<Payment>> {
  PaymentHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'paymentHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$paymentHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<Payment>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Payment>> create(Ref ref) {
    return paymentHistory(ref);
  }
}

String _$paymentHistoryHash() => r'1664cc627c4938d5ae22455fcb62925112bfc185';
