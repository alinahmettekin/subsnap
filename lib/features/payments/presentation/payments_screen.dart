import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:subsnap/features/subscriptions/presentation/payments_provider.dart';
import 'package:subsnap/features/subscriptions/domain/entities/payment.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';
import 'package:subsnap/features/subscriptions/presentation/subscriptions_provider.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription_template.dart';
import 'package:subsnap/features/subscriptions/presentation/subscription_templates_provider.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/core/utils/currency_formatter.dart';

/// Ödemeler ekranı - Sadece görüntüleme
class PaymentsScreen extends ConsumerWidget {
  const PaymentsScreen({super.key});

  SubscriptionTemplate? _findMatchingTemplate(
    String subscriptionName,
    List<SubscriptionTemplate> templates,
  ) {
    try {
      final normalizedName = subscriptionName.toLowerCase().trim();
      for (var template in templates) {
        if (template.name.toLowerCase().trim() == normalizedName) {
          return template;
        }
      }
    } catch (e) {
      // Hata durumunda null
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsProvider);
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final templatesAsync = ref.watch(subscriptionTemplatesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ödemeler'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(paymentsProvider);
          ref.invalidate(subscriptionsProvider);
          ref.invalidate(subscriptionTemplatesProvider);
          await ref.read(paymentsProvider.future);
          await ref.read(subscriptionsProvider.future);
        },
        child: paymentsAsync.when(
          data: (payments) {
            if (payments.isEmpty) {
              return const Center(
                child: Text(
                  'Henüz ödeme kaydı yok.\nAbonelikleriniz için otomatik ödemeler burada görünecek.',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final groupedPayments = <String, List<Payment>>{};
            for (var payment in payments) {
              final dateKey = DateFormat('yyyy-MM').format(payment.paymentDate);
              groupedPayments.putIfAbsent(dateKey, () => []).add(payment);
            }

            final sortedDates = groupedPayments.keys.toList()..sort((a, b) => b.compareTo(a));

            return subscriptionsAsync.when(
              data: (subscriptions) {
                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: ClampingScrollPhysics(),
                  ),
                  slivers: [
                    ...sortedDates.map((dateKey) {
                      final monthPayments = groupedPayments[dateKey]!;
                      final monthTotal = monthPayments.fold<double>(
                        0.0,
                        (sum, payment) => sum + payment.amount,
                      );

                      return SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat('MMMM yyyy', 'tr_TR').format(DateTime.parse('$dateKey-01')),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    CurrencyFormatter.format(monthTotal, currency: 'TRY'),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final payment = monthPayments[index];

                                Subscription subscription;
                                try {
                                  subscription = subscriptions.firstWhere(
                                    (sub) => sub.id == payment.subscriptionId,
                                  );
                                } catch (e) {
                                  return const SizedBox.shrink();
                                }

                                // Template mantığına uygun ikonu bul
                                final matchingTemplate = templatesAsync.maybeWhen(
                                  data: (templates) => _findMatchingTemplate(subscription.name, templates),
                                  orElse: () => null,
                                );

                                final bool hasValidTemplate = matchingTemplate != null &&
                                    matchingTemplate.id.isNotEmpty &&
                                    matchingTemplate.iconName.isNotEmpty;

                                return Dismissible(
                                  key: Key(payment.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
                                    return await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Ödemeyi Sil'),
                                        content: const Text('Bu ödeme kaydını silmek istediğinize emin misiniz?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Vazgeç'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                                            child: const Text('Sil'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  onDismissed: (direction) async {
                                    try {
                                      await ref.read(paymentsRepositoryProvider).deletePayment(payment.id);
                                      // Listeyi yenile
                                      ref.invalidate(paymentsProvider);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Ödeme silindi')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Hata: $e')),
                                        );
                                      }
                                    }
                                  },
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.only(right: 20),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  child: ListTile(
                                    leading: hasValidTemplate
                                        ? CircleAvatar(
                                            backgroundColor: Colors.grey.shade100,
                                            child: Icon(
                                              matchingTemplate.iconData,
                                              color: matchingTemplate.iconColor,
                                              size: 24,
                                            ),
                                          )
                                        : CircleAvatar(
                                            backgroundColor: Colors.grey.shade100,
                                            child: Text(
                                              subscription.name.isNotEmpty ? subscription.name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.indigo,
                                              ),
                                            ),
                                          ),
                                    title: Text(
                                      subscription.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: Text(
                                      DateFormat('dd MMMM yyyy', 'tr_TR').format(payment.paymentDate),
                                    ),
                                    trailing: Text(
                                      CurrencyFormatter.format(payment.amount, currency: payment.currency),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: monthPayments.length,
                            ),
                          ),
                        ],
                      );
                    }),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Hata: $err')),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Hata: $err')),
        ),
      ),
    );
  }
}
