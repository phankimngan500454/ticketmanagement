import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';

/// Global Serverpod client — call [initServerpodClient] once in main().
late Client client;

void initServerpodClient() {
  client = Client('http://localhost:8080/')
    ..connectivityMonitor = FlutterConnectivityMonitor();
}
