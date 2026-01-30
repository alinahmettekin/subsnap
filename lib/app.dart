import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subsnap/core/providers.dart';
import 'package:subsnap/core/theme/app_theme.dart';
import 'package:subsnap/core/widgets/loading_screen.dart';
import 'package:subsnap/router.dart';
import 'package:subsnap/features/onboarding/presentation/onboarding_screen.dart';
import 'package:overlay_support/overlay_support.dart';

class SublyApp extends ConsumerWidget {
  const SublyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final router = ref.watch(routerProvider);
      final themeMode = ref.watch(themeModeProvider);
      final onboardingCompleted = ref.watch(onboardingCompletedProvider);
      
      // Loading state kontrolü
      final authState = ref.watch(authUserProvider);
      final isLoadingAuth = authState.isLoading;
      
      final profileAsync = ref.watch(userProfileProvider);
      final isLoadingProfile = profileAsync.isLoading;
      
      final isLoading = isLoadingAuth || isLoadingProfile;

      // Onboarding tamamlanmamışsa onboarding screen'i göster
      return onboardingCompleted.when(
        data: (completed) {
          if (!completed) {
            return MaterialApp(
              title: 'Subly',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('tr')],
              home: const OnboardingScreen(),
            );
          }

          return OverlaySupport.global(
            child: MaterialApp.router(
              title: 'Subly',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('en'), Locale('tr')],
              routerConfig: router,
              builder: (context, child) {
                return Stack(
                  children: [
                    if (child != null) child,
                    // Loading overlay - state-based
                    if (isLoading)
                      const Material(
                        color: Colors.black54,
                        child: LoadingScreen(),
                      ),
                  ],
                );
              },
            ),
          );
        },
        loading: () => MaterialApp(
          title: 'Subly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('tr')],
          home: const Scaffold(
            body: Center(child: LoadingScreen()),
          ),
        ),
        error: (_, __) => MaterialApp(
          title: 'Subly',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en'), Locale('tr')],
          home: const OnboardingScreen(), // Hata durumunda onboarding göster
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('Error in SublyApp build: $e');
      debugPrint('Stack trace: $stackTrace');
      return MaterialApp(
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('tr')],
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
