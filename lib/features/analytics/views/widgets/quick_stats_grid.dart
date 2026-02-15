import 'package:flutter/material.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';
import 'package:subsnap/features/payments/models/payment.dart';

class QuickStatsGrid extends StatelessWidget {
  final List<Subscription> subscriptions;
  final List<Payment> upcomingPayments;

  const QuickStatsGrid({super.key, required this.subscriptions, required this.upcomingPayments});

  @override
  Widget build(BuildContext context) {
    // 1. Active Plans
    final activeCount = subscriptions.length;

    // 2. Upcoming Payments (Next 7 days for example)
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    final upcomingCount = upcomingPayments.where((p) => p.dueDate.isAfter(now) && p.dueDate.isBefore(nextWeek)).length;

    // 3. Most Expensive
    Subscription? mostExpensive;
    if (subscriptions.isNotEmpty) {
      mostExpensive = subscriptions.reduce((curr, next) => curr.price > next.price ? curr : next);
    }

    // 4. Yearly Total
    double yearlyTotal = 0;
    for (var sub in subscriptions) {
      if (sub.billingCycle == 'monthly') {
        yearlyTotal += sub.price * 12;
      } else {
        yearlyTotal += sub.price;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(title: 'Aktif Plan', value: '$activeCount Abonelik', icon: Icons.playlist_play_rounded),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Yaklaşan (7 Gün)',
                value: '$upcomingCount Ödeme',
                icon: Icons.event_note_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'En Pahalı',
                value: mostExpensive?.name ?? '-',
                icon: Icons.monetization_on_outlined,
                valueFontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Bu Yıl',
                value: '₺${yearlyTotal.toStringAsFixed(0)}',
                icon: Icons.calendar_today_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double valueFontSize;

  const _StatCard({required this.title, required this.value, required this.icon, this.valueFontSize = 18});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Container(
      height: 110, // Fixed height for consistency
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: onSurfaceVariant, fontSize: 13)),
              Icon(icon, color: theme.colorScheme.primary.withValues(alpha: 0.8), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(color: onSurface, fontSize: valueFontSize, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
