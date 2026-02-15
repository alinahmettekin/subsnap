import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/features/payments/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MonthlyComparisonCard extends ConsumerStatefulWidget {
  const MonthlyComparisonCard({super.key});

  @override
  ConsumerState<MonthlyComparisonCard> createState() => _MonthlyComparisonCardState();
}

class _MonthlyComparisonCardState extends ConsumerState<MonthlyComparisonCard> {
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isExpanded = prefs.getBool('monthly_comparison_expanded') ?? true;
    });
  }

  Future<void> _toggleExpanded() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isExpanded = !_isExpanded;
    });
    await prefs.setBool('monthly_comparison_expanded', _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(paymentHistoryProvider);
    final upcomingAsync = ref.watch(upcomingPaymentsProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: historyAsync.when(
        data: (history) {
          return upcomingAsync.when(
            data: (upcoming) {
              final now = DateTime.now();
              final thisMonth = DateTime(now.year, now.month);
              final lastMonth = DateTime(now.year, now.month - 1);

              // Calculate Last Month Total (Real payments)
              double lastMonthTotal = 0;
              for (var p in history) {
                final date = p.paidAt ?? p.dueDate;
                if (date.year == lastMonth.year && date.month == lastMonth.month) {
                  lastMonthTotal += p.amount;
                }
              }

              // Calculate This Month Total (Real payments + Upcoming)
              double thisMonthTotal = 0;
              // 1. Paid this month
              for (var p in history) {
                final date = p.paidAt ?? p.dueDate;
                if (date.year == thisMonth.year && date.month == thisMonth.month) {
                  thisMonthTotal += p.amount;
                }
              }
              // 2. Upcoming this month
              for (var p in upcoming) {
                final date = p.dueDate;
                if (date.year == thisMonth.year && date.month == thisMonth.month) {
                  thisMonthTotal += p.amount;
                }
              }

              // Calculate Change
              double change = 0;
              if (lastMonthTotal > 0) {
                change = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
              } else if (thisMonthTotal > 0) {
                change = 100;
              }

              final isIncrease = change > 0;
              final isDecrease = change < 0;
              final changeColor = isIncrease
                  ? theme.colorScheme.error
                  : (isDecrease ? Colors.green : theme.colorScheme.onSurface);
              final icon = isIncrease
                  ? Icons.arrow_upward_rounded
                  : (isDecrease ? Icons.arrow_downward_rounded : Icons.remove_rounded);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: _toggleExpanded,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Aylık Karşılaştırma',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Icon(
                            _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bu Ay',
                              style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₺${thisMonthTotal.toStringAsFixed(0)}',
                              style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: changeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(icon, size: 16, color: changeColor),
                              const SizedBox(width: 4),
                              Text(
                                '${change.abs().toStringAsFixed(1)}%',
                                style: TextStyle(color: changeColor, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Geçen ay ₺${lastMonthTotal.toStringAsFixed(0)} harcadınız.',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox(),
          );
        },
        loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
        error: (err, _) => Text('Hata: $err'),
      ),
    );
  }
}
