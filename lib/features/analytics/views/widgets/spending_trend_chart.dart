import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';

class SpendingTrendChart extends StatelessWidget {
  final List<Subscription> subscriptions;

  const SpendingTrendChart({super.key, required this.subscriptions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    final now = DateTime.now();
    final List<FlSpot> spots = [];

    // Calculate projected spending for the next 6 months
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month + i, 1);
      double monthTotal = 0;

      for (var sub in subscriptions) {
        if (sub.billingCycle == 'monthly') {
          monthTotal += sub.price;
        } else if (sub.nextBillingDate.month == month.month) {
          monthTotal += sub.price;
        }
      }
      spots.add(FlSpot(i.toDouble(), monthTotal));
    }

    if (spots.isEmpty) return const SizedBox();

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2;
    final lineStart = theme.colorScheme.primary;
    final lineEnd = theme.colorScheme.tertiary;

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Harcama Trendi',
            style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('Gelecek 6 aylık ödeme projeksiyonu', style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
          const SizedBox(height: 24),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY / 3 : 1,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: onSurfaceVariant.withValues(alpha: 0.2), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final date = DateTime(now.year, now.month + value.toInt(), 1);
                        return SideTitleWidget(
                          meta: meta,
                          fitInside: SideTitleFitInsideData(
                            enabled: true,
                            axisPosition: meta.axisPosition,
                            parentAxisSize: meta.parentAxisSize,
                            distanceFromEdge: 2,
                          ),
                          child: Text(
                            DateFormat('MMM').format(date),
                            style: TextStyle(color: onSurfaceVariant.withValues(alpha: 0.7), fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    gradient: LinearGradient(colors: [lineStart, lineEnd]),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [lineStart.withValues(alpha: 0.2), lineEnd.withValues(alpha: 0.0)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
