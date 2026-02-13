import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import 'package:intl/intl.dart';
import '../../auth/views/settings_view.dart';
import 'widgets/delete_subscription_dialog.dart';
import 'paywall_view.dart';
import '../../../core/services/subscription_service.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: subscriptionsAsync.when(
        data: (subs) => RefreshIndicator(
          onRefresh: () => ref.refresh(subscriptionsProvider.future),
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
                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsView())),
                    icon: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primaryContainer.withAlpha(100),
                      ),
                      child: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(padding: const EdgeInsets.all(20.0), child: _buildSummaryCard(context, subs)),
              ),
              // Premium usage indicator
              Consumer(
                builder: (context, ref, _) {
                  final isPremium = ref.watch(isPremiumProvider).asData?.value ?? false;
                  if (isPremium) return const SliverToBoxAdapter(child: SizedBox.shrink());

                  final subscriptionCount = subs.length;
                  const maxFree = 3;
                  final progress = subscriptionCount / maxFree;

                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Abonelik Kullanımı',
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
                    ),
                  );
                },
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
                      TextButton(onPressed: () {}, child: const Text('Hepsini Gör')),
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
                        Icon(
                          Icons.subscriptions_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text('Henüz abonelik eklemediniz.'),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _SubscriptionListTile(subscription: subs[index]),
                      childCount: subs.length,
                    ),
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
                subs.isNotEmpty ? DateFormat('dd MMM').format(subs.first.nextBillingDate) : '-',
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
    final DeleteOption? result = await showDialog<DeleteOption>(
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
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withAlpha(150),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  subscription.name[0].toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: theme.colorScheme.primary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subscription.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    'Yenileme: ${DateFormat('dd MMM').format(subscription.nextBillingDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subscription.billingCycle == 'monthly' ? 'aylık' : 'yıllık',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
