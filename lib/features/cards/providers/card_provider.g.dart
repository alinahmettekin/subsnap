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
        isAutoDispose: false,
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

String _$cardServiceHash() => r'8dad6e13f029398bbf3c32b34fa86f4500540a3c';

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
        isAutoDispose: false,
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

String _$cardsHash() => r'e658e9c28c2d79f42ee6694b191877573e2c40d9';

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
        isAutoDispose: false,
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

String _$cardCountHash() => r'6b649e367c0d57ca39932557aa964ec1f76b36f3';

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
        isAutoDispose: false,
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

String _$canAddCardHash() => r'41d3f8b33c68bc9b1b5c5e48571ed557d3769d08';
