import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'package:flutter/foundation.dart';

/// Global Serverpod client — call [initServerpodClient] once in main().
late Client client;

void initServerpodClient() {
  String host;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    host = 'http://192.168.1.181:8080/';  // Android emulator → IP thật của server
  } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    host = 'http://192.168.1.181:8080/';  // iOS device → cũng dùng IP thật (không dùng localhost)
  } else {
    host = 'http://localhost:8080/';      // Web / Windows / Desktop
  }
  client = Client(host)
    ..connectivityMonitor = FlutterConnectivityMonitor();
}
