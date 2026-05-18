import 'package:postgres/postgres.dart';

void main() async {
  try {
    final conn = await Connection.open(
      Endpoint(
        host: '127.0.0.1',
        port: 5432,
        database: 'ticketmanagement_server',
        username: 'postgres',
        password: 'postgres',
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

    final results = await conn.execute("SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'ticket_events';");
    for (final row in results) {
      print('INDEX: ' + row[0].toString() + ' -> ' + row[1].toString());
    }

    await conn.close();
  } catch (e) {
    print('Lỗi: ' + e.toString());
  }
}
