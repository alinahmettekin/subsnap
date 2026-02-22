import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';
import 'package:subsnap/features/subscriptions/providers/subscription_provider.dart';
import 'package:subsnap/features/subscriptions/views/widgets/subscription_icon.dart';

class CategoryDonutChart extends ConsumerStatefulWidget {
  final List<Subscription> subscriptions;

  const CategoryDonutChart({super.key, required this.subscriptions});

  @override
  ConsumerState<CategoryDonutChart> createState() => _CategoryDonutChartState();
}

class _CategoryDonutChartState extends ConsumerState<CategoryDonutChart> {
  bool _isMonthly = true; // State to toggle between Monthly/Yearly
  bool _isExpanded = true;
  String? _expandedCategoryId;
  int _touchedIndex = -1;

  final List<Color> _chartColors = [
    const Color(0xFF6366F1), // Indigo
    const Color(0xFFEC4899), // Pink
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFFF43F5E), // Rose
    const Color(0xFF06B6D4), // Cyan
    const Color(0xFF84CC16), // Lime
    const Color(0xFFEF4444), // Red
  ];

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
                    final Map<String, List<Subscription>> categorySubscriptions = {};
                    final Map<String, String> categoryNames = {};
                    final Map<String, Color> categoryColors = {};
                    final Map<String, String> categoryIconPaths = {};

                    // Pre-process category metadata with automatic color distribution
                    for (int i = 0; i < categories.length; i++) {
                      final cat = categories[i];
                      final id = cat['id'] as String;
                      categoryNames[id] = cat['name'] as String;
                      final colorHex = cat['color'] as String?;

                      // Use DB color if exists, otherwise cycle through _chartColors
                      categoryColors[id] = colorHex != null
                          ? Color(int.parse(colorHex.replaceFirst('#', '0xFF')))
                          : _chartColors[i % _chartColors.length];

                      categoryIconPaths[id] = _getCategoryIconPath(cat['name'] as String);
                    }

                    double totalCost = 0;

                    // Calculate costs based on _isMonthly
                    for (var sub in widget.subscriptions) {
                      final catId = sub.categoryId ?? 'unknown';
                      categorySubscriptions.putIfAbsent(catId, () => []).add(sub);
                      totalCost += _calculateCost(sub);
                    }

                    // Special handling for 'unknown' category if it exists
                    if (categorySubscriptions.containsKey('unknown')) {
                      categoryNames['unknown'] = 'Diğer';
                      categoryColors['unknown'] = theme.colorScheme.outline;
                      categoryIconPaths['unknown'] = 'assets/categories/other.png';
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
                    final sortedEntries =
                        categorySubscriptions.entries.where((e) => _calculateCategoryCost(e.value) > 0).toList()
                          ..sort((a, b) => _calculateCategoryCost(b.value).compareTo(_calculateCategoryCost(a.value)));

                    // Pie Chart Sections
                    final sections = List.generate(sortedEntries.length, (i) {
                      final entry = sortedEntries[i];
                      final catId = entry.key;
                      final value = _calculateCategoryCost(entry.value);
                      final isTouched = i == _touchedIndex;

                      return PieChartSectionData(
                        color: categoryColors[catId] ?? theme.colorScheme.primary,
                        value: value,
                        title: '',
                        radius: isTouched ? 28 : 20,
                        showTitle: false,
                        badgeWidget: isTouched
                            ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: categoryColors[catId] ?? theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4)],
                                ),
                                child: Image.asset(
                                  categoryIconPaths[catId] ?? 'assets/categories/other.png',
                                  width: 16,
                                  height: 16,
                                ),
                              )
                            : null,
                        badgePositionPercentageOffset: 1.1,
                      );
                    });

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
                                  pieTouchData: PieTouchData(
                                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                      setState(() {
                                        if (!event.isInterestedForInteractions ||
                                            pieTouchResponse == null ||
                                            pieTouchResponse.touchedSection == null) {
                                          _touchedIndex = -1;
                                          return;
                                        }
                                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                      });
                                    },
                                  ),
                                  sections: sections,
                                  centerSpaceRadius: 55,
                                  sectionsSpace: 4,
                                  startDegreeOffset: -90,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_touchedIndex == -1) ...[
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
                                  ] else ...[
                                    Text(
                                      categoryNames[sortedEntries[_touchedIndex].key] ?? '',
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    Text(
                                      '%${((_calculateCategoryCost(sortedEntries[_touchedIndex].value) / totalCost) * 100).toStringAsFixed(1)}',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: categoryColors[sortedEntries[_touchedIndex].key],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
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
                            final subs = entry.value;
                            final categoryCost = _calculateCategoryCost(subs);
                            final name = categoryNames[catId] ?? 'Diğer';
                            final color = categoryColors[catId] ?? theme.colorScheme.primary;
                            final iconPath = categoryIconPaths[catId] ?? 'assets/categories/other.png';
                            final percentage = (categoryCost / totalCost) * 100;
                            final isExpanded = _expandedCategoryId == catId;

                            return Column(
                              children: [
                                InkWell(
                                  onTap: () {
                                    setState(() {
                                      _expandedCategoryId = isExpanded ? null : catId;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Row(
                                      children: [
                                        // Icon Box
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceContainerHigh,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Image.asset(iconPath, width: 24, height: 24),
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
                                                    width: percentage.clamp(0, 100).toDouble(),
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
                                            Row(
                                              children: [
                                                Text(
                                                  '₺${categoryCost.toStringAsFixed(0)}',
                                                  style: theme.textTheme.bodyMedium?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: onSurface,
                                                  ),
                                                ),
                                                Icon(
                                                  isExpanded
                                                      ? Icons.keyboard_arrow_up_rounded
                                                      : Icons.keyboard_arrow_down_rounded,
                                                  size: 16,
                                                  color: onSurfaceVariant,
                                                ),
                                              ],
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
                                  ),
                                ),
                                // Subscriptions list if expanded
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 52, top: 4, bottom: 12),
                                    child: Column(
                                      children: subs.map((sub) {
                                        final subCost = _calculateCost(sub);
                                        final subPercentage = (subCost / categoryCost) * 100;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6),
                                          child: Row(
                                            children: [
                                              SubscriptionIcon(subscription: sub, size: 28),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  sub.name,
                                                  style: theme.textTheme.bodySmall?.copyWith(
                                                    color: onSurface.withValues(alpha: 0.8),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '₺${subCost.toStringAsFixed(0)}',
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: onSurface,
                                                    ),
                                                  ),
                                                  Text(
                                                    '%${subPercentage.toStringAsFixed(0)}',
                                                    style: theme.textTheme.labelSmall?.copyWith(
                                                      color: onSurfaceVariant,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                if (!isExpanded) const SizedBox(height: 8),
                              ],
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

  double _calculateCost(Subscription sub) {
    if (_isMonthly) {
      return sub.billingCycle == 'monthly' ? sub.price : sub.price / 12;
    } else {
      return sub.billingCycle == 'yearly' ? sub.price : sub.price * 12;
    }
  }

  double _calculateCategoryCost(List<Subscription> subs) {
    return subs.fold(0.0, (sum, sub) => sum + _calculateCost(sub));
  }

  String _getCategoryIconPath(String name) {
    switch (name.toLowerCase()) {
      case 'yazılım':
        return 'assets/categories/code.png';
      case 'eğlence':
      case 'dijital platformlar':
      case 'müzik':
        return 'assets/categories/film.png';
      case 'araçlar':
        return 'assets/categories/tools.png';
      case 'eğitim':
        return 'assets/categories/school.png';
      case 'finans':
      case 'finansk':
        return 'assets/categories/attach_money.png';
      case 'iş & kariyer':
        return 'assets/categories/work.png';
      case 'tasarım':
        return 'assets/categories/palette.png';
      case 'yapay zeka':
        return 'assets/categories/ai.png';
      case 'alışveriş':
        return 'assets/categories/shopping_bag.png';
      case 'mobil operatörler':
        return 'assets/categories/phone.png';
      case 'internet servis sağlayıcıları':
        return 'assets/categories/wifi.png';
      default:
        return 'assets/categories/other.png';
    }
  }
}
