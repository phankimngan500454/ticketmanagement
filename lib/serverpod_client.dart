import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';

// ============================================================
// Serverpod Client Singleton
// Đổi host thành IP thực khi chạy trên thiết bị thật (LAN)
// Flutter Web/Desktop → localhost:8080
// Android Emulator    → 10.0.2.2:8080
// ============================================================
late Client client;

void initClient() {
  client = Client('http://localhost:8080/');
}
