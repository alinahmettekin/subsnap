// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cardService)
final cardServiceProvider = CardServiceProvider._();

final class CardServiceProvider
    extends $FunctionalProvider<CardService, CardService, CardService>
    with $Provider<CardService> {
  CardServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardServiceHash();

  @$internal
  @override
  $ProviderElement<CardService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CardService create(Ref ref) {
    return cardService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CardService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CardService>(value),
    );
  }
}

String _$cardServiceHash() => r'f31da9b4f595573d84ba354d642ee90c1a7bff78';

@ProviderFor(cards)
final cardsProvider = CardsProvider._();

final class CardsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PaymentCard>>,
          List<PaymentCard>,
          FutureOr<List<PaymentCard>>
        >
    with
        $FutureModifier<List<PaymentCard>>,
        $FutureProvider<List<PaymentCard>> {
  CardsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardsHash();

  @$internal
  @override
  $FutureProviderElement<List<PaymentCard>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentCard>> create(Ref ref) {
    return cards(ref);
  }
}

String _$cardsHash() => r'1e8710407629b5f47badfd3b62242ca00a31e160';

@ProviderFor(cardCount)
final cardCountProvider = CardCountProvider._();

final class CardCountProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  CardCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cardCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cardCountHash();

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    return cardCount(ref);
  }
}

String _$cardCountHash() => r'336562d7f7a032e0a9d88dc40320dd495d88cc72';

@ProviderFor(canAddCard)
final canAddCardProvider = CanAddCardProvider._();

final class CanAddCardProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  CanAddCardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'canAddCardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$canAddCardHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return canAddCard(ref);
  }
}

String _$canAddCardHash() => r'a180c573309d9ca518907dea66a652cbb814a32b';
