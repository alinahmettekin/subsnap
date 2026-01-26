import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subsnap/features/subscriptions/presentation/subscriptions_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _getCurrentIndex(String location) {
    if (location.contains('payments')) return 1;
    if (location.contains('analytics')) return 2;
    if (location.contains('settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        context.go('/home/dashboard');
        break;
      case 1:
        context.go('/home/payments');
        break;
      case 2:
        context.go('/home/analytics');
        break;
      case 3:
        context.go('/home/settings');
        break;
    }
  }

  Future<void> _navigateToAdd() async {
    final result = await context.push('/home/dashboard/add');
    // Eğer başarıyla döndüyse refresh yap
    if (result == true && mounted) {
      ref.refresh(subscriptionsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _getCurrentIndex(location);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: widget.child,
      floatingActionButton: currentIndex == 0
          ? FloatingActionButton(
              onPressed: _navigateToAdd,
              backgroundColor: isDark ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).primaryColor,
              foregroundColor: isDark ? Theme.of(context).colorScheme.onPrimaryContainer : Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          NavigationDestination(
            icon: Icon(Icons.payment_outlined),
            selectedIcon: Icon(Icons.payment),
            label: 'Ödemeler',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}
