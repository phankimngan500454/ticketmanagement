-- ============================================================
-- SEED DATA ĐẦY ĐỦ - Chạy trên máy chủ mới (Windows Server)
-- Mật khẩu: admin=admin123 | it01=it123 | user1=user123
--
-- Cách chạy trên máy server:
--   psql -U postgres -d ticketmanagement_server -f seed_full.sql
-- ============================================================

-- ── 1. PHÒNG BAN ─────────────────────────────────────────────
INSERT INTO "departments" (id, "name") VALUES
  (1, 'Phòng Công nghệ thông tin'),
  (2, 'Phòng Kế hoạch tổng hợp'),
  (3, 'Phòng Tổ chức cán bộ'),
  (4, 'Phòng Tài chính kế toán'),
  (5, 'Phòng Điều dưỡng'),
  (6, 'Phòng Hành chính quản trị'),
  (7, 'Phòng Chỉ đạo tuyến')
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('departments', 'id'), 20);

-- ── 2. DANH MỤC LỖI ──────────────────────────────────────────
INSERT INTO "categories" (id, "categoryName") VALUES
  (1, 'Lỗi phần cứng'),
  (2, 'Lỗi phần mềm'),
  (3, 'Lỗi mạng'),
  (4, 'Thiết bị y tế'),
  (5, 'Khác')
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('categories', 'id'), 20);

-- ── 3. THIẾT BỊ ───────────────────────────────────────────────
-- Cột DB: assetName, assetType, serialNumber, categoryId, assetGroup, assetModel
-- (KHÔNG có assetCode, KHÔNG có status)

-- Phần cứng (categoryId = 1)
INSERT INTO "assets" ("assetName", "assetType", "serialNumber", "assetGroup", "assetModel", "categoryId") VALUES
  ('Dell Laptop #001',                    'Laptop',               'SN-LAP-001',  'Hardware', 'Dell Latitude 5520',        1),
  ('Laptop bác sĩ Lenovo ThinkPad E14',  'Laptop',               'MED-LAP-001', 'Hardware', 'Lenovo ThinkPad E14 Gen 4', 1),
  ('PC phòng khám Dell OptiPlex 3090',   'Máy tính để bàn',     'MED-PC-001',  'Hardware', 'Dell OptiPlex 3090',         1),
  ('Máy tính bảng phòng khám Samsung',   'Điện thoại / Tablet', 'MED-TAB-001', 'Hardware', 'Samsung Galaxy Tab A8',     1),
  ('Màn hình bệnh nhân Philips MX450',   'Màn hình',            'MED-MON-001', 'Hardware', 'Philips IntelliVue MX450',  1),
  ('Màn hình bệnh nhân Mindray T5',      'Màn hình',            'MED-MON-002', 'Hardware', 'Mindray BeneView T5',       1),
  ('Màn hình theo dõi Nihon Kohden',     'Màn hình',            'MED-MON-003', 'Hardware', 'Nihon Kohden BSM-1700',     1),
  ('HP Printer',                          'Máy in',              'SN-PRT-001',  'Hardware', 'HP LaserJet 1020',          1),
  ('Máy in xét nghiệm Zebra ZD420',      'Máy in',              'MED-PRT-001', 'Hardware', 'Zebra ZD420',               1),
  ('Máy in phim X-quang Fujifilm',       'Máy in',              'MED-PRT-002', 'Hardware', 'Fujifilm Drypix Smart',     1),
  ('Máy in toa thuốc HP LaserJet M404n', 'Máy in',              'MED-PRT-003', 'Hardware', 'HP LaserJet M404n',         1),
  ('Máy in nhãn barcode Zebra GK420d',   'Máy in',              'MED-PRT-004', 'Hardware', 'Zebra GK420d',              1);

-- Mạng (categoryId = 3)
INSERT INTO "assets" ("assetName", "assetType", "serialNumber", "assetGroup", "assetModel", "categoryId") VALUES
  ('Cisco Switch Catalyst 2960',          'Switch',   'MED-NET-001', 'Network', 'Cisco Catalyst 2960-24',  3),
  ('Router Wi-Fi bệnh viện Cisco RV340', 'Router',   'MED-NET-002', 'Network', 'Cisco RV340',             3),
  ('Access Point TP-Link EAP225',        'Wifi AP',  'MED-NET-003', 'Network', 'TP-Link EAP225',          3);

-- Thiết bị y tế (categoryId = 4)
INSERT INTO "assets" ("assetName", "assetType", "serialNumber", "assetGroup", "assetModel", "categoryId") VALUES
  ('Máy siêu âm Mindray DC-60',           'Thiết bị y tế', 'MED-US-001',  'Medical', 'Mindray DC-60',              4),
  ('Máy điện tim ECG Nihon Kohden',        'Thiết bị y tế', 'MED-ECG-001', 'Medical', 'Nihon Kohden ECG-1350',      4),
  ('Máy đo SpO2/huyết áp Omron',          'Thiết bị y tế', 'MED-SPO-001', 'Medical', 'Omron HEM-7156',             4),
  ('Máy chụp X-quang Shimadzu',           'Thiết bị y tế', 'MED-XRY-001', 'Medical', 'Shimadzu MobileDaRt',        4),
  ('UPS APC Smart-UPS 1500VA (ICU)',       'Thiết bị điện', 'MED-UPS-001', 'Medical', 'APC Smart-UPS 1500VA',       4),
  ('Camera an ninh Hikvision DS-2CD',      'Camera',        'MED-CAM-001', 'Medical', 'Hikvision DS-2CD2143G2',     4),
  ('Máy chủ HIS/EMR Dell PowerEdge R540', 'Máy chủ',       'MED-SRV-001', 'Medical', 'Dell PowerEdge R540',        4);

SELECT setval(pg_get_serial_sequence('assets', 'id'), 100);

-- ── 4. NGƯỜI DÙNG ─────────────────────────────────────────────
-- roleId: 1=Admin, 2=IT, 3=Customer (nhân viên thường)
-- Mật khẩu: admin123 / it123 / user123
INSERT INTO "app_users" (id, "username", "passwordHash", "fullName", "phone", "roleId", "deptId", "createdAt") VALUES
  (1, 'admin', '$2a$10$g3PFEHF.HsBsAPy/2TMurObfQ35Oxbw0eFSSBQ3bHKer6fo.X7/ea', 'Administrator',   '0900000001', 1, 1, now()),
  (2, 'it01',  '$2a$10$Aom.FVlPK5aVBQ3uEATi6uqjKVTtBRISFkKIgRh/Vwcsyi1HovnXy', 'Nhân viên IT 01', '0900000002', 2, 1, now()),
  (3, 'user1', '$2a$10$g.XN8hxJT1b23LoZwxdhbuXTIRVuf8DBsyuM7NZg8A2ff.H5Dn5Q6', 'Nguyễn Văn A',    '0900000003', 3, 2, now())
ON CONFLICT (id) DO NOTHING;

SELECT setval(pg_get_serial_sequence('app_users', 'id'), 20);

-- ── 5. KIỂM TRA KẾT QUẢ ──────────────────────────────────────
SELECT 'departments' AS "Bảng", COUNT(*) AS "Số bản ghi" FROM departments
UNION ALL
SELECT 'categories',            COUNT(*)                  FROM categories
UNION ALL
SELECT 'assets',                COUNT(*)                  FROM assets
UNION ALL
SELECT 'app_users',             COUNT(*)                  FROM app_users;
