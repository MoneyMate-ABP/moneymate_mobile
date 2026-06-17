import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../network/api_client.dart';
import '../storage/key_value_storage.dart';
import '../storage/secure_key_value_storage.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final KeyValueStorage _storage = SecureKeyValueStorage();

  static const String _enabledKey = 'daily_notifications_enabled';

  Future<void> initialize() async {
    // 0. Initialize Firebase core messaging if native configurations exist
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('FCM Warning: Firebase could not initialize. Native configs might be missing: $e');
    }

    // 1. Initialize timezone database
    tz.initializeTimeZones();
    try {
      // Set timezone matching project timezone (Asia/Jakarta)
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Fallback if location not found, default to UTC
    }

    // 2. Initialize Flutter Local Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click if needed
      },
    );

    // 3. Re-schedule daily reminder if it was previously enabled
    final isEnabled = await areNotificationsEnabled();
    if (isEnabled) {
      await scheduleDailyReminder();
    }
  }

  Future<bool> areNotificationsEnabled() async {
    final val = await _storage.read(_enabledKey);
    // Default to true if not set yet, so user gets notification by default
    return val != 'false';
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await _storage.write(key: _enabledKey, value: enabled ? 'true' : 'false');
    if (enabled) {
      await scheduleDailyReminder();
    } else {
      await cancelDailyReminder();
    }
  }

  Future<void> scheduleDailyReminder({
    String title = 'Pengingat Anggaran Harian',
    String body = 'Ayo catat transaksi hari ini dan cek sisa anggaran harianmu di MoneyMate! 💰',
  }) async {
    const int notificationId = 800; // Unique ID for daily reminder

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_budget_channel',
      'Daily Budget Reminders',
      channelDescription: 'Channel for daily budget push notifications at 8 AM',
      importance: Importance.max,
      priority: Priority.high,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime scheduledDate = _nextInstanceOfEightAM();

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminder() async {
    await _notificationsPlugin.cancel(800);
  }

  tz.TZDateTime _nextInstanceOfEightAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> syncFcmToken(ApiClient apiClient) async {
    final isEnabled = await areNotificationsEnabled();
    if (!isEnabled) return;

    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('FCM Warning: Skipped sync because Firebase is not initialized.');
        return;
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final String? fcmToken = await messaging.getToken();
        if (fcmToken != null) {
          await apiClient.post(
            '/api/notifications/subscribe-fcm',
            body: {'token': fcmToken},
          );
          debugPrint('FCM Token synced to backend successfully.');
        }
      }
    } catch (e) {
      debugPrint('FCM Warning: Failed to sync FCM token to server: $e');
    }
  }

  Future<void> clearFcmToken(ApiClient apiClient) async {
    try {
      if (Firebase.apps.isEmpty) return;

      final String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await apiClient.post(
          '/api/notifications/unsubscribe-fcm',
          body: {'token': fcmToken},
        );
        debugPrint('FCM Token cleared from backend successfully.');
      }
    } catch (e) {
      debugPrint('FCM Warning: Failed to clear FCM token from server: $e');
    }
  }
}
