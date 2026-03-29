// ignore_for_file: avoid_print
import 'package:postgres/postgres.dart';

void main() async {
  final conn = await Connection.open(
    Endpoint(host: '127.0.0.1', port: 5432,
      database: 'ticketmanagement_server', username: 'postgres', password: 'postgres'),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  print('=== Departments ===');
  final depts = await conn.execute('SELECT id, "deptName" FROM departments ORDER BY id;');
  for (final row in depts) print('  id=${row[0]}, name=${row[1]}');

  print('\n=== Duplicate departments ===');
  final dupDepts = await conn.execute('''
    SELECT id, COUNT(*) as cnt FROM departments GROUP BY id HAVING COUNT(*) > 1;
  ''');
  if (dupDepts.isEmpty) print('  Không có duplicate'); else for (final row in dupDepts) print('  id=${row[0]}, count=${row[1]}');

  print('\n=== Duplicate deptName ===');
  final dupNames = await conn.execute('''
    SELECT "deptName", COUNT(*) FROM departments GROUP BY "deptName" HAVING COUNT(*) > 1;
  ''');
  if (dupNames.isEmpty) print('  Không có duplicate name'); else for (final row in dupNames) print('  name=${row[0]}, count=${row[1]}');

  await conn.close();
}
