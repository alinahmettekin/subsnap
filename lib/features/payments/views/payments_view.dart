import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';

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

            return Scaffold(
              body: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: payments.length,
                itemBuilder: (context, index) {
                  final payment = payments[index];
                  final subscription = subscriptionMap[payment.subscriptionId];

                  return Dismissible(
                    key: Key(payment.id),
                    direction: DismissDirection.endToStart,
                    confirmDismiss: (direction) async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Ödeme Kaydını Sil'),
                          content: Text(
                            isHistory
                                ? 'Bu ödeme kaydını silmek istediğinize emin misiniz?'
                                : 'Bu ödeme kaydını silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('İptal')),
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
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ödeme kaydı silindi'), backgroundColor: Colors.green),
                            );
                          }
                          return true;
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Silme hatası: $e'), backgroundColor: Colors.red));
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
                    child: Card(
                      elevation: 0,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            subscription?.name.characters.first.toUpperCase() ?? '?',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          subscription?.name ?? 'Bilinmeyen Abonelik',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          isHistory
                              ? 'Ödendi: ${DateFormat('dd MMM yyyy').format(payment.paidAt ?? payment.dueDate)}'
                              : 'Vade: ${DateFormat('dd MMM yyyy').format(payment.dueDate)}',
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
                              InkWell(
                                onTap: () async {
                                  await ref.read(paymentServiceProvider).markAsPaid(payment.id);
                                  ref.invalidate(upcomingPaymentsProvider);
                                  ref.invalidate(paymentHistoryProvider);
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
                            if (isHistory)
                              InkWell(
                                onTap: () async {
                                  await ref.read(paymentServiceProvider).markAsUnpaid(payment.id);
                                  ref.invalidate(upcomingPaymentsProvider);
                                  ref.invalidate(paymentHistoryProvider);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 8),
                                  child: Text(
                                    'Geri Al',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
