import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

/// Lấy tự động: nếu người dùng truy cập từ web Cloudflare thì nối vào API từ Cloudflare
/// Nếu truy cập mạng nội bộ thì dùng IP LAN của máy chủ.
// String get _serverHost {
//   if (kIsWeb) {
//     if (Uri.base.host.contains('bvkhanhhoa.cloud')) {
//       // Nhớ config Cloudflare Tunnel cho subdomain này trỏ về 172.16.3.27:8080!
//       return 'https://api-hotrocntt.bvkhanhhoa.cloud/';
//     }
//   }
//   return 'http://172.16.3.27:8080/';
// }
// const String _serverHost = 'https://api-hotrocntt.bvkhanhhoa.cloud/';

// /// Địa chỉ IP máy chủ Serverpod — đổi về localhost để test local
const String _serverHost = 'http://localhost:8080/';

/// Global Serverpod client — call [initServerpodClient] once in main().
late Client client;

void initServerpodClient() {
  // Tất cả platform (Windows, Android, iOS) đều kết nối về TICKET-IT (172.16.3.27)
  // Chỉ cần đổi _serverHost ở trên nếu IP server thay đổi
  client = Client(_serverHost)
    ..connectivityMonitor = FlutterConnectivityMonitor();
}
