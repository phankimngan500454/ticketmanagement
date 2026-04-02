import 'dart:io';

void main() {
  final dir = Directory('C:/Users/ASUS/Documents/ticketmanagement/lib/screens');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    String original = content;

    content = content.replaceAll(r"'❌ Lỗi: $e'", r"'❌ Đã xảy ra lỗi, vui lòng thử lại!'");
    content = content.replaceAll(r"'Lỗi: $e'", r"'Đã xảy ra lỗi, vui lòng thử lại!'");
    content = content.replaceAll(r"'Không tải được danh bạ: $e'", r"'Không tải được danh bạ!'");
    content = content.replaceAll(r"'Không tải được danh sách: $e'", r"'Không tải được danh sách!'");
    content = content.replaceAll(r"'⚠️ Ticket đã tạo nhưng không gửi được deadline: $e'", r"'⚠️ Ticket đã tạo nhưng gặp lỗi gửi đề xuất'");
    content = content.replaceAll(r"'Có lỗi xảy ra: $e'", r"'Có lỗi xảy ra, vui lòng thử lại!'");
    content = content.replaceAll(r"'Không tải được dữ liệu: $e'", r"'Không tải được dữ liệu!'");
    content = content.replaceAll(r"'Lỗi khi xóa: $e'", r"'Lỗi khi xóa!'");
    content = content.replaceAll(r"'❌ Lỗi khi xóa: $e'", r"'❌ Lỗi khi xóa!'");
    
    // Some single occurrences and variable formats:
    content = content.replaceAll(r"Text('Lỗi: $e')", r"Text('Đã xảy ra lỗi, vui lòng thử lại!')");

    if (content != original) {
      file.writeAsStringSync(content);
      print('Updated: ${file.path}');
    }
  }
}
