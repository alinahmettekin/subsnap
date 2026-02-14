import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/subscription.dart';

class SubscriptionListItem extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const SubscriptionListItem({
    super.key,
    required this.subscription,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(isDark ? 0.3 : 0.6),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildIcon(context),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.billingCycle == 'monthly' ? 'Aylık' : 'Yıllık',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${subscription.price} ${subscription.currency}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getDaysRemainingColor(context).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getDaysRemainingText(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getDaysRemainingColor(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    final theme = Theme.of(context);
    // Simple logic for icon color based on name hash or similar could be added here
    // For now, consistent primary container
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          subscription.name.isNotEmpty ? subscription.name[0].toUpperCase() : '?',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  String _getDaysRemainingText() {
    final now = DateTime.now();
    final difference = subscription.nextBillingDate.difference(now).inDays;
    if (difference < 0) return 'Gecikmiş';
    if (difference == 0) return 'Bugün';
    if (difference == 1) return 'Yarın';
    return '$difference gün kaldı';
  }

  Color _getDaysRemainingColor(BuildContext context) {
    final now = DateTime.now();
    final difference = subscription.nextBillingDate.difference(now).inDays;
    final theme = Theme.of(context);

    if (difference < 3) return theme.colorScheme.error;
    if (difference < 7) return theme.colorScheme.tertiary;
    return theme.colorScheme.secondary;
  }
}
