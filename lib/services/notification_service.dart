import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../data/ticket_repository.dart';

// ── Background message handler (must be top-level) ───────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // FCM auto-shows the notification in system tray when app is killed.
  // Nothing extra needed here unless you want to save to local DB.
}

/// Service that initialises Firebase, handles FCM tokens + notifications.
///
/// **Setup:**
/// 1. Add `google-services.json` to `android/app/`
/// 2. Update `android/build.gradle` and `android/app/build.gradle` (see README)
/// 3. Call `NotificationService.init(userId)` after user logs in
class NotificationService {
  static final _messaging = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  // Global navigator key to navigate from notification tap
  static final navigatorKey = GlobalKey<NavigatorState>();

  // ── Initialise ────────────────────────────────────────────────
  static Future<void> init(int userId) async {
    // Không chạy Push Notifications trên Web và Windows để tránh crash
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // 2. Get & upload FCM token
    final token = await _messaging.getToken();
    if (token != null) {
      await _uploadToken(userId, token);
    }

    // 3. Refresh token automatically
    _messaging.onTokenRefresh.listen((newToken) {
      _uploadToken(userId, newToken);
    });

    // 4. Init local notifications (for foreground popups)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _localNotif.initialize(
      const InitializationSettings(android: androidSettings),
      onDidReceiveNotificationResponse: _onNotifTap,
    );

    // 5. Create notification channel (Android 8+)
    const channel = AndroidNotificationChannel(
      'ticket_alerts',
      'Thông báo Ticket',
      description: 'Thông báo về ticket IT Helpdesk',
      importance: Importance.high,
    );
    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 6. Foreground messages → show local popup
    FirebaseMessaging.onMessage.listen(_showForegroundNotif);

    // 7. Background tap handler (app in background, user taps notif)
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      _handleNotifTap(msg.data);
    });

    // 8. Terminated tap handler (app was killed, user taps notif)
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      _handleNotifTap(initial.data);
    }

    // 9. Background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  // ── Upload FCM token to server ────────────────────────────────
  static Future<void> _uploadToken(int userId, String token) async {
    try {
      await TicketRepository.instance.updateFcmToken(userId, token);
    } catch (_) {/* silently fail if server is down */}
  }

  // ── Show foreground popup ─────────────────────────────────────
  static Future<void> _showForegroundNotif(RemoteMessage message) async {
    final notif = message.notification;
    if (notif == null) return;

    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'ticket_alerts',
          'Thông báo Ticket',
          channelDescription: 'Thông báo về ticket IT Helpdesk',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  // ── Handle notification tap ───────────────────────────────────
  static void _onNotifTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _handleNotifTap(Map<String, String>.from(data));
    } catch (_) {}
  }

  static void _handleNotifTap(Map<String, dynamic> data) {
    final ticketIdStr = data['ticketId'];
    if (ticketIdStr == null) return;
    final ticketId = int.tryParse(ticketIdStr.toString());
    if (ticketId == null) return;

    // Navigate to the ticket — the route handler in main.dart will load it
    navigatorKey.currentState?.pushNamed(
      '/ticket',
      arguments: ticketId,
    );
  }
}
