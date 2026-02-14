import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/subscription_provider.dart';
import '../models/subscription.dart';
import '../../auth/views/settings_view.dart';
import 'widgets/delete_subscription_dialog.dart';
import 'paywall_view.dart';
import '../../../core/services/subscription_service.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_summary_card.dart';
import 'widgets/subscription_list_item.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  Future<void> _handleDelete(BuildContext context, WidgetRef ref, Subscription subscription) async {
    // Check if widget is mounted before showing dialog
    if (!context.mounted) return;

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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: subscriptionsAsync.when(
          data: (subs) => RefreshIndicator(
            onRefresh: () => ref.refresh(subscriptionsProvider.future),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: DashboardHeader(
                    onProfileTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsView()),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: DashboardSummaryCard(subscriptions: subs),
                  ),
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
                                  'Üyelik Limiti',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  '$subscriptionCount / $maxFree',
                                  style: theme.textTheme.labelLarge?.copyWith(
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
                                minHeight: 6,
                                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation(
                                  progress >= 1.0 ? theme.colorScheme.error : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            if (subscriptionCount >= 2)
                              Padding(
                                padding: const EdgeInsets.only(top: 16.0),
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallView()));
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          const Color(0xFFFFD700).withOpacity(0.15), // Gold-ish
                                          const Color(0xFFFFA500).withOpacity(0.15), // Orange-ish
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(0xFFFFD700).withOpacity(0.3),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFD700).withOpacity(0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD4AF37), size: 24),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Premium\'a Yükselt',
                                                style: theme.textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.colorScheme.onSurface,
                                                ),
                                              ),
                                              Text(
                                                'Sınırsız abonelik ve analizler',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: theme.colorScheme.onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.arrow_forward_ios_rounded, color: theme.colorScheme.primary, size: 16),
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Abonelikler',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (subs.isNotEmpty)
                          TextButton(
                            onPressed: () {}, // Future implementation: Navigate to full list
                            style: TextButton.styleFrom(
                              foregroundColor: theme.colorScheme.primary,
                              textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            child: const Text('Hepsini Gör'),
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
