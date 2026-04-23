import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

// ── Cấu hình server ────────────────────────────────────────────
const String _lanHost = 'http://172.16.3.27:8080/';
const String _cloudHost = 'https://api-hotrocntt.bvkhanhhoa.cloud/';

/// Global Serverpod client — call [initServerpodClient] once in main().
late Client client;

/// Tự động chọn server phù hợp:
///  - Luôn dùng Cloudflare (hoạt động từ mọi nơi: nhà, viện, 4G...)
///  - Ngoại lệ: nếu web truy cập trực tiếp IP nội bộ → dùng LAN
///  - KHÔNG cần đổi code khi di chuyển giữa nhà và bệnh viện!
void initServerpodClient() {
  String host;

  if (kIsWeb && Uri.base.host == '172.16.3.27') {
    // Web truy cập trực tiếp IP nội bộ → dùng LAN (nhanh hơn)
    host = _lanHost;
  } else {
    // Mọi trường hợp khác → Cloudflare (ổn định, hoạt động mọi nơi)
    host = _cloudHost;
  }

  debugPrint('[SP_Client] Connecting to: $host');
  client = Client(host)
    ..connectivityMonitor = FlutterConnectivityMonitor();
}
