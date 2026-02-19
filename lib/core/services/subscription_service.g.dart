// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(isPremium)
final isPremiumProvider = IsPremiumProvider._();

final class IsPremiumProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  IsPremiumProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isPremiumProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isPremiumHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return isPremium(ref);
  }
}

String _$isPremiumHash() => r'e0995b74fe2443d05738a3666c03d2770d9c3cf3';

@ProviderFor(PremiumStatus)
final premiumStatusProvider = PremiumStatusProvider._();

final class PremiumStatusProvider
    extends $NotifierProvider<PremiumStatus, bool> {
  PremiumStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'premiumStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$premiumStatusHash();

  @$internal
  @override
  PremiumStatus create() => PremiumStatus();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$premiumStatusHash() => r'5946d2c149b6e025eee12fde9fc15e4dc0e4cbcd';

abstract class _$PremiumStatus extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
