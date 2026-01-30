import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:subsnap/app.dart';
import 'package:subsnap/core/constants/revenuecat_config.dart';
import 'package:subsnap/core/constants/supabase_config.dart';
import 'package:subsnap/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Turkish locale data for date formatting
  await initializeDateFormatting('tr_TR', null);

  // Initialize RevenueCat
  try {
    debugPrint('💰 [MAIN] Initializing RevenueCat...');
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(
      PurchasesConfiguration(RevenueCatConfig.apiKey),
    );
    debugPrint('✅ [MAIN] RevenueCat initialized');
  } catch (e) {
    debugPrint('❌ [MAIN] RevenueCat initialization failed: $e');
  }

  // Add error handling for Flutter framework errors FIRST
  FlutterError.onError = (FlutterErrorDetails details) {
    // SVG parse hatalarını sessizce yakala (kullanıcı deneyimini bozmamak için)
    if (details.exception.toString().contains('XmlParserException') ||
        details.exception.toString().contains('SvgParser')) {
      debugPrint('⚠️ [MAIN] SVG parse hatası yakalandı (sessizce): ${details.exception}');
      return; // Hata gösterilmez, uygulama çalışmaya devam eder
    }
    
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
  };

  debugPrint('🚀 [MAIN] Starting app initialization...');

  // Initialize Supabase correctly
  try {
    debugPrint('📡 [MAIN] Initializing Supabase...');
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    debugPrint('✅ [MAIN] Supabase initialized');
  } catch (e) {
    debugPrint('❌ [MAIN] Supabase initialization failed: $e');
  }

  // Initialize Local Notifications
  try {
    debugPrint('🔔 [MAIN] Initializing NotificationService...');
    await NotificationService().init();
    debugPrint('✅ [MAIN] NotificationService initialized');
  } catch (e) {
    debugPrint('❌ [MAIN] NotificationService initialization failed: $e');
  }

  debugPrint('🏁 [MAIN] Initialization complete. Running app...');
  runApp(
    const ProviderScope(
      child: SublyApp(),
    ),
  );
}
