import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/subscription_service.dart';
import '../models/card.dart';
import '../services/card_service.dart';

part 'card_provider.g.dart';

@Riverpod(keepAlive: true)
CardService cardService(ref) {
  return CardService(Supabase.instance.client);
}

@Riverpod(keepAlive: true)
Future<List<PaymentCard>> cards(ref) async {
  return ref.watch(cardServiceProvider).getCards();
}

@Riverpod(keepAlive: true)
Future<int> cardCount(Ref ref) async {
  final cards = await ref.watch(cardsProvider.future);
  return cards.length;
}

@Riverpod(keepAlive: true)
Future<bool> canAddCard(Ref ref) async {
  final isPremium = await ref.watch(isPremiumProvider.future);
  if (isPremium) return true;

  final cards = await ref.watch(cardsProvider.future);
  return cards.length < 2;
}
