// ignore_for_file: avoid_print
import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(
      host: '127.0.0.1', port: 5432,
      database: 'ticketmanagement_server',
      username: 'postgres', password: 'postgres',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  // Xóa các row trùng lặp, giữ lại row có id nhỏ nhất cho mỗi assetName
  final result = await conn.execute('''
    DELETE FROM assets
    WHERE id NOT IN (
      SELECT MIN(id) FROM assets GROUP BY "assetName"
    );
  ''');
  print('Deleted ${result.affectedRows} duplicate asset rows');

  final count = await conn.execute('SELECT COUNT(*) FROM assets;');
  print('Total assets remaining: ${count.first.first}');

  await conn.close();
  print('Done!');
}
