import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card.dart';

class CardService {
  final SupabaseClient _client;

  CardService(this._client);

  Future<List<PaymentCard>> getCards({bool includeDeleted = false}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client.from('cards').select().eq('user_id', userId);

    if (!includeDeleted) {
      query = query.eq('is_deleted', false);
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List).map((json) => PaymentCard.fromJson(json)).toList();
  }

  Future<bool> canAddCard() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    // Get current card count
    final cards = await getCards();
    final cardCount = cards.length;

    // Check if user is premium
    final profileResponse = await _client.from('profiles').select('is_premium').eq('id', userId).maybeSingle();

    final isPremium = profileResponse?['is_premium'] ?? false;

    // Premium users have unlimited cards, free users limited to 2
    if (isPremium) return true;
    return cardCount < 2;
  }

  Future<void> addCard(PaymentCard card) async {
    // Rely on UI/Provider layer for permission checks.
    await _client.from('cards').insert(card.toJson());
  }

  Future<void> deleteCard(String id) async {
    await _client.from('cards').update({'is_deleted': true}).eq('id', id);
  }

  Future<void> updateCard(PaymentCard card) async {
    await _client.from('cards').update({'card_name': card.cardName, 'last_four': card.lastFour}).eq('id', card.id);
  }

  Future<PaymentCard?> getCardById(String id) async {
    final response = await _client.from('cards').select().eq('id', id).maybeSingle();

    if (response == null) return null;
    return PaymentCard.fromJson(response);
  }
}
