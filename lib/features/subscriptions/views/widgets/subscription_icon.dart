import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/subscription.dart';
import '../../models/service.dart';
import '../../providers/subscription_provider.dart';

class SubscriptionIcon extends ConsumerWidget {
  final Subscription subscription;
  final double size;

  const SubscriptionIcon({super.key, required this.subscription, this.size = 52});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

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

        // Widget builder helper for consistent container
        Widget buildIconContainer(Widget child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Center(child: child),
          );
        }

        // Helper to build the default/fallback icon
        Widget buildDefaultIcon() {
          return buildIconContainer(
            Image.asset('assets/categories/other.png', width: size * 0.6, height: size * 0.6, fit: BoxFit.contain),
          );
        }

        // If there's no matched service or no iconName, we immediately show the default
        if (matchedService == null || matchedService.iconName == null || matchedService.iconName!.isEmpty) {
          return buildDefaultIcon();
        }

        final String assetPath = 'assets/services/${matchedService.iconName}.png';

        return Image.asset(
          assetPath,
          width: size * 0.6,
          height: size * 0.6,
          fit: BoxFit.contain,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return buildIconContainer(child);
          },
          errorBuilder: (context, error, stackTrace) {
            return buildDefaultIcon();
          },
        );
      },
      loading: () => Container(width: size, height: size, color: Colors.transparent),
      error: (_, _) => Container(
        width: size,
        height: size,
        child: Icon(Icons.error_outline, size: size * 0.5),
      ),
    );
  }
}
