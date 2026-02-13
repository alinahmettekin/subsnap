import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../payments/services/payment_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscriptions/views/paywall_view.dart';
import 'widgets/header_overview.dart';
import 'widgets/quick_stats_grid.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/upcoming_payments_list.dart';

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final upcomingPaymentsAsync = ref.watch(upcomingPaymentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: subscriptionsAsync.when(
        data: (subscriptions) {
          if (subscriptions.isEmpty) {
            return Center(
              child: Text(
                'Analiz için yeterli veri yok.\nLütfen abonelik ekleyin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            );
          }

          return upcomingPaymentsAsync.when(
            data: (upcoming) {
              return Consumer(
                builder: (context, ref, _) {
                  final isPremium = ref.watch(isPremiumProvider).asData?.value ?? false;

                  // Show paywall on first visit (only once)
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    final prefs = await SharedPreferences.getInstance();
                    final hasSeenPaywall = prefs.getBool('analytics_paywall_seen') ?? false;

                    if (!isPremium && !hasSeenPaywall && context.mounted) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        isDismissible: true,
                        builder: (context) => const PaywallView(),
                      ).then((_) {
                        // Mark as seen when dismissed
                        prefs.setBool('analytics_paywall_seen', true);
                      });
                    }
                  });

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // 1. Header Overview - FREE
                        HeaderOverview(subscriptions: subscriptions),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              // 2. Quick Stats Grid - FREE
                              QuickStatsGrid(subscriptions: subscriptions, upcomingPayments: upcoming),
                              const SizedBox(height: 16),

                              // 3. Category Breakdown - Show real or placeholder
                              if (isPremium)
                                CategoryDonutChart(subscriptions: subscriptions)
                              else
                                _PremiumPlaceholder(title: 'Kategori Analizi', icon: Icons.pie_chart_rounded),
                              const SizedBox(height: 32),

                              // 6. Upcoming Payments - FREE (limited to 3 for non-premium)
                              UpcomingPaymentsList(
                                subscriptions: subscriptions,
                                upcomingPayments: isPremium ? upcoming : upcoming.take(3).toList(),
                                showLimitMessage: !isPremium && upcoming.length > 3,
                              ),

                              // Premium Banner at bottom (only for non-premium)
                              if (!isPremium) ...[const SizedBox(height: 32), _PremiumBanner()],

                              const SizedBox(height: 100), // Bottom padding for FAB
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(
              child: Text('Hata: $err', style: TextStyle(color: theme.colorScheme.error)),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Hata: $err', style: TextStyle(color: theme.colorScheme.error)),
        ),
      ),
    );
  }
}

// Simple Premium Placeholder Widget
class _PremiumPlaceholder extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PremiumPlaceholder({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Premium Banner Widget
class _PremiumBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.auto_awesome_rounded, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Premium ile Daha Fazlası',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detaylı harcama trendleri, kategori analizleri ve sınırsız ödeme takibi',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallView()));
            },
            icon: const Icon(Icons.star_rounded),
            label: const Text('Premium\'a Geç'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
