import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Logs errors and warnings to Supabase [error_log] for debugging during
/// internal test / development. Use context like 'iap_purchase', 'analytics_gate'.
/// Never throws; failures are only debug-printed.
class ErrorLogService {
  static const String _table = 'error_log';

  /// Log a message to Supabase error_log. Safe to call from anywhere.
  /// [level]: 'error' | 'warning' | 'info'
  /// [context]: e.g. 'iap_initialize', 'iap_purchase', 'iap_verify', 'analytics_gate'
  static Future<void> log({
    required String level,
    required String context,
    required String message,
    String? stackTrace,
    String? userId,
    String? platform,
    String? appVersion,
  }) async {
    try {
      final client = Supabase.instance.client;
      await client.from(_table).insert({
        'level': level,
        'context': context,
        'message': message,
        if (stackTrace != null && stackTrace.isNotEmpty) 'stack_trace': stackTrace,
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
        if (appVersion != null && appVersion.isNotEmpty) 'app_version': appVersion,
      });
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('⚠️ [ErrorLogService] Failed to write to error_log: $e');
        debugPrint('$st');
      }
    }
  }

  static Future<void> logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
    String? userId,
    String? platform,
  ]) {
    return log(
      level: 'error',
      context: context,
      message: error.toString(),
      stackTrace: stackTrace?.toString(),
      userId: userId,
      platform: platform,
    );
  }

  static Future<void> logWarning(String context, String message, {String? userId, String? platform}) {
    return log(level: 'warning', context: context, message: message, userId: userId, platform: platform);
  }

  static Future<void> logInfo(String context, String message, {String? userId, String? platform}) {
    return log(level: 'info', context: context, message: message, userId: userId, platform: platform);
  }
}
