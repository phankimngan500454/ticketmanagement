// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: deprecated_member_use
import 'dart:html' as html;

Future<void> init() async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission == 'default') {
    await html.Notification.requestPermission();
  }
}

Future<void> show({
  required String title,
  required String body,
  String? route,
  String? tag,
}) async {
  if (!html.Notification.supported) return;
  if (html.Notification.permission != 'granted') return;

  final notification = html.Notification(
    title,
    body: body,
    icon: 'assets/app_icon.png',
    tag: tag,
  );

  notification.onClick.listen((_) {
    if (route != null && route.isNotEmpty) {
      html.window.location.href = route;
    }
    notification.close();
  });

  Timer(const Duration(seconds: 6), notification.close);
}
