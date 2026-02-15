import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/features/subscriptions/models/subscription.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HeaderOverview extends ConsumerWidget {
  final List<Subscription> subscriptions;
  final double growthPercentage; // Pre-calculated or passed

  const HeaderOverview({super.key, required this.subscriptions, this.growthPercentage = 18.0});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    final user = Supabase.instance.client.auth.currentUser;
    final name = user?.userMetadata?['full_name']?.toString().split(' ').first ?? 'Kullanıcı';

    double totalMonthly = 0;
    for (var sub in subscriptions) {
      if (sub.billingCycle == 'monthly') {
        totalMonthly += sub.price;
      } else {
        totalMonthly += sub.price / 12;
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.9 : 0.95),
            theme.colorScheme.surface,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hoş geldin $name', style: TextStyle(color: onSurfaceVariant, fontSize: 16)),
            const SizedBox(height: 24),
            Text('Toplam Abonelik Harcaman', style: TextStyle(color: onSurfaceVariant, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₺${totalMonthly.toStringAsFixed(0)}',
                  style: TextStyle(color: onSurface, fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1),
                ),
                Text(' / Ay', style: TextStyle(color: onSurfaceVariant, fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
