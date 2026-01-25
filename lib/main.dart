import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:subsnap/app.dart';
import 'package:subsnap/core/constants/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Turkish locale data for date formatting
  await initializeDateFormatting('tr_TR', null);

  // Add error handling for Flutter framework errors FIRST
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack: ${details.stack}');
    debugPrint('Library: ${details.library}');
    debugPrint('Context: ${details.context}');
  };

  // Set custom error widget builder
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('ErrorWidget: ${details.exception}');
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('An error occurred', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                details.exception.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  };

  // Initialize Supabase with timeout
  // Note: This will fail if config is not set, but expected for MVP setup
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint('Supabase init timeout - continuing anyway');
        throw TimeoutException('Supabase initialization timeout');
      },
    );
    debugPrint('Supabase initialized successfully');
  } catch (e, stackTrace) {
    debugPrint('Warning: Supabase init failed: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - app might work without Supabase in some cases
  }

  runApp(
    const ProviderScope(
      child: SublyApp(),
    ),
  );
}
