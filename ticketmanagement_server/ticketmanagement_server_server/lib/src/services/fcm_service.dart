import 'dart:convert';
import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Sends Firebase Cloud Messaging (FCM) push notifications via HTTP v1 API.
///
/// **Setup required:**
/// Place `firebase_service_account.json` in the server root directory.
/// Download from: Firebase Console → Project Settings → Service accounts → Generate new private key
class FcmService {
  static const _scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

  // Lazy-loaded authenticated HTTP client (token cached & refreshed automatically)
  static AutoRefreshingAuthClient? _authClient;

  static Future<AutoRefreshingAuthClient> _client() async {
    if (_authClient != null) return _authClient!;
    final saFile = File('firebase_service_account.json');
    if (!saFile.existsSync()) {
      throw Exception(
        '[FcmService] firebase_service_account.json not found in server root.\n'
        'Download from Firebase Console → Project Settings → Service accounts.',
      );
    }
    final credentials = ServiceAccountCredentials.fromJson(
      jsonDecode(saFile.readAsStringSync()),
    );
    _authClient = await clientViaServiceAccount(credentials, _scopes);
    return _authClient!;
  }

  // ── Send to a single user ────────────────────────────────────
  /// Sends a push notification to [targetUserId].
  /// Silently skips if the user has no FCM token stored.
  static Future<void> sendToUser(
    Session session, {
    required int targetUserId,
    required String title,
    required String body,
    Map<String, String>? data, // extra key-value payload for deep linking
  }) async {
    try {
      final user = await AppUser.db.findById(session, targetUserId);
      if (user?.fcmToken == null || user!.fcmToken!.isEmpty) return;
      await _send(session, token: user.fcmToken!, title: title, body: body, data: data);
    } catch (e, st) {
      session.log('[FcmService] sendToUser error: $e',
          level: LogLevel.warning, stackTrace: st);
    }
  }

  // ── Send to all users of a role ──────────────────────────────
  /// Sends to every user with the given [roleId]. 1=Admin, 2=IT, 3=Customer.
  static Future<void> sendToRole(
    Session session, {
    required int roleId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      final users = await AppUser.db.find(
        session,
        where: (u) => u.roleId.equals(roleId),
      );
      for (final user in users) {
        if (user.fcmToken != null && user.fcmToken!.isNotEmpty) {
          await _send(session, token: user.fcmToken!, title: title, body: body, data: data);
        }
      }
    } catch (e, st) {
      session.log('[FcmService] sendToRole error: $e',
          level: LogLevel.warning, stackTrace: st);
    }
  }

  // ── Internal FCM HTTP v1 call ────────────────────────────────
  static Future<void> _send(
    Session session, {
    required String token,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    // Read projectId from service account file
    final saFile = File('firebase_service_account.json');
    final sa = jsonDecode(saFile.readAsStringSync());
    final projectId = sa['project_id'] as String;

    final client = await _client();
    final url = Uri.parse(
      'https://fcm.googleapis.com/v1/projects/$projectId/messages:send',
    );

    final payload = {
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body},
        if (data != null) 'data': data,
        'android': {
          'priority': 'HIGH',
          'notification': {'sound': 'default', 'channel_id': 'ticket_alerts'},
        },
      }
    };

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      session.log(
        '[FcmService] FCM error ${response.statusCode}: ${response.body}',
        level: LogLevel.warning,
      );
    }
  }
}
