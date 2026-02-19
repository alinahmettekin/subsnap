import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';
import 'package:subsnap/features/subscriptions/providers/subscription_provider.dart';

class CategoryDonutChart extends ConsumerStatefulWidget {
  final List<Subscription> subscriptions;

  const CategoryDonutChart({super.key, required this.subscriptions});

  @override
  ConsumerState<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends ConsumerState<CategoryDonutChart> {
  bool _isMonthly = true; // State to toggle between Monthly/Yearly
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.userMetadata != null && user.userMetadata!.containsKey('is_category_analysis_expanded')) {
      _isExpanded = user.userMetadata!['is_category_analysis_expanded'] as bool;
    }
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    // Save preference to Supabase Auth Metadata
    try {
      Supabase.instance.client.auth.updateUser(UserAttributes(data: {'is_category_analysis_expanded': _isExpanded}));
    } catch (e) {
      debugPrint('Failed to save expansion preference: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final categoriesAsync = ref.watch(categoriesProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          GestureDetector(
            onTap: _toggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Kategori Analizi',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
                // Toggle Button (Visible only when expanded, or always? Let's hide when collapsed for cleaner look)
                if (_isExpanded)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [_buildToggleButton(theme, 'Aylık', true), _buildToggleButton(theme, 'Yıllık', false)],
                    ),
                  ),

                // Expansion Icon
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  color: onSurfaceVariant,
                ),
              ],
            ),
          ),

          // Collapsible Content
          AnimatedCrossFade(
            firstChild: Container(), // Collapsed state (empty)
            secondChild: Column(
              children: [
                const SizedBox(height: 24),
                categoriesAsync.when(
                  data: (categories) {
                    final Map<String, double> categoryCosts = {};
                    final Map<String, Color> categoryColors = {};
                    final Map<String, String> categoryNames = {};
                    final Map<String, IconData> categoryIcons = {};

                    // Pre-process category metadata
                    for (var cat in categories) {
                      final id = cat['id'] as String;
                      categoryNames[id] = cat['name'] as String;
                      final colorHex = cat['color'] as String?;
                      categoryColors[id] = colorHex != null
                          ? Color(int.parse(colorHex.replaceFirst('#', '0xFF')))
                          : theme.colorScheme.primary;
                      categoryIcons[id] = _getCategoryIcon(cat['name'] as String);
                    }

                    double totalCost = 0;

                    // Calculate costs based on _isMonthly
                    for (var sub in widget.subscriptions) {
                      final catId = sub.categoryId ?? 'unknown';

                      double cost = 0;
                      if (_isMonthly) {
                        // Monthly View
                        cost = sub.billingCycle == 'monthly' ? sub.price : sub.price / 12;
                      } else {
                        // Yearly View
                        cost = sub.billingCycle == 'yearly' ? sub.price : sub.price * 12;
                      }

                      categoryCosts[catId] = (categoryCosts[catId] ?? 0) + cost;
                      totalCost += cost;
                    }

                    if (totalCost == 0) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text('Görüntülenecek veri yok', style: TextStyle(color: onSurfaceVariant)),
                        ),
                      );
                    }

                    // Filter out zero categories and sort by cost
                    final sortedEntries = categoryCosts.entries.where((e) => e.value > 0).toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    // Pie Chart Sections
                    final sections = sortedEntries.map((entry) {
                      final catId = entry.key;
                      final value = entry.value;
                      return PieChartSectionData(
                        color: categoryColors[catId] ?? theme.colorScheme.primary,
                        value: value,
                        title: '',
                        radius: 20, // Slightly thicker ring
                        showTitle: false,
                      );
                    }).toList();

                    return Column(
                      children: [
                        // Donut Chart
                        SizedBox(
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              PieChart(
                                PieChartData(
                                  sections: sections,
                                  centerSpaceRadius: 55,
                                  sectionsSpace: 4,
                                  startDegreeOffset: -90,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '₺${totalCost.toStringAsFixed(0)}',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: onSurface,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  Text(
                                    _isMonthly ? 'Aylık Toplam' : 'Yıllık Toplam',
                                    style: theme.textTheme.bodySmall?.copyWith(color: onSurfaceVariant),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Category List Breakdown
                        Column(
                          children: sortedEntries.map((entry) {
                            final catId = entry.key;
                            final cost = entry.value;
                            final name = categoryNames[catId] ?? 'Diğer';
                            final color = categoryColors[catId] ?? theme.colorScheme.primary;
                            final icon = categoryIcons[catId] ?? Icons.category_rounded;
                            final percentage = (cost / totalCost) * 100;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Row(
                                children: [
                                  // Icon Box
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(icon, color: color, size: 20),
                                  ),
                                  const SizedBox(width: 16),

                                  // Name & Percentage
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        // Progress Bar background
                                        Stack(
                                          children: [
                                            Container(
                                              height: 4,
                                              width: 100,
                                              decoration: BoxDecoration(
                                                color: theme.colorScheme.surfaceContainerHighest,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                            Container(
                                              height: 4,
                                              width: percentage.clamp(0, 100).toDouble(), // Simple width proportional
                                              decoration: BoxDecoration(
                                                color: color,
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Cost & Percentage Text
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '₺${cost.toStringAsFixed(0)}',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: onSurface,
                                        ),
                                      ),
                                      Text(
                                        '%${percentage.toStringAsFixed(1)}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: onSurfaceVariant,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => Text('Veri yüklenemedi', style: TextStyle(color: theme.colorScheme.error)),
                ),
              ],
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(ThemeData theme, String text, bool isMonthlyOption) {
    final isSelected = _isMonthly == isMonthlyOption;
    return InkWell(
      onTap: () => setState(() => _isMonthly = isMonthlyOption),
      borderRadius: BorderRadius.circular(6),
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
          text,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
            fontSize: 9,
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    // Simplified icon mapping, can be expanded or use IconHelper
    switch (name.toLowerCase()) {
      case 'yazılım':
        return Icons.code_rounded;
      case 'eğlence':
        return Icons.movie_rounded;
      case 'dijital platformlar':
        return Icons.movie_filter_rounded;
      case 'araçlar':
        return Icons.cloud_rounded;
      case 'eğitim':
        return Icons.school_rounded;
      case 'müzik':
        return Icons.music_note_rounded;
      case 'finans':
        return Icons.attach_money_rounded;
      case 'finansk': // Typo specific fix if needed, assuming the previous switch had typos or specific cases.
        return Icons.attach_money_rounded;
      case 'iş & kariyer':
        return Icons.work_rounded;
      case 'tasarım':
        return Icons.palette_rounded;
      case 'yapay zeka':
        return Icons.psychology_rounded;
      case 'alışveriş':
        return Icons.shopping_bag_rounded;
      case 'mobil operatörler':
        return Icons.phone_android_rounded;
      case 'internet servis sağlayıcıları':
        return Icons.wifi_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
