// ignore_for_file: avoid_print
import 'package:postgres/postgres.dart';

void main() async {
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

  print('Connected to DB');

  await conn.execute('''
    INSERT INTO assets ("assetName", "assetType", "serialNumber") VALUES
      ('Màn hình bệnh nhân Philips IntelliVue MX450', 'Màn hình y tế', 'MED-MON-001'),
      ('Màn hình bệnh nhân Mindray BeneView T5',      'Màn hình y tế', 'MED-MON-002'),
      ('Màn hình theo dõi sinh hiệu Nihon Kohden',    'Màn hình y tế', 'MED-MON-003'),
      ('Máy in kết quả xét nghiệm Zebra ZD420',       'Máy in y tế',   'MED-PRT-001'),
      ('Máy in phim X-quang Fujifilm Drypix',         'Máy in y tế',   'MED-PRT-002'),
      ('Máy in toa thuốc HP LaserJet M404n',          'Máy in y tế',   'MED-PRT-003'),
      ('Máy in nhãn barcode bệnh nhân Zebra GK420d',  'Máy in y tế',   'MED-PRT-004'),
      ('Switch mạng Cisco Catalyst 2960',             'Thiết bị mạng', 'MED-NET-001'),
      ('Router Wi-Fi bệnh viện Cisco RV340',          'Thiết bị mạng', 'MED-NET-002'),
      ('Access Point TP-Link EAP225 (khu điều trị)',  'Thiết bị mạng', 'MED-NET-003'),
      ('Máy tính bảng phòng khám Samsung Tab A8',     'Máy tính bảng', 'MED-TAB-001'),
      ('PC phòng khám Dell OptiPlex 3090',            'Máy tính',      'MED-PC-001'),
      ('Laptop bác sĩ Lenovo ThinkPad E14',           'Laptop',        'MED-LAP-001'),
      ('Máy siêu âm Mindray DC-60',                   'Thiết bị y tế', 'MED-US-001'),
      ('Máy điện tim (ECG) Nihon Kohden ECG-1350',    'Thiết bị y tế', 'MED-ECG-001'),
      ('Máy đo SpO2/huyết áp Omron HEM-7156',         'Thiết bị y tế', 'MED-SPO-001'),
      ('Máy chụp X-quang kỹ thuật số Shimadzu',       'Thiết bị y tế', 'MED-XRY-001'),
      ('UPS APC Smart-UPS 1500VA (phòng ICU)',         'Thiết bị điện', 'MED-UPS-001'),
      ('Camera an ninh Hikvision DS-2CD2143',          'Camera',        'MED-CAM-001'),
      ('Máy chủ HIS/EMR Dell PowerEdge R540',          'Máy chủ',       'MED-SRV-001')
    ;
  ''');

  // Kiểm tra tổng số assets
  final result = await conn.execute('SELECT COUNT(*) FROM assets;');
  final count = result.first.first;
  print('✓ Xong! Tổng số thiết bị trong DB: $count');

  await conn.close();
}
