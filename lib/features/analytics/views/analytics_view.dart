import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../subscriptions/providers/subscription_provider.dart';
import '../../payments/services/payment_service.dart';
import '../../../core/services/subscription_service.dart';
import '../../subscriptions/views/paywall_view.dart';

import 'widgets/quick_stats_grid.dart';
import 'widgets/category_donut_chart.dart';
import 'widgets/monthly_comparison_card.dart';
import 'widgets/payment_method_breakdown.dart';
import 'widgets/spending_history_chart.dart';

// ... (inside build)

class AnalyticsView extends ConsumerWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsProvider);
    final upcomingPaymentsAsync = ref.watch(upcomingPaymentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('Harcama Analizi'), scrolledUnderElevation: 0),
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
                  final isPremiumAsync = ref.watch(isPremiumProvider);

                  return isPremiumAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_, _) => Center(
                      child: Text('Hata oluştu', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                    data: (isPremium) {
                      // Paywall logic
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
                            prefs.setBool('analytics_paywall_seen', true);
                          });
                        }
                      });

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Column(
                                children: [
                                  QuickStatsGrid(subscriptions: subscriptions, upcomingPayments: upcoming),
                                  const SizedBox(height: 12),

                                  if (isPremium) ...[
                                    // 2. Spending History Chart
                                    const SpendingHistoryChart(),
                                    const SizedBox(height: 12),

                                    // 3. Monthly Comparison
                                    const MonthlyComparisonCard(),
                                    const SizedBox(height: 12),

                                    // 3. Advanced Analysis
                                    CategoryDonutChart(subscriptions: subscriptions),
                                    const SizedBox(height: 16),
                                    PaymentMethodBreakdown(subscriptions: subscriptions),
                                  ] else ...[
                                    _PremiumBanner(),
                                  ],
                                  const SizedBox(height: 120), // Bottom padding
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Detaylı harcama trendleri, kategori analizleri ve sınırsız ödeme takibi',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
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
