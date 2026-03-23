import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subscription.dart';

class DashboardSummaryCard extends StatelessWidget {
  final List<Subscription> subscriptions;

  const DashboardSummaryCard({super.key, required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final total = subscriptions.fold(0.0, (sum, item) {
      double monthlyPrice = 0.0;
      switch (item.billingCycle) {
        case 'weekly':
          monthlyPrice = item.price * 4; // 4 weeks in a month
          break;
        case 'monthly':
          monthlyPrice = item.price;
          break;
        case '3_months':
          monthlyPrice = item.price / 3;
          break;
        case '6_months':
          monthlyPrice = item.price / 6;
          break;
        case 'yearly':
          monthlyPrice = item.price / 12;
          break;
        default:
          monthlyPrice = item.price;
      }
      return sum + monthlyPrice;
    });

    final nextBill = subscriptions.isNotEmpty
        ? subscriptions.reduce((a, b) => a.nextBillingDate.isBefore(b.nextBillingDate) ? a : b)
        : null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration (circles)
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.05)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Aylık Harcama',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Icon(Icons.trending_up_rounded, color: Colors.white.withValues(alpha: 0.8), size: 20),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${total.toStringAsFixed(2)} ₺',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sıradaki Ödeme',
                            style: theme.textTheme.labelSmall?.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                          ),
                          Text(
                            nextBill != null
                                ? '${nextBill.name} • ${DateFormat('d MMM').format(nextBill.nextBillingDate)}'
                                : 'Planlanmış ödeme yok',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
