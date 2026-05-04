import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'package:go_router/go_router.dart';
import 'services/sp_client.dart';
import 'services/windows_notification_service.dart';
import 'theme/app_theme.dart';

/// Chỉ true khi chạy trên desktop (Windows/macOS/Linux)
bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// Gọi khi ở màn hình Login/Splash → giữ nguyên maximize (không thu nhỏ)
Future<void> setLoginWindowSize() async {
  if (!_isDesktop) return;
  await windowManager.setMaximumSize(const Size(9999, 9999));
  await windowManager.setMinimumSize(const Size(800, 600));
  await windowManager.setResizable(true);
  await windowManager.maximize();
}

/// Gọi sau khi đăng nhập thành công → full màn hình / maximize
Future<void> setFullWindowSize() async {
  if (!_isDesktop) return;
  await windowManager.setMaximumSize(const Size(9999, 9999)); // bỏ giới hạn max
  await windowManager.setMinimumSize(const Size(800, 600));
  await windowManager.setResizable(true);
  await windowManager.maximize();
}

void main() async {
  // Bắt lỗi Flutter framework không bị crash im lặng
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('🔴 FlutterError: ${details.exception}');
    debugPrint('🔴 Stack: ${details.stack}');
  };

  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Bỏ dấu /#/ trong URL trên web → URL sạch: /admin thay vì /#/admin
      usePathUrlStrategy();
      // Buộc URL trình duyệt cập nhật khi dùng context.push() (không chỉ context.go())
      GoRouter.optionURLReflectsImperativeAPIs = true;
      initServerpodClient();
      // Khởi tạo Windows toast notification (chỉ chạy trên Windows)
      if (!kIsWeb && Platform.isWindows) {
        await WindowsNotificationService.init();
      }

      // Khởi tạo window_manager (chỉ desktop)
      if (_isDesktop) {
        await windowManager.ensureInitialized();
        const options = WindowOptions(
          minimumSize: Size(900, 600),
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.normal,
          title: 'MedHub',
        );
        await windowManager.waitUntilReadyToShow(options, () async {
          await windowManager.maximize();
          await windowManager.setResizable(true);
          await windowManager.show();
          await windowManager.focus();
        });
      }

      // Initialise Firebase (required for FCM push notifications)
      // Web chưa có cấu hình Firebase nên ta skip để tránh FirebaseOptions ném lỗi
      if (!kIsWeb) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          debugPrint('✅ Firebase initialized');
        } catch (e) {
          debugPrint('⚠️ Firebase init error (non-fatal): $e');
          // Không crash app nếu Firebase lỗi, chỉ bỏ qua push notification
        }
      }
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );
      runApp(const MedHubApp());
    },
    (error, stackTrace) {
      debugPrint('🔴 Unhandled error: $error');
      debugPrint('🔴 Stack: $stackTrace');
    },
  );
}

class MedHubApp extends StatelessWidget {
  const MedHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'MedHub',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      // textScaler bị xóa để tỉ lệ nhất quán giữa login và dashboard
      builder: null,
      theme: AppTheme.light(),
    );
  }
}
