// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'support_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(supportService)
final supportServiceProvider = SupportServiceProvider._();

final class SupportServiceProvider
    extends $FunctionalProvider<SupportService, SupportService, SupportService>
    with $Provider<SupportService> {
  SupportServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'supportServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$supportServiceHash();

  @$internal
  @override
  $ProviderElement<SupportService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupportService create(Ref ref) {
    return supportService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupportService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupportService>(value),
    );
  }
}

String _$supportServiceHash() => r'1c90f441dd068e86aac1a149a635b5133420f427';
