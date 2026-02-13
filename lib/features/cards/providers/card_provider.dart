import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card.dart';
import '../services/card_service.dart';

part 'card_provider.g.dart';

@riverpod
CardService cardService(ref) {
  return CardService(Supabase.instance.client);
}

@riverpod
Future<List<PaymentCard>> cards(ref) async {
  return ref.watch(cardServiceProvider).getCards();
}

@riverpod
Future<int> cardCount(ref) async {
  final cards = await ref.watch(cardsProvider.future);
  return cards.length;
}

@riverpod
Future<bool> canAddCard(ref) async {
  return ref.watch(cardServiceProvider).canAddCard();
}
