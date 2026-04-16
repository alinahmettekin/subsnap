import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/card_provider.dart';
import '../../subscriptions/views/paywall_view.dart';
import 'add_card_view.dart';
import 'edit_card_view.dart';

class CardsListView extends ConsumerWidget {
  const CardsListView({super.key});

  Future<bool> _deleteCard(BuildContext context, WidgetRef ref, String cardId,
      String cardName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kartı Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$cardName kartını silmek istediğinize emin misiniz?'),
            const SizedBox(height: 16),
            const Text(
              '• Bu kart bir daha yeni abonelikler için seçilemez.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            const Text(
              '• Geçmiş ödemelerinizdeki ve analizlerinizdeki kart bilgileri korunmaya devam edecektir.',
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(cardServiceProvider).deleteCard(cardId);
        ref.invalidate(cardsProvider);
        ref.invalidate(allCardsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Kart başarıyla silindi'),
              backgroundColor: Colors.green));
        }
        return true;
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
        }
        return false;
      }
    }
    return false;
  }

  Future<void> _showAddCard(BuildContext context, WidgetRef ref) async {
    final canAdd = await ref.read(canAddCardProvider.future);

    if (!canAdd && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Kart Limiti'),
          content: const Text(
            'Ücretsiz planda en fazla 2 kart ekleyebilirsiniz. Sınırsız kart eklemek için Premium\'a geçin.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal')),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PaywallView()));
              },
              child: const Text('Premium\'a Geç'),
            ),
          ],
        ),
      );
      return;
    }

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const AddCardView(),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cardsAsync = ref.watch(cardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Yöntemlerim'), centerTitle: true),
      body: cardsAsync.when(
        data: (cards) {
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_card_off_rounded,
                      size: 80, color: theme.colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kart eklemediniz',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Abonelikleriniz için kart ekleyin',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return Dismissible(
                key: Key(card.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) =>
                    _deleteCard(context, ref, card.id, card.cardName),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 28),
                ),
                child: _buildDigitalCard(context, card, theme, index),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Hata: $error')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCard(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Kart Ekle'),
      ),
    );
  }

  Widget _buildDigitalCard(
      BuildContext context, dynamic card, ThemeData theme, int index) {
    // Variety of gradients for different cards
    final List<List<Color>> gradients = [
      [theme.colorScheme.primary, theme.colorScheme.secondary],
      [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
      [const Color(0xFF00B4DB), const Color(0xFF0083B0)],
      [const Color(0xFF232526), const Color(0xFF414345)],
    ];

    final currentGradient = gradients[index % gradients.length];

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => EditCardView(card: card),
        );
      },
      child: Container(
        height: 160,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: currentGradient,
          ),
          boxShadow: [
            BoxShadow(
              color: currentGradient[0].withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.credit_card,
                size: 130,
                color: Colors.white.withValues(alpha: 0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KART TAKMA ADI',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            card.cardName.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.nfc, color: Colors.white70, size: 24),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '**** **** **** ${card.lastFour}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              letterSpacing: 2,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Icon(Icons.more_horiz, color: Colors.white54),
                        ],
                      ),
                      // Card Brand Mini Logo
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(-10, 0),
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
