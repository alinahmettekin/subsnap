import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../features/subscriptions/models/subscription.dart';
import '../../../../features/cards/providers/card_provider.dart';

class PaymentMethodBreakdown extends ConsumerStatefulWidget {
  final List<Subscription> subscriptions;

  const PaymentMethodBreakdown({super.key, required this.subscriptions});

  @override
  ConsumerState<PaymentMethodBreakdown> createState() => _PaymentMethodBreakdownState();
}

class _PaymentMethodBreakdownState extends ConsumerState<PaymentMethodBreakdown> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null && user.userMetadata!.containsKey('is_payment_method_expanded')) {
      _isExpanded = user.userMetadata!['is_payment_method_expanded'] as bool;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    try {
      Supabase.instance.client.auth.updateUser(UserAttributes(data: {'is_payment_method_expanded': _isExpanded}));
    } catch (e) {
      debugPrint('Failed to save expansion preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final cardsAsync = ref.watch(cardsProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Ödeme Yöntemi Analizi',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: onSurfaceVariant,
                ),
              ],
            ),
          ),

          // Content
          AnimatedCrossFade(
            firstChild: Container(),
            secondChild: cardsAsync.when(
              data: (cards) {
                final Map<String, double> cardCosts = {};
                final Map<String, String> cardNames = {};
                final Map<String, Color> cardColors = {};

                // Default 'No Card' entry
                cardNames['null'] = 'Kart Seçilmedi';
                cardColors['null'] = theme.colorScheme.outline;

                for (var card in cards) {
                  cardNames[card.id] = '${card.cardName} (**${card.lastFour})';
                  // Generate a pseudo-random color based on card ID or name
                  // Or use card details if available. For now, use primary palette.
                  cardColors[card.id] = theme.colorScheme.primary;
                }

                // Assign distinct colors
                final distinctColors = [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                  theme.colorScheme.tertiary,
                  theme.colorScheme.error,
                  Colors.orange,
                  Colors.teal,
                  Colors.indigo,
                ];

                int colorIndex = 0;
                for (var card in cards) {
                  cardColors[card.id] = distinctColors[colorIndex % distinctColors.length];
                  colorIndex++;
                }

                double totalMonthlyCost = 0;

                for (var sub in widget.subscriptions) {
                  // Normalize to monthly cost for fair comparison
                  final monthlyCost = sub.billingCycle == 'monthly' ? sub.price : sub.price / 12;

                  final cardId = sub.cardId ?? 'null';
                  cardCosts[cardId] = (cardCosts[cardId] ?? 0) + monthlyCost;
                  totalMonthlyCost += monthlyCost;
                }

                if (totalMonthlyCost == 0) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('Veri yok')),
                  );
                }

                final sortedEntries = cardCosts.entries.where((e) => e.value > 0).toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return Column(
                  children: [
                    const SizedBox(height: 24),
                    // List
                    ...sortedEntries.map((entry) {
                      final cardId = entry.key;
                      final cost = entry.value;
                      final percentage = (cost / totalMonthlyCost) * 100;
                      final name = cardNames[cardId] ?? 'Bilinmeyen Kart';
                      final color = cardColors[cardId] ?? theme.colorScheme.primary;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(color: onSurface, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '₺${cost.toStringAsFixed(0)} / ay',
                                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Stack(
                              children: [
                                Container(
                                  height: 8,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: percentage / 100,
                                  child: Container(
                                    height: 8,
                                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                '%${percentage.toStringAsFixed(1)}',
                                style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Padding(padding: const EdgeInsets.all(16), child: Text('Hata: $err')),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }
}
