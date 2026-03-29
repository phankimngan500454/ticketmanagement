-- Seed departments
INSERT INTO departments (id, "deptName") VALUES
  (1, 'Bộ phận IT'),
  (2, 'Nhân sự'),
  (3, 'Tài chính')
ON CONFLICT (id) DO NOTHING;

-- Seed categories
INSERT INTO categories (id, "categoryName") VALUES
  (1, 'Lỗi phần cứng'),
  (2, 'Lỗi phần mềm'),
  (3, 'Lỗi mạng'),
  (4, 'Khác')
ON CONFLICT (id) DO NOTHING;

-- Seed assets
INSERT INTO assets (id, "assetName", "assetType", "serialNumber") VALUES
  (1, 'Dell Laptop #001', 'Laptop', 'SN-001'),
  (2, 'HP Printer', 'Printer', 'SN-002'),
  (3, 'Cisco Switch', 'Network', 'SN-003')
ON CONFLICT (id) DO NOTHING;

-- Seed users (admin123 / it123 / user123)
INSERT INTO app_users (id, username, "passwordHash", "fullName", phone, "roleId", "deptId", "createdAt") VALUES
  (1, 'admin', '$2a$10$g3PFEHF.HsBsAPy/2TMurObfQ35Oxbw0eFSSBQ3bHKer6fo.X7/ea', 'Administrator', '0900000001', 1, 1, now()),
  (2, 'it01',  '$2a$10$Aom.FVlPK5aVBQ3uEATi6uqjKVTtBRISFkKIgRh/Vwcsyi1HovnXy', 'Tran Van IT',   '0900000002', 2, 1, now()),
  (3, 'user1', '$2a$10$g.XN8hxJT1b23LoZwxdhbuXTIRVuf8DBsyuM7NZg8A2ff.H5Dn5Q6', 'Nguyen Van A',  '0900000003', 3, 2, now())
ON CONFLICT (id) DO NOTHING;

-- Reset sequences
SELECT setval(pg_get_serial_sequence('departments', 'id'), 10);
SELECT setval(pg_get_serial_sequence('categories',  'id'), 10);
SELECT setval(pg_get_serial_sequence('assets',      'id'), 10);
SELECT setval(pg_get_serial_sequence('app_users',   'id'), 10);
