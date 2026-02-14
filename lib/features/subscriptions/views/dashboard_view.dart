import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import '../../auth/views/settings_view.dart';
import 'widgets/delete_subscription_dialog.dart';
import 'paywall_view.dart';
import '../../../core/services/subscription_service.dart';
import 'widgets/subscription_icon.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Subscription subscription) async {
    // Check if widget is mounted before showing dialog
    if (!context.mounted) return;

  Widget _buildSummaryCard(BuildContext context, List<Subscription> subs) {
    final total = subs.fold(0.0, (sum, item) {
      if (item.billingCycle == 'monthly') return sum + item.price;
      if (item.billingCycle == 'yearly') return sum + (item.price / 12);
      return sum;
    });

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withAlpha(80), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aylık Harcama Tahmini',
            style: theme.textTheme.labelMedium?.copyWith(color: Colors.white.withAlpha(180), letterSpacing: 1.1),
          ),
          const SizedBox(height: 12),
          Text(
            '${total.toStringAsFixed(2)} ₺',
            style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSummaryIndicator(context, 'Abonelik', '${subs.length}'),
              const Spacer(),
              _buildSummaryIndicator(
                context,
                'Sıradaki',
                subs.isNotEmpty ? DateFormat('dd MMM', 'tr_TR').format(subs.first.nextBillingDate) : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryIndicator(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ],
    );
  }
}

class _SubscriptionListTile extends ConsumerWidget {
  final Subscription subscription;

  const _SubscriptionListTile({required this.subscription});

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    // Import the dialog
    final result = await showDialog<DeleteOption>(
      context: context,
      builder: (context) => DeleteSubscriptionDialog(subscriptionName: subscription.name),
    );

    if (result == null || !context.mounted) return;

    try {
      final repository = ref.read(subscriptionRepositoryProvider);

      if (result == DeleteOption.subscriptionOnly) {
        await repository.deleteSubscription(subscription.id);
      } else {
        await repository.deleteSubscriptionWithPayments(subscription.id);
      }

      // Refresh the subscriptions list
      ref.invalidate(subscriptionsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Abonelik başarıyla silindi'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Silme işlemi başarısız: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(subscription.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _handleDelete(context, ref);
        return false; // Don't auto-dismiss, we handle it manually
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 32),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            SubscriptionIcon(subscription: subscription),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subscription.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    'Yenileme: ${DateFormat('dd MMM', 'tr_TR').format(subscription.nextBillingDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: DashboardSummaryCard(subscriptions: subs),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      subscription.billingCycle == 'monthly' ? 'aylık' : 'yıllık',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => SubscriptionService.manageSubscriptions(),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(Icons.open_in_new_rounded, size: 16, color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
                if (subs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add_circle_outline_rounded,
                              size: 48,
                              color: theme.colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Henüz abonelik yok',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Takip etmek için ilk aboneliğinizi ekleyin',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final subscription = subs[index];
                          return Dismissible(
                            key: Key(subscription.id),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              await _handleDelete(context, ref, subscription);
                              return false; // Manually handled refresh
                            },
                            background: Container(
                              alignment: Alignment.centerRight,
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.only(right: 24),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(Icons.delete_rounded, color: Colors.white, size: 28),
                            ),
                            child: SubscriptionListItem(
                              subscription: subscription,
                              onTap: () {
                                // Future: Navigate to details
                              },
                              onDelete: () async => await _handleDelete(context, ref, subscription),
                            ),
                          );
                        },
                        childCount: subs.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Bir hata oluştu: $err')),
        ),
      ),
    );
  }
}
