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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Date Formatting
  await initializeDateFormatting('tr_TR', null);
  Intl.defaultLocale = 'tr_TR';

  // Initialize Supabase
  await Supabase.initialize(url: AppConstants.supabaseUrl, anonKey: AppConstants.supabaseAnonKey);

  // Initialize RevenueCat
  await SubscriptionService.init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SubSnap',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,

      home: const AuthWrapper(),
    );
  }
}
