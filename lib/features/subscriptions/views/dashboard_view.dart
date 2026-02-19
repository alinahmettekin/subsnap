import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import 'widgets/delete_subscription_dialog.dart';
import 'archived_subscriptions_view.dart';
import 'paywall_view.dart';
import '../../../core/services/subscription_service.dart';
import 'widgets/subscription_icon.dart';
import 'edit_subscription_view.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Subscription subscription) async {
    // Check if widget is mounted before showing dialog
    if (!context.mounted) return;

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

    return Scaffold(
      body: subscriptionsAsync.when(
        data: (subs) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(servicesProvider);
            return ref.refresh(subscriptionsProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Text(
                  'SubSnap',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchivedSubscriptionsView())),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.4),
                      ),
                      child: Icon(Icons.history_rounded, color: theme.colorScheme.secondary),
                    ),
                    tooltip: 'İptal Edilenler',
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                  child: _buildSummaryCard(context, subs),
                ),
              ),
              // Premium/Usage Box
              SliverToBoxAdapter(
                child: Consumer(
                  builder: (context, ref, _) {
                    final isPremiumAsync = ref.watch(isPremiumProvider);

                    return isPremiumAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (isPremium) {
                        if (isPremium) return const SizedBox.shrink();

                        final subscriptionCount = subs.length;
                        const maxFree = 3;
                        final progress = subscriptionCount / maxFree;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Abonelik Limiti',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                    ),
                                  ),
                                  Text(
                                    '$subscriptionCount/$maxFree',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: progress >= 1.0 ? theme.colorScheme.error : theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress.clamp(0.0, 1.0),
                                  minHeight: 8,
                                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    progress >= 1.0 ? theme.colorScheme.error : theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                              if (subscriptionCount >= 2)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallView()));
                                    },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            theme.colorScheme.primaryContainer,
                                            theme.colorScheme.secondaryContainer,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star_rounded, color: theme.colorScheme.primary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Premium\'a Geç',
                                                  style: theme.textTheme.titleSmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: theme.colorScheme.onPrimaryContainer,
                                                  ),
                                                ),
                                                Text(
                                                  'Sınırsız abonelik ekle',
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Abonelikler',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
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
                            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add_circle_outline_rounded,
                            size: 48,
                            color: theme.colorScheme.primary.withValues(alpha: 0.5),
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
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final subscription = subs[index];
                      return Dismissible(
                        key: Key(subscription.id),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          await _handleDelete(context, ref, subscription);
                          return false; // Manually handled delete
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
                        child: _SubscriptionListTile(subscription: subscription),
                      );
                    }, childCount: subs.length),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Hata oluştu: $err')),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, List<Subscription> subs) {
    final total = subs.fold(0.0, (sum, item) {
      if (item.billingCycle == 'monthly') return sum + item.price;
      if (item.billingCycle == 'yearly') return sum + (item.price / 12);
      return sum;
    });

    final theme = Theme.of(context);

    // Find next billing date
    DateTime? nextBilling;
    if (subs.isNotEmpty) {
      final sorted = List<Subscription>.from(subs)..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
      nextBilling = sorted.first.nextBillingDate;
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aylık Harcama Tahmini',
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${total.toStringAsFixed(2)} ₺',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontSize: 36,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildSummaryIndicator(context, 'Abonelik', '${subs.length}'),
              const Spacer(),
              _buildSummaryIndicator(
                context,
                'Sıradaki',
                nextBilling != null ? DateFormat('dd MMM', 'tr_TR').format(nextBilling) : '-',
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

class _SubscriptionListTile extends StatelessWidget {
  final Subscription subscription;

  const _SubscriptionListTile({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => EditSubscriptionView(subscription: subscription),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                SubscriptionIcon(subscription: subscription),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subscription.name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 12, color: theme.colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy', 'tr_TR').format(subscription.nextBillingDate),
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${subscription.price} ${subscription.currency}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        subscription.billingCycle == 'monthly' ? 'Aylık' : 'Yıllık',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 9,
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
}
