// ignore_for_file: avoid_print
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

void main() async {
  // Tạo hashes
  final adminHash = BCrypt.hashpw('admin123', BCrypt.gensalt());
  final itHash    = BCrypt.hashpw('it123',    BCrypt.gensalt());
  final userHash  = BCrypt.hashpw('user123',  BCrypt.gensalt());

  print('admin hash: $adminHash');
  print('it hash   : $itHash');
  print('user hash : $userHash');

  // Kết nối PostgreSQL
  final conn = await Connection.open(
    Endpoint(
      host: '127.0.0.1',
      port: 5433,
      database: 'ticketmanagement_server',
      username: 'postgres',
      password: '9-0-qNvHZWF21k38HxbIdEK48QV_Hq_C',
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  print('Connected to DB');

  await conn.execute('''
    INSERT INTO departments (id, "deptName") VALUES
      (1, 'Bộ phận IT'),
      (2, 'Nhân sự'),
      (3, 'Tài chính')
    ON CONFLICT (id) DO NOTHING;
  ''');

  await conn.execute('''
    INSERT INTO categories (id, "categoryName") VALUES
      (1, 'Lỗi phần cứng'),
      (2, 'Lỗi phần mềm'),
      (3, 'Lỗi mạng'),
      (4, 'Khác')
    ON CONFLICT (id) DO NOTHING;
  ''');

  await conn.execute('''
    INSERT INTO assets (id, "assetName", "assetType", "serialNumber") VALUES
      (1, 'Dell Laptop #001', 'Laptop', 'SN-001'),
      (2, 'HP Printer', 'Printer', 'SN-002'),
      (3, 'Cisco Switch', 'Network', 'SN-003')
    ON CONFLICT (id) DO NOTHING;
  ''');

  await conn.execute(Sql.named('''
    INSERT INTO app_users (id, username, "passwordHash", "fullName", phone, "roleId", "deptId", "createdAt") VALUES
      (1, 'admin', @adminHash, 'Administrator', '0900000001', 1, 1, now()),
      (2, 'it01',  @itHash,   'Tran Van IT',   '0900000002', 2, 1, now()),
      (3, 'user1', @userHash, 'Nguyen Van A',  '0900000003', 3, 2, now())
    ON CONFLICT (id) DO NOTHING;
  '''), parameters: {'adminHash': adminHash, 'itHash': itHash, 'userHash': userHash});

  // Reset sequences
  await conn.execute("SELECT setval(pg_get_serial_sequence('departments', 'id'), 10);");
  await conn.execute("SELECT setval(pg_get_serial_sequence('categories',  'id'), 10);");
  await conn.execute("SELECT setval(pg_get_serial_sequence('assets',      'id'), 10);");
  await conn.execute("SELECT setval(pg_get_serial_sequence('app_users',   'id'), 10);");

  await conn.close();
  print('✓ Seed data inserted!');
}
