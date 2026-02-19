import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:subsnap/features/payments/services/payment_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpendingHistoryChart extends ConsumerStatefulWidget {
  const SpendingHistoryChart({super.key});

  @override
  ConsumerState<SpendingHistoryChart> createState() => _SpendingHistoryChartState();
}

class _SpendingHistoryChartState extends ConsumerState<SpendingHistoryChart> {
  String _selectedPeriod = '6A'; // 1A, 6A, 1Y, 5Y
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isExpanded = prefs.getBool('spending_chart_expanded') ?? true;
    });
  }

  Future<void> _toggleExpanded() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isExpanded = !_isExpanded;
    });
    await prefs.setBool('spending_chart_expanded', _isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(paymentHistoryProvider);
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Harcama Grafiği',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onSurface,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (_isExpanded)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Row(children: ['1A', '6A', '1Y', '5Y'].map((p) => _buildPeriodButton(theme, p)).toList()),
                ),
              InkWell(
                onTap: _toggleExpanded,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (_isExpanded) const SizedBox(height: 24),

          if (_isExpanded)
            historyAsync.when(
              data: (history) {
                if (history.isEmpty) {
                  return const SizedBox(height: 200, child: Center(child: Text('Veri yok')));
                }

                // Process Data
                final now = DateTime.now();
                final List<FlSpot> spots = [];
                double maxY = 0;
                Map<int, String> titleMap = {};

                if (_selectedPeriod == '1A') {
                  // Daily for last 30 days
                  for (int i = 0; i < 30; i++) {
                    final day = now.subtract(Duration(days: 29 - i));
                    double total = 0;
                    for (var p in history) {
                      final date = p.paidAt ?? p.dueDate;
                      if (date.year == day.year && date.month == day.month && date.day == day.day) {
                        total += p.amount;
                      }
                    }
                    spots.add(FlSpot(i.toDouble(), total));
                    if (total > maxY) maxY = total;
                    if (i % 5 == 0) {
                      // Show title every 5 days
                      titleMap[i] = DateFormat('d MMM', 'tr_TR').format(day);
                    }
                  }
                } else if (_selectedPeriod == '6A') {
                  // Monthly for last 6 months
                  for (int i = 0; i < 6; i++) {
                    final month = DateTime(now.year, now.month - 5 + i, 1);
                    double total = 0;
                    for (var p in history) {
                      // Match month and year
                      final date = p.paidAt ?? p.dueDate;
                      if (date.year == month.year && date.month == month.month) {
                        total += p.amount;
                      }
                    }
                    spots.add(FlSpot(i.toDouble(), total));
                    if (total > maxY) maxY = total;
                    titleMap[i] = DateFormat('MMM', 'tr_TR').format(month);
                  }
                } else if (_selectedPeriod == '1Y') {
                  // Monthly for last 12 months
                  for (int i = 0; i < 12; i++) {
                    final month = DateTime(now.year, now.month - 11 + i, 1);
                    double total = 0;
                    for (var p in history) {
                      final date = p.paidAt ?? p.dueDate;
                      if (date.year == month.year && date.month == month.month) {
                        total += p.amount;
                      }
                    }
                    spots.add(FlSpot(i.toDouble(), total));
                    if (total > maxY) maxY = total;
                    if (i % 2 == 0) titleMap[i] = DateFormat('MMM', 'tr_TR').format(month);
                  }
                } else if (_selectedPeriod == '5Y') {
                  // Yearly for last 5 years
                  for (int i = 0; i < 5; i++) {
                    final year = now.year - 4 + i;
                    double total = 0;
                    for (var p in history) {
                      final date = p.paidAt ?? p.dueDate;
                      if (date.year == year) {
                        total += p.amount;
                      }
                    }
                    spots.add(FlSpot(i.toDouble(), total));
                    if (total > maxY) maxY = total;
                    titleMap[i] = year.toString();
                  }
                }

                if (maxY == 0) maxY = 100; // Default scale

                return SizedBox(
                  height: 160,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        // Only show a base line at 0 and maybe one at 50% opacity
                        getDrawingHorizontalLine: (value) =>
                            FlLine(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false), // Hide default axis to use custom lines
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (titleMap.containsKey(index)) {
                                return SideTitleWidget(
                                  meta: meta,
                                  child: Text(
                                    titleMap[index]!,
                                    style: TextStyle(color: onSurfaceVariant, fontSize: 10),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: spots.length.toDouble() - 1,
                      minY: 0,
                      maxY: maxY, // Exact max value
                      extraLinesData: ExtraLinesData(
                        horizontalLines: () {
                          final lines = <HorizontalLine>[];
                          // Max Value Line (Reference)
                          lines.add(
                            HorizontalLine(
                              y: maxY,
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                              strokeWidth: 1,
                              dashArray: [5, 5],
                              label: HorizontalLineLabel(
                                show: true,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(right: 5, bottom: 5),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                                labelResolver: (_) => '₺${maxY.toInt()}',
                              ),
                            ),
                          );

                          // Add lines for priority spots (First, Last, and others if distinct)
                          final prioritySpots = List<FlSpot>.from(spots);

                          for (var spot in prioritySpots) {
                            if (spot.y <= 0) continue;

                            // Check overlap with existing lines
                            bool distinct = true;
                            for (var line in lines) {
                              if ((spot.y - line.y).abs() < maxY * 0.08) {
                                // If too close (8% of range), skip
                                distinct = false;
                                break;
                              }
                            }

                            if (distinct) {
                              lines.add(
                                HorizontalLine(
                                  y: spot.y,
                                  color: onSurfaceVariant.withValues(alpha: 0.3),
                                  strokeWidth: 1,
                                  dashArray: [5, 5],
                                  label: HorizontalLineLabel(
                                    show: true,
                                    alignment: Alignment.centerLeft,
                                    padding: const EdgeInsets.only(right: 5, bottom: 5),
                                    style: TextStyle(color: onSurfaceVariant, fontSize: 10),
                                    labelResolver: (_) => '₺${spot.y.toInt()}',
                                  ),
                                ),
                              );
                            }
                          }
                          return lines;
                        }(),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: theme.colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '₺${spot.y.toStringAsFixed(0)}',
                                TextStyle(color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                          tooltipPadding: const EdgeInsets.all(8),
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipColor: (_) => theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Hata: $err')),
            ),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(ThemeData theme, String period) {
    final isSelected = _selectedPeriod == period;
    return InkWell(
      onTap: () => setState(() => _selectedPeriod = period),
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          period,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      ),
    );
  }
}
