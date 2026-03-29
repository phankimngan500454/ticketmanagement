import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';
import 'package:flutter/foundation.dart';

// ============================================================
// Serverpod Client Singleton
// Flutter Web/Desktop → localhost:8080
// Android Emulator    → 10.0.2.2:8080
// Android thiết bị thật → IP LAN máy tính: 192.168.1.181:8080
// ============================================================
late Client client;

void initClient() {
  String host;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    host = 'http://192.168.1.181:8080/';
  } else {
    host = 'http://localhost:8080/';
  }
  client = Client(host);
}
