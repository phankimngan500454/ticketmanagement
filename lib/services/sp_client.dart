import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

// ── Cấu hình server ────────────────────────────────────────────
// ĐỔI DÒNG NÀY ĐỂ CHUYỂN SERVER:
//   true  = kết nối localhost (dev local)
//   false = kết nối Cloud/LAN (production)
const bool _useLocal = true;

const String _localHost = 'http://127.0.0.1:8080/';
const String _lanHost = 'http://172.16.3.27:8080/';
const String _cloudHost = 'https://api-hotrocntt.bvkhanhhoa.cloud/';

/// Global Serverpod client — call [initServerpodClient] once in main().
late Client client;

/// Tự động chọn server phù hợp:
///  - _useLocal = true  → luôn dùng localhost
///  - _useLocal = false → Cloud (mặc định), hoặc LAN nếu web truy cập IP nội bộ
void initServerpodClient() {
  String host;

  if (_useLocal) {
    // Dev local → localhost
    host = _localHost;
  } else if (kIsWeb && Uri.base.host == '172.16.3.27') {
    // Web truy cập trực tiếp IP nội bộ → dùng LAN (nhanh hơn)
    host = _lanHost;
  } else {
    // Mọi trường hợp khác → Cloudflare (ổn định, hoạt động mọi nơi)
    host = _cloudHost;
  }

  debugPrint('[SP_Client] Connecting to: $host');
  client = Client(host)..connectivityMonitor = FlutterConnectivityMonitor();
}
