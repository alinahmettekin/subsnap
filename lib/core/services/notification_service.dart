import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter/foundation.dart';
import 'package:subsnap/features/subscriptions/domain/entities/subscription.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();

    // Cihazın yerel saat dilimini otomatik olarak algıla
    try {
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();
      // 'identifier' özelliği IANA formatındaki saat dilimini (ör: Europe/Istanbul) verir
      final String timeZoneName = currentTimeZone.identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('🌍 [NOTIFICATION_SERVICE] Timezone detected: $timeZoneName');
    } catch (e) {
      debugPrint('⚠️ [NOTIFICATION_SERVICE] Could not detect timezone, falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }

    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap if needed
      },
    );

    // Request permissions for Android 13+
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin =
          _notificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    debugPrint('🔔 [NOTIFICATION_SERVICE] Initialized');

    // Reset retention notification every time app starts
    await scheduleRetentionNotification();
  }

  Future<void> scheduleRetentionNotification() async {
    const int retentionId = 888;
    await _notificationsPlugin.cancel(retentionId);

    // Check if retention notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('retention_notifications_enabled') ?? true;
    if (!isEnabled) return;

    final scheduledDate = tz.TZDateTime.now(tz.local).add(const Duration(days: 3));

    await _notificationsPlugin.zonedSchedule(
      retentionId,
      'Seni Özledik! 💙',
      'Aboneliklerini ekle, harcamalarını kontrol altına al!',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'retention_notifications',
          'Uygulama Hatırlatıcıları',
          channelDescription: 'Uygulamayı uzun süre açmadığınızda gelen hatırlatıcılar',
          importance: Importance.low,
          priority: Priority.low,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('📅 [NOTIFICATION_SERVICE] Retention notification rescheduled for: $scheduledDate');
  }

  Future<void> scheduleSubscriptionReminder(Subscription sub) async {
    // Cancel existing notifications for this sub first
    await cancelNotification(sub.id);

    // 1 Gün Önce
    if (sub.notify1DayBefore) {
      await _scheduleReminder(
        sub,
        daysBefore: 1,
        notificationId: sub.id.hashCode,
      );
    }

    // 3 Gün Önce
    if (sub.notify3DaysBefore) {
      await _scheduleReminder(
        sub,
        daysBefore: 3,
        notificationId: sub.id.hashCode + 1000000, // Offset to avoid collision
      );
    }
  }

  Future<void> _scheduleReminder(Subscription sub, {required int daysBefore, required int notificationId}) async {
    // Check if app notifications are enabled
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('app_notifications_enabled') ?? true;
    if (!isEnabled) return;

    final scheduledDate = sub.nextPaymentDate.subtract(Duration(days: daysBefore));
    final scheduledDateTime = DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, 10, 0, 0);

    if (scheduledDateTime.isBefore(DateTime.now())) return;

    final scheduledTZDate = tz.TZDateTime.from(scheduledDateTime, tz.local);

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Abonelik Hatırlatıcı',
      '${sub.name} ödemesi ${daysBefore == 1 ? "yarın" : "3 gün sonra"} yaklaşıyor!',
      scheduledTZDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'subscription_reminders',
          'Abonelik Hatırlatıcıları',
          channelDescription: 'Abonelik ödeme hatırlatıcıları için bildirim kanalı',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('✅ [NOTIFICATION_SERVICE] Scheduled $daysBefore-day reminder for "${sub.name}" at $scheduledTZDate');
  }

  Future<void> showInstantNotification({required String title, required String body}) async {
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: AndroidNotificationDetails(
        'test_notifications',
        'Test Bildirimleri',
        channelDescription: 'Anlık test bildirimleri için',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> showTestNotification() async {
    await showInstantNotification(
      title: 'SubSnap Test 🔔',
      body: 'Bildirim sisteminiz başarıyla çalışıyor! (Anlık)',
    );
  }

  Future<void> scheduleOneMinuteTest() async {
    final now = DateTime.now();
    final testTime = now.add(const Duration(minutes: 1));
    final scheduledTZDate = tz.TZDateTime.from(testTime, tz.local);

    debugPrint('🧪 [NOTIFICATION_SERVICE] 1 dakikalık test kuruluyor: $scheduledTZDate');

    await _notificationsPlugin.zonedSchedule(
      999,
      'Test Bildirimi (1 Dakika)',
      'Bu bildirim 1 dakika sonra gelmeliydi.',
      scheduledTZDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'test_reminders',
          'Test Hatırlatıcıları',
          channelDescription: 'Hızlı testler için kanal',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint('✅ [NOTIFICATION_SERVICE] 1 dakikalık test planlandı.');
  }

  Future<void> cancelRetentionNotification() async {
    await _notificationsPlugin.cancel(888);
    debugPrint('🚫 [NOTIFICATION_SERVICE] Retention notification canceled');
  }

  Future<void> cancelNotification(String subId) async {
    await _notificationsPlugin.cancel(subId.hashCode);
    await _notificationsPlugin.cancel(subId.hashCode + 1000000);
    debugPrint('🚫 [NOTIFICATION_SERVICE] Notifications canceled for ID: $subId');
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
