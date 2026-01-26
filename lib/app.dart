import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/core/theme/app_theme.dart';
import 'package:subsnap/router.dart';
import 'package:overlay_support/overlay_support.dart';

class SublyApp extends ConsumerWidget {
  const SublyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final router = ref.watch(routerProvider);
      final themeMode = ref.watch(themeModeProvider);

      return OverlaySupport.global(
        child: MaterialApp.router(
          title: 'Subly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: router,
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error in SublyApp build: $e');
      debugPrint('Stack trace: $stackTrace');
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('App Error: $e'),
              ],
            ),
          ),
        ),
      );
    }
  }
}
