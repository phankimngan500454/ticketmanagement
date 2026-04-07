import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'package:go_router/go_router.dart';
import 'services/sp_client.dart';
import 'services/windows_notification_service.dart';

/// Chỉ true khi chạy trên desktop (Windows/macOS/Linux)
bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

/// Gọi khi đang ở màn hình Login/Splash → cửa sổ nhỏ gọn (landscape, 2 cột)
Future<void> setLoginWindowSize() async {
  if (!_isDesktop) return;
  await windowManager.setSize(const Size(820, 560));
  await windowManager.setMinimumSize(const Size(700, 480));
  await windowManager.setMaximumSize(const Size(1000, 700));
  await windowManager.center();
  await windowManager.setResizable(false);
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
          size: Size(820, 560),
          minimumSize: Size(700, 480),
          maximumSize: Size(1000, 700),
          center: true,
          backgroundColor: Colors.transparent,
          skipTaskbar: false,
          titleBarStyle: TitleBarStyle.normal,
          title: 'IT Helpdesk',
        );
        await windowManager.waitUntilReadyToShow(options, () async {
          await windowManager.setResizable(false);
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
      runApp(const HelpdeskApp());
    },
    (error, stackTrace) {
      debugPrint('🔴 Unhandled error: $error');
      debugPrint('🔴 Stack: $stackTrace');
    },
  );
}

class HelpdeskApp extends StatelessWidget {
  const HelpdeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'IT Helpdesk',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      // Tăng cỡ chữ 1.2× trên Windows để dễ đọc hơn khi dùng desktop
      builder: _isDesktop
          ? (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.2)),
              child: child!,
            )
          : null,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: const Color(0xFF3949AB),
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF0F2F8),
        fontFamily: 'Roboto',
        // Card theme
        cardTheme: CardThemeData(
          elevation: 1,
          shadowColor: Colors.black.withValues(alpha: 0.08),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          color: Colors.white,
        ),
        // AppBar theme
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // ElevatedButton theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3949AB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        // OutlinedButton theme
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF3949AB),
            side: const BorderSide(color: Color(0xFF3949AB)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF4F5F9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3949AB), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        ),
        // SnackBar theme
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentTextStyle: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        // Divider
        dividerTheme: DividerThemeData(
          color: Colors.grey.shade200,
          thickness: 1,
        ),
        // Chip theme
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        ),
        // PopupMenu theme
        popupMenuTheme: PopupMenuThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: Colors.black.withValues(alpha: 0.12),
        ),
        // Bottom sheet theme
        bottomSheetTheme: const BottomSheetThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
