import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

const String _serverHost = 'http://172.16.3.27:8080/';

/// Địa chỉ IP máy chủ Serverpod — đổi về localhost để test local
// const String _serverHost = 'http://localhost:8080/';

/// Global Serverpod client — call [initServerpodClient] once in main().
late Client client;

void initServerpodClient() {
  // Tất cả platform (Windows, Android, iOS) đều kết nối về TICKET-IT (172.16.3.27)
  // Chỉ cần đổi _serverHost ở trên nếu IP server thay đổi
  client = Client(_serverHost)
    ..connectivityMonitor = FlutterConnectivityMonitor();
}
