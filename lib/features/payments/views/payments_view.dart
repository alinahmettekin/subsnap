import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../cards/providers/card_provider.dart';
import '../services/payment_service.dart';
import '../../subscriptions/views/widgets/subscription_icon.dart';

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
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
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
                                    Text(
                                      card != null ? '${card.cardName} (**** ${card.lastFour})' : 'Kart Seçilmedi',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        fontSize: 12,
                                        fontStyle: card == null ? FontStyle.italic : FontStyle.normal,
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
                              if (!isHistory &&
                                  !DateUtils.dateOnly(payment.dueDate).isAfter(DateUtils.dateOnly(DateTime.now())))
                                InkWell(
                                  onTap: () async {
                                    try {
                                      await ref.read(paymentServiceProvider).createPayment(payment);

                                      if (subscription != null) {
                                        DateTime nextDate = payment.dueDate;
                                        if (subscription.billingCycle == 'monthly') {
                                          int newYear = nextDate.year;
                                          int newMonth = nextDate.month + 1;
                                          if (newMonth > 12) {
                                            newMonth = 1;
                                            newYear++;
                                          }
                                          int lastDay = DateTime(newYear, newMonth + 1, 0).day;
                                          int newDay = nextDate.day > lastDay ? lastDay : nextDate.day;
                                          nextDate = DateTime(
                                            newYear,
                                            newMonth,
                                            newDay,
                                            nextDate.hour,
                                            nextDate.minute,
                                          );
                                        } else {
                                          // Yearly
                                          int newYear = nextDate.year + 1;
                                          int newMonth = nextDate.month;
                                          int lastDay = DateTime(newYear, newMonth + 1, 0).day;
                                          int newDay = nextDate.day > lastDay ? lastDay : nextDate.day;
                                          nextDate = DateTime(
                                            newYear,
                                            newMonth,
                                            newDay,
                                            nextDate.hour,
                                            nextDate.minute,
                                          );
                                        }
                                        await ref
                                            .read(subscriptionRepositoryProvider)
                                            .updateSubscriptionDate(subscription.id, nextDate);
                                      }

                                      ref.invalidate(upcomingPaymentsProvider);
                                      ref.invalidate(paymentHistoryProvider);
                                      ref.invalidate(subscriptionsProvider);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Ödeme başarıyla kaydedildi ve bir sonraki tarih güncellendi',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4, left: 8),
                                    child: Text(
                                      'Ödendi İşaretle',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
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
