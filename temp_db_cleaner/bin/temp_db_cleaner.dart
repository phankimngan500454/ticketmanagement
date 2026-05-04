import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to database on 172.16.3.27...');
  try {
    final conn = await Connection.open(
      Endpoint(
        host: '172.16.3.27',
        database: 'ticketmanagement',
        username: 'postgres',
        password: 'Bvdkkh@123',
        port: 5432,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    print('Connected successfully!');
    
    // Truncate tables. Cascade ensures related tables (like comments and attachments) are also cleared.
    print('Deleting all ticket data...');
    await conn.execute('TRUNCATE TABLE ticket CASCADE;');
    
    print('Data cleared successfully. You can now test with a clean database.');
    
    await conn.close();
  } catch (e) {
    print('Error: ' + e.toString());
  }
}
