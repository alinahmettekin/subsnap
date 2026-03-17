import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:subsnap/core/theme/app_theme.dart';
import 'package:subsnap/core/utils/constants.dart';
import 'package:subsnap/core/services/subscription_service.dart';
import 'package:subsnap/features/auth/views/auth_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:subsnap/core/theme/theme_provider.dart';
import 'package:flutter/services.dart';

void main() async {
  // ... (same init logic)
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  try {
    await Future.wait([
      initializeDateFormatting('tr_TR', null),
      Supabase.initialize(
        url: AppConstants.supabaseUrl,
        anonKey: AppConstants.supabaseAnonKey,
      ),
      SubscriptionService.init(),
    ]);
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
  }

  Intl.defaultLocale = 'tr_TR';
  FlutterNativeSplash.remove();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeSettingsProvider);

    return MaterialApp(
      title: 'SubSnap',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR')],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const AuthWrapper(),
    );
  }
}
