// File này được tạo thủ công từ google-services.json và GoogleService-Info.plist
// Tương đương với file được tạo bởi: flutterfire configure
// Project: ticketmanagement-e5e41

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web chưa cấu hình Firebase.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions chưa cấu hình cho platform: $defaultTargetPlatform',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-hPhGz-J6quIfzkE2oO7PAsrleBqKC_8',
    appId: '1:770329419082:android:3c62268656a83f2c0bb5b3',
    messagingSenderId: '770329419082',
    projectId: 'ticketmanagement-e5e41',
    storageBucket: 'ticketmanagement-e5e41.firebasestorage.app',
  );

  // iOS — lấy từ GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBhJiwQ449j46wrLF05hGdzEaiuclXaiqo',
    appId: '1:770329419082:ios:d4c63adb36430cbf0bb5b3',
    messagingSenderId: '770329419082',
    projectId: 'ticketmanagement-e5e41',
    storageBucket: 'ticketmanagement-e5e41.firebasestorage.app',
    iosBundleId: 'com.bvdkkh.ticketmanagement',
  );

  // Windows dùng cùng Firebase project, FCM push không khả dụng trên Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD-hPhGz-J6quIfzkE2oO7PAsrleBqKC_8',
    appId: '1:770329419082:android:3c62268656a83f2c0bb5b3',
    messagingSenderId: '770329419082',
    projectId: 'ticketmanagement-e5e41',
    storageBucket: 'ticketmanagement-e5e41.firebasestorage.app',
  );
}
