import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';
import 'package:subsnap/features/subscriptions/providers/subscription_provider.dart';

class CategoryDonutChart extends ConsumerWidget {
  final List<Subscription> subscriptions;

  const CategoryDonutChart({super.key, required this.subscriptions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    final categoriesAsync = ref.watch(categoriesProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategori Analizi',
            style: TextStyle(color: onSurface, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          categoriesAsync.when(
            data: (categories) {
              final Map<String, double> categoryCosts = {};
              final Map<String, Color> categoryColors = {};
              final Map<String, String> categoryNames = {};
              final Map<String, IconData> categoryIcons = {};

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
              for (var sub in subscriptions) {
                final catId = sub.categoryId ?? 'unknown';
                final cost = sub.billingCycle == 'monthly' ? sub.price : sub.price / 12;
                categoryCosts[catId] = (categoryCosts[catId] ?? 0) + cost;
                totalCost += cost;
              }

              if (totalCost == 0) {
                return Center(
                  child: Text('Veri yok', style: TextStyle(color: onSurfaceVariant)),
                );
              }

              final sections = categoryCosts.entries.map((entry) {
                final catId = entry.key;
                final value = entry.value;
                return PieChartSectionData(
                  color: categoryColors[catId] ?? theme.colorScheme.primary,
                  value: value,
                  title: '',
                  radius: 20,
                  showTitle: false,
                );
              }).toList();

              return Column(
                children: [
                  SizedBox(
                    height: 180,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sections: sections,
                            centerSpaceRadius: 60,
                            sectionsSpace: 4,
                            startDegreeOffset: -90,
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₺${totalCost.toStringAsFixed(0)}',
                                style: TextStyle(color: onSurface, fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              Text('Aylık', style: TextStyle(color: onSurfaceVariant, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  ...categoryCosts.entries.map((entry) {
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: TextStyle(color: onSurface, fontSize: 14)),
                                Text(
                                  '%${percentage.toStringAsFixed(0)} Dağılım',
                                  style: TextStyle(color: onSurfaceVariant, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₺${cost.toStringAsFixed(0)}',
                            style: TextStyle(color: onSurface, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text('Hata oluştu', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    switch (name.toLowerCase()) {
      case 'yazılım':
        return Icons.code_rounded;
      case 'eğlence':
        return Icons.movie_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'eğitim':
        return Icons.school_rounded;
      case 'müzik':
        return Icons.music_note_rounded;
      default:
        return Icons.category_rounded;
    }
  }
}
