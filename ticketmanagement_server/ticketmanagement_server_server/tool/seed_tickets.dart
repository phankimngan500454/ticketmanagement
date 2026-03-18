import 'dart:io';
import 'dart:convert';

void main() async {
  final now = DateTime.now().toUtc();
  String ts(int hoursAgo) {
    final t = now.subtract(Duration(hours: hoursAgo));
    return t.toIso8601String();
  }

  final lines = [
    "DELETE FROM tickets;",
    "SELECT setval(pg_get_serial_sequence('tickets', 'id'), 1, false);",
    "INSERT INTO tickets (\"requesterId\",\"assigneeId\",\"categoryId\",\"assetId\",\"subject\",\"description\",\"status\",\"priority\",\"createdAt\") VALUES",
    "  (3, 2, 1, NULL, 'Không thể đăng nhập ứng dụng', 'Ứng dụng báo sai mật khẩu', 'Pending', 'High', '${ts(6)}'),",
    "  (3, 2, 2, 1, 'Máy in tầng 2 bị kẹt giấy', 'Máy in HP bị kẹt giấy liên tục', 'Pending', 'Medium', '${ts(5)}'),",
    "  (3, NULL, 3, NULL, 'Xin cấp quyền truy cập thư mục', 'Cần quyền đọc ghi vào shared drive', 'Open', 'Low', '${ts(4)}'),",
    "  (3, 2, 4, NULL, 'Không vào được WiFi công ty', 'Máy tính báo sai mật khẩu WiFi', 'Open', 'Medium', '${ts(3)}'),",
    "  (3, 2, 2, 1, 'Máy in báo hết mực', 'Máy in tầng 1 báo ink empty', 'Resolved', 'Low', '${ts(1)}');",
  ];

  final sql = lines.join('\n');
  final file = File(r'C:\Temp\seed_tickets_utf8.sql');
  await file.writeAsBytes(utf8.encode(sql));
  print('SQL written to ${file.path}');
}
