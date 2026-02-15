import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/subscription_service.dart';
import 'package:intl/intl.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../cards/providers/card_provider.dart';
import '../services/payment_service.dart';
import '../../subscriptions/views/widgets/subscription_icon.dart';
import 'add_payment_view.dart';
import '../../subscriptions/views/paywall_view.dart';

class PaymentsView extends ConsumerWidget {
  const PaymentsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ödemeler'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ödenecekler'),
              Tab(text: 'Geçmiş'),
            ],
          ),
        ),
        body: const TabBarView(children: [_PaymentsList(isHistory: false), _PaymentsList(isHistory: true)]),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 100.0),
          child: FloatingActionButton(
            onPressed: () {
              final isPremium = ref.read(isPremiumProvider).asData?.value ?? false;
              if (!isPremium) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallView()));
                return;
              }
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const AddPaymentView(),
              );
            },
            tooltip: 'Ödeme Ekle',
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(Icons.add, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
        ),
      ),
    );
  }
}

class _PaymentsList extends ConsumerWidget {
  final bool isHistory;

  const _PaymentsList({required this.isHistory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = isHistory ? ref.watch(paymentHistoryProvider) : ref.watch(upcomingPaymentsProvider);
    final subscriptionsAsync = ref.watch(allSubscriptionsProvider);
    final cardsAsync = ref.watch(cardsProvider);

    return paymentsAsync.when(
      data: (payments) {
        if (payments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isHistory ? Icons.history_rounded : Icons.payments_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  isHistory ? 'Henüz ödeme geçmişi yok' : 'Ödenecek fatura bulunmuyor',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return subscriptionsAsync.when(
          data: (subscriptions) {
            final subscriptionMap = {for (var s in subscriptions) s.id: s};

            return cardsAsync.when(
              data: (cards) {
                final cardMap = {for (var c in cards) c.id: c};

                return Scaffold(
                  body: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final subscription = subscriptionMap[payment.subscriptionId];
                      final card = payment.cardId != null ? cardMap[payment.cardId] : null;

                      // Only allow delete for history items (real DB records)
                      // Upcoming items are generated from subscriptions
                      final canDelete = isHistory || !payment.id.startsWith('temp_');

                      final child = Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: subscription != null
                              ? SubscriptionIcon(subscription: subscription, size: 40)
                              : CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                  child: const Icon(Icons.help_outline),
                                ),
                          title: Text(
                            subscription?.name ?? 'Bilinmeyen Abonelik',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isHistory
                                    ? 'Ödendi: ${DateFormat('dd MMM yyyy', 'tr_TR').format(payment.paidAt ?? payment.dueDate)}'
                                    : 'Vade: ${DateFormat('dd MMM yyyy', 'tr_TR').format(payment.dueDate)}',
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        card != null ? '${card.cardName} ${card.lastFour}' : 'Kart Seçilmedi',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: 12,
                                          fontStyle: card == null ? FontStyle.italic : FontStyle.normal,
                                        ),
                                        // Removed maxLines so it wraps to the next line
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${payment.amount} ${payment.currency}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isHistory ? Colors.green : Theme.of(context).colorScheme.error,
                                ),
                              ),
                              if (!isHistory)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Otomatik Ödenecek',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (isHistory) const SizedBox(height: 20), // Placeholder for alignment
                            ],
                          ),
                        ),
                      );

                      if (!canDelete) return child;

                      return Dismissible(
                        key: Key(payment.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Ödeme Kaydını Sil'),
                              content: Text('Bu ödeme kaydını silmek istediğinize emin misiniz?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('İptal'),
                                ),
                                FilledButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
                                  child: const Text('Sil'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await ref.read(paymentServiceProvider).deletePayment(payment.id);
                              ref.invalidate(upcomingPaymentsProvider);
                              ref.invalidate(paymentHistoryProvider);
                              return true;
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Silme hatası: $e'), backgroundColor: Colors.red),
                                );
                              }
                              return false;
                            }
                          }
                          return false;
                        },
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                        ),
                        child: child,
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Kart Hatası: $err')),
            );
          },
          loading: () => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Abonelik bilgileri yükleniyor...')],
            ),
          ),
          error: (err, stack) {
            debugPrint('PaymentsView Sub Error: $err\n$stack');
            return Center(child: Text('Abonelik Hatası: $err'));
          },
        );
      },

      loading: () => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Ödemeler yükleniyor...')],
        ),
      ),
      error: (err, stack) {
        debugPrint('PaymentsView Main Error: $err\n$stack');
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SelectableText(
              'Bir hata oluştu:\n$err',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
