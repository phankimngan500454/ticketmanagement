import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

/// Hiển thị Windows toast notification kiểu Zalo
/// — popup góc dưới phải, hoạt động kể cả khi app thu nhỏ.
class WindowsNotificationService {
  static bool _initialized = false;

  /// Khởi tạo — gọi 1 lần trong main() trước runApp()
  static Future<void> init() async {
    if (!_isWindows) return;
    if (_initialized) return;
    await localNotifier.setup(appName: 'IT Helpdesk');
    _initialized = true;
  }

  /// Hiện toast notification với title + body.
  /// [onTap]: callback khi user click vào notification.
  static Future<void> show({
    required String title,
    required String body,
    VoidCallback? onTap,
  }) async {
    if (!_isWindows) return;
    if (!_initialized) await init();

    final notification = LocalNotification(
      title: title,
      body: body,
    );

    notification.onShow = () {
      // notification đã hiển thị
    };

    notification.onClick = () {
      onTap?.call();
    };

    await notification.show();
  }

  /// Tiện ích: hiện thông báo ticket mới
  static Future<void> showNewTicket({
    required int ticketId,
    required String subject,
    required String requester,
    VoidCallback? onTap,
  }) async {
    await show(
      title: '🎫 Ticket mới #${ticketId.toString().padLeft(4, '0')}',
      body: '$subject\nGửi bởi: $requester',
      onTap: onTap,
    );
  }

  /// Tiện ích: hiện thông báo cập nhật ticket
  static Future<void> showTicketUpdate({
    required int ticketId,
    required String message,
    VoidCallback? onTap,
  }) async {
    await show(
      title: 'IT Helpdesk — Cập nhật ticket #${ticketId.toString().padLeft(4, '0')}',
      body: message,
      onTap: onTap,
    );
  }

  static bool get _isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
}
