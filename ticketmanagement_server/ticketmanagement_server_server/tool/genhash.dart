// ignore_for_file: avoid_print
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';

void main() {
  final adminHash = BCrypt.hashpw('admin123', BCrypt.gensalt());
  final itHash    = BCrypt.hashpw('it123',    BCrypt.gensalt());
  final userHash  = BCrypt.hashpw('user123',  BCrypt.gensalt());

  final sql = '''
INSERT INTO departments (id, "deptName") VALUES
  (1, 'IT Department'), (2, 'HR Department'), (3, 'Finance')
ON CONFLICT (id) DO NOTHING;

INSERT INTO categories (id, "categoryName") VALUES
  (1, 'Hardware'), (2, 'Software'), (3, 'Network'), (4, 'Other')
ON CONFLICT (id) DO NOTHING;

INSERT INTO assets (id, "assetName", "assetType", "serialNumber") VALUES
  (1, 'Dell Laptop #001', 'Laptop', 'SN-001'),
  (2, 'HP Printer', 'Printer', 'SN-002'),
  (3, 'Cisco Switch', 'Network', 'SN-003')
ON CONFLICT (id) DO NOTHING;

INSERT INTO app_users (id, username, "passwordHash", "fullName", phone, "roleId", "deptId", "createdAt") VALUES
  (1, 'admin', '$adminHash', 'Administrator', '0900000001', 1, 1, now()),
  (2, 'it01',  '$itHash',   'Tran Van IT',   '0900000002', 2, 1, now()),
  (3, 'user1', '$userHash', 'Nguyen Van A',  '0900000003', 3, 2, now())
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('departments','id'), 10);
SELECT setval(pg_get_serial_sequence('categories','id'),  10);
SELECT setval(pg_get_serial_sequence('assets','id'),      10);
SELECT setval(pg_get_serial_sequence('app_users','id'),   10);

SELECT 'Seed done' as result;
''';

  final f = File(r'C:\Temp\sp_seed.sql');
  f.parent.createSync(recursive: true);
  f.writeAsStringSync(sql);
  print('SQL written to ${f.path}');
}
