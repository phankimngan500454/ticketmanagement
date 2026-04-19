import 'browser_notification_service_stub.dart'
    if (dart.library.html) 'browser_notification_service_web.dart' as impl;

class BrowserNotificationService {
  static Future<void> init() => impl.init();

  static Future<void> show({
    required String title,
    required String body,
    String? route,
    String? tag,
  }) {
    return impl.show(title: title, body: body, route: route, tag: tag);
  }
}
