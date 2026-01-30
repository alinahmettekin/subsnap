import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:subsnap/features/analytics/presentation/analytics_provider.dart';
import 'package:subsnap/core/utils/currency_formatter.dart';
import 'package:subsnap/features/subscriptions/presentation/subscription_provider.dart';
import 'package:subsnap/features/payments/presentation/paywall_screen.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int touchedIndex = -1;

  Future<void> _selectCustomRange(BuildContext context, WidgetRef ref) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: ref.read(customDateRangeProvider),
      confirmText: 'SEÇ',
      saveText: 'KAYDET',
      helpText: 'Tarih Aralığı Seçin',
    );

    if (picked != null) {
      ref.read(analyticsPeriodProvider.notifier).state = AnalyticsPeriod.custom;
      ref.read(customDateRangeProvider.notifier).state = picked;
    }
  }

  String _getPeriodTitle(AnalyticsPeriod period, DateTime start, DateTime end) {
    switch (period) {
      case AnalyticsPeriod.thisMonth:
        return 'Bu Ay';
      case AnalyticsPeriod.lastMonth:
        return 'Geçen Ay';
      case AnalyticsPeriod.thisYear:
        return 'Bu Yıl';
      case AnalyticsPeriod.lastYear:
        return 'Geçen Yıl';
      case AnalyticsPeriod.custom:
        return '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM').format(end)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check PRO status
    final isPro = ref.watch(isProUserProvider);

    if (!isPro) {
      return Scaffold(
        appBar: AppBar(title: const Text('Harcama Analizi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                const SizedBox(height: 24),
                Text(
                  'Bu özellik Pro kullanıcılara özeldir.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Harcamalarınızı detaylı analiz etmek için Pro plana geçin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallScreen()));
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Pro\'ya Geç'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // PRO user content below
    final analyticsAsync = ref.watch(analyticsDataProvider);
    final period = ref.watch(analyticsPeriodProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Harcama Analizi'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Periyot Seçici - Daha temiz bir SegmentedButton
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<AnalyticsPeriod>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: AnalyticsPeriod.thisMonth, label: Text('Bu Ay', style: TextStyle(fontSize: 13))),
                  ButtonSegment(
                      value: AnalyticsPeriod.lastMonth, label: Text('Geçen Ay', style: TextStyle(fontSize: 13))),
                  ButtonSegment(value: AnalyticsPeriod.thisYear, label: Text('Yıl', style: TextStyle(fontSize: 13))),
                  ButtonSegment(value: AnalyticsPeriod.custom, label: Text('Özel', style: TextStyle(fontSize: 13))),
                ],
                selected: {period},
                onSelectionChanged: (value) {
                  ref.read(analyticsPeriodProvider.notifier).state = value.first;
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Özel Tarih Aralığı Seçiciler (Sadece Özel modda görünür)
            if (period == AnalyticsPeriod.custom) ...[
              Row(
                children: [
                  Expanded(
                    child: _DateInputField(
                      label: 'Başlangıç',
                      date: ref.watch(customDateRangeProvider)?.start,
                      onTap: () => _selectCustomRange(context, ref),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateInputField(
                      label: 'Bitiş',
                      date: ref.watch(customDateRangeProvider)?.end,
                      onTap: () => _selectCustomRange(context, ref),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Özet Kartı
            analyticsAsync.when(
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getPeriodTitle(period, data.startDate, data.endDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(data: data),
                ],
              ),
              loading: () => const _SummaryCardLoading(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 32),

            // Grafik Alanı
            analyticsAsync.when(
              data: (data) {
                if (data.subscriptionSpend.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Column(
                        children: [
                          Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text(
                            'Bu tarihler arasında\nharcama kaydı bulunamadı.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  touchedIndex = -1;
                                  return;
                                }
                                touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          sections: _showingSections(data, isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Detay Listesi Başlığı
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Harcama Detayları',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    // Detay Listesi
                    ...data.subscriptionSpend.entries.map((entry) {
                      final index = data.subscriptionSpend.keys.toList().indexOf(entry.key);
                      final isTouched = index == touchedIndex;
                      return _SubscriptionDetailRow(
                        name: entry.key,
                        amount: entry.value,
                        color: _getSectionColor(index),
                        isTouched: isTouched,
                        percentage: (entry.value / data.totalAmount) * 100,
                      );
                    }),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Hata: $e')),
            ),

            const SizedBox(height: 100), // BottomNav için boşluk
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections(AnalyticsData data, bool isDark) {
    final entries = data.subscriptionSpend.entries.toList();

    return List.generate(entries.length, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 75.0 : 65.0;
      final widgetSize = isTouched ? 60.0 : 45.0;

      return PieChartSectionData(
        color: _getSectionColor(i),
        value: entries[i].value,
        title: '', // Rakamı rozet içinde göstereceğiz
        radius: radius,
        badgeWidget: isTouched
            ? _Badge(
                '${entries[i].key}\nToplam: ${CurrencyFormatter.format(entries[i].value, currency: 'TRY', decimalDigits: 0)}',
                size: widgetSize,
              )
            : null,
        badgePositionPercentageOffset: 1.15,
      );
    });
  }

  Color _getSectionColor(int index) {
    const colors = [
      Color(0xFF6366F1), // Indigo
      Color(0xFFEC4899), // Pink
      Color(0xFFF59E0B), // Amber
      Color(0xFF10B981), // Emerald
      Color(0xFF8B5CF6), // Violet
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF43F5E), // Rose
      Color(0xFF3B82F6), // Blue
    ];
    return colors[index % colors.length];
  }
}

class _DateInputField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateInputField({
    required this.label,
    this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  date != null ? DateFormat('dd.MM.yyyy').format(date!) : 'Seçiniz',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
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

class _Badge extends StatelessWidget {
  final String label;
  final double size;

  const _Badge(this.label, {required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .2),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

class _SubscriptionDetailRow extends StatelessWidget {
  final String name;
  final double amount;
  final Color color;
  final bool isTouched;
  final double percentage;

  const _SubscriptionDetailRow({
    required this.name,
    required this.amount,
    required this.color,
    required this.isTouched,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTouched ? color.withValues(alpha: 0.08) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTouched ? color.withValues(alpha: 0.4) : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isTouched
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                fontWeight: isTouched ? FontWeight.bold : FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(amount, currency: 'TRY'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 2),
              Text(
                '%${percentage.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final AnalyticsData data;

  const _SummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // Modern Indigo
            Color(0xFF4F46E5),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toplam Harcama',
            style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(data.totalAmount, currency: 'TRY'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardLoading extends StatelessWidget {
  const _SummaryCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}
