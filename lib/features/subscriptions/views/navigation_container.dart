import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dashboard_view.dart';
import 'add_subscription_view.dart';
import '../../payments/views/payments_view.dart';
import '../../analytics/views/analytics_view.dart';
import '../../auth/views/settings_view.dart';

class NavigationContainer extends ConsumerStatefulWidget {
  const NavigationContainer({super.key});

  @override
  ConsumerState<NavigationContainer> createState() => _NavigationContainerState();
}

class _NavigationContainerState extends ConsumerState<NavigationContainer> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardView(),
    const PaymentsView(),
    const AnalyticsView(),
    const SettingsView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: _screens[_currentIndex],
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _SoftBottomBar(
            currentIndex: _currentIndex,
            onSelect: (index) => setState(() => _currentIndex = index),
            onAddSubscription: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddSubscriptionView(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SoftBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onAddSubscription;

  const _SoftBottomBar({required this.currentIndex, required this.onSelect, required this.onAddSubscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = theme.colorScheme.surface;
    final tintColor = theme.colorScheme.surfaceContainerHighest;
    final borderColor = theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5);
    final shadowColor = theme.colorScheme.shadow.withValues(alpha: isDark ? 0.35 : 0.18);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withValues(alpha: isDark ? 0.72 : 0.9),
                tintColor.withValues(alpha: isDark ? 0.6 : 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor),
            boxShadow: [BoxShadow(color: shadowColor, blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: SizedBox(
            height: 72,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavBarItem(icon: Icons.grid_view_rounded, isSelected: currentIndex == 0, onTap: () => onSelect(0)),
                  _NavBarItem(icon: Icons.payments_rounded, isSelected: currentIndex == 1, onTap: () => onSelect(1)),
                  _NavBarItem(
                    icon: Icons.add_circle_rounded,
                    isSelected: false,
                    onTap: onAddSubscription,
                    isAddButton: true,
                  ),
                  _NavBarItem(icon: Icons.bar_chart_rounded, isSelected: currentIndex == 2, onTap: () => onSelect(2)),
                  _NavBarItem(icon: Icons.person_rounded, isSelected: currentIndex == 3, onTap: () => onSelect(3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isAddButton;

  const _NavBarItem({required this.icon, required this.isSelected, required this.onTap, this.isAddButton = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = theme.colorScheme.onSurface.withValues(alpha: isDark ? 0.5 : 0.55);

    // Special styling for add button
    if (isAddButton) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Icon(icon, color: selectedColor, size: 32),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withValues(alpha: isDark ? 0.16 : 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(icon, color: isSelected ? selectedColor : unselectedColor, size: 28),
      ),
    );
  }
}
