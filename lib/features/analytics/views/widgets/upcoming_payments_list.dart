import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';
import 'package:subsnap/features/payments/models/payment.dart';

class UpcomingPaymentsList extends StatelessWidget {
  final List<Subscription> subscriptions;
  final List<Payment> upcomingPayments;
  final bool showLimitMessage;

  const UpcomingPaymentsList({
    super.key,
    required this.subscriptions,
    required this.upcomingPayments,
    this.showLimitMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    // Join with subscription names
    final subMap = {for (var s in subscriptions) s.id: s};
    final now = DateTime.now();

    // Take only next 5
    final displayPayments = upcomingPayments.where((p) => p.dueDate.isAfter(now)).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final limitedPayments = displayPayments.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Yaklaşan Ödemeler',
          style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (limitedPayments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Text('Yaklaşan ödeme yok.', style: TextStyle(color: onSurfaceVariant)),
            ),
          ),
        ...limitedPayments.map((payment) {
          final subscription = subMap[payment.subscriptionId];
          final daysLeft = payment.dueDate.difference(now).inDays;
          final isUrgent = daysLeft <= 3;
          final accent = isUrgent ? theme.colorScheme.error : theme.colorScheme.primary;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUrgent
                    ? theme.colorScheme.error.withOpacity(0.35)
                    : theme.colorScheme.outlineVariant.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(isUrgent ? Icons.priority_high_rounded : Icons.payment_rounded, color: accent),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription?.name ?? 'Bilinmeyen',
                        style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        isUrgent ? '$daysLeft gün kaldı!' : '${daysLeft + 1} gün sonra',
                        style: TextStyle(
                          color: isUrgent ? theme.colorScheme.error : onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: isUrgent ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '₺${payment.amount.toStringAsFixed(0)}',
                  style: TextStyle(color: onSurface, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          );
        }),
        if (showLimitMessage)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tüm ödemeleri görmek için Premium\'a geçin',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
