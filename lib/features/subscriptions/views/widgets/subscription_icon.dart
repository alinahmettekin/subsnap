import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../models/subscription.dart';
import '../../models/service.dart';
import '../../providers/subscription_provider.dart';
import '../../../../core/utils/icon_helper.dart';

class SubscriptionIcon extends ConsumerWidget {
  final Subscription subscription;
  final double size;

  const SubscriptionIcon({super.key, required this.subscription, this.size = 52});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);
    final theme = Theme.of(context);

    return servicesAsync.when(
      data: (services) {
        Service? matchedService;

        // Try strict match by ID
        if (subscription.serviceId != null) {
          try {
            matchedService = services.firstWhere((s) => s.id == subscription.serviceId);
          } catch (_) {}
        }

        // Fallback to name match
        if (matchedService == null) {
          try {
            matchedService = services.firstWhere((s) => s.name.toLowerCase() == subscription.name.toLowerCase());
          } catch (_) {}
        }

        if (matchedService != null) {
          final color = IconHelper.getColor(matchedService.color);
          final icon = IconHelper.getIcon(matchedService.iconName);

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16)),
            child: Center(
              child: FaIcon(icon, color: color, size: size * 0.45),
            ),
          );
        }

        // Fallback to initials
        return _buildInitials(theme);
      },
      loading: () => _buildInitials(theme),
      error: (_, _) => _buildInitials(theme),
    );
  }

  Widget _buildInitials(ThemeData theme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0150),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          subscription.name.isNotEmpty ? subscription.name[0].toUpperCase() : '?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: size * 0.45, color: theme.colorScheme.primary),
        ),
      ),
    );
  }
}
