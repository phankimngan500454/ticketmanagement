import '../models/department.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/asset.dart';
import '../models/ticket.dart';
import '../models/ticket_comment.dart';

/// ==================================================
/// DỮ LIỆU MẪU — Thay thế bằng API call thực tế
/// ==================================================

// ── DEPARTMENTS ──────────────────────────────────
final List<Department> mockDepartments = [
  Department(deptId: 1, deptName: 'IT'),
  Department(deptId: 2, deptName: 'Kế toán'),
  Department(deptId: 3, deptName: 'Nhân sự'),
  Department(deptId: 4, deptName: 'Kinh doanh'),
];

// ── USERS ─────────────────────────────────────────
final List<User> mockUsers = [
  User(userId: 1, fullName: 'Quản Trị Viên', phone: '0901111111', role: 'Admin', createdAt: DateTime(2025, 1, 1), deptId: 1, deptName: 'IT'),
  User(userId: 2, fullName: 'Nhân Viên IT 1', phone: '0902222222', role: 'IT', createdAt: DateTime(2025, 1, 5), deptId: 1, deptName: 'IT'),
  User(userId: 3, fullName: 'Nhân Viên IT 2', phone: '0903333333', role: 'IT', createdAt: DateTime(2025, 1, 5), deptId: 1, deptName: 'IT'),
  User(userId: 4, fullName: 'Nhân Viên IT 3', phone: '0904444444', role: 'IT', createdAt: DateTime(2025, 2, 1), deptId: 1, deptName: 'IT'),
  User(userId: 5, fullName: 'Nguyễn Văn Khách', phone: '0905555555', role: 'Customer', createdAt: DateTime(2025, 3, 1), deptId: 2, deptName: 'Kế toán'),
  User(userId: 6, fullName: 'Trần Thị B', phone: '0906666666', role: 'Customer', createdAt: DateTime(2025, 3, 5), deptId: 3, deptName: 'Nhân sự'),
  User(userId: 7, fullName: 'Lê Văn C', phone: '0907777777', role: 'Customer', createdAt: DateTime(2025, 3, 10), deptId: 4, deptName: 'Kinh doanh'),
  User(userId: 8, fullName: 'Phạm Thị D', phone: '0908888888', role: 'Customer', createdAt: DateTime(2025, 4, 1), deptId: 2, deptName: 'Kế toán'),
];

// ── CATEGORIES ───────────────────────────────────
final List<Category> mockCategories = [
  Category(categoryId: 1, categoryName: 'Lỗi phần mềm'),
  Category(categoryId: 2, categoryName: 'Lỗi phần cứng'),
  Category(categoryId: 3, categoryName: 'Lỗi mạng'),
  Category(categoryId: 4, categoryName: 'Yêu cầu cấp quyền'),
  Category(categoryId: 5, categoryName: 'Cài đặt / Nâng cấp'),
  Category(categoryId: 6, categoryName: 'Khác'),
];

// ── ASSETS ───────────────────────────────────────
final List<Asset> mockAssets = [
  Asset(assetId: 1, assetName: 'Laptop Dell XPS 13', assetCode: 'LT-001', assetGroup: 'Phần cứng', assetType: 'Laptop', assetModel: 'Dell XPS 13', status: 'Active'),
  Asset(assetId: 2, assetName: 'Máy in HP LaserJet', assetCode: 'PR-001', assetGroup: 'Phần cứng', assetType: 'Máy in', assetModel: 'HP LaserJet Pro', status: 'Maintenance'),
  Asset(assetId: 3, assetName: 'Router tầng 2', assetCode: 'NW-001', assetGroup: 'Mạng', assetType: 'Router', assetModel: 'Cisco RV340', status: 'Active'),
  Asset(assetId: 4, assetName: 'Laptop Lenovo ThinkPad', assetCode: 'LT-002', assetGroup: 'Phần cứng', assetType: 'Laptop', assetModel: 'Lenovo ThinkPad X1', status: 'Active'),
  Asset(assetId: 5, assetName: 'Máy in Canon', assetCode: 'PR-002', assetGroup: 'Phần cứng', assetType: 'Máy in', assetModel: 'Canon imageRUNNER', status: 'Inactive'),
];

// ── TICKETS ──────────────────────────────────────
final List<Ticket> mockTickets = [
  Ticket(
    ticketId: 1, requesterId: 5, assigneeId: 2, categoryId: 1, assetId: 1,
    subject: 'Không thể đăng nhập ứng dụng',
    description: 'Tôi không thể đăng nhập vào hệ thống ERP từ sáng nay. Báo lỗi "Sai mật khẩu" dù đã nhập đúng.',
    status: 'Open', priority: 'High', createdAt: DateTime(2026, 3, 12, 8, 30),
    requesterName: 'Nguyễn Văn Khách', assigneeName: 'Nhân Viên IT 1', categoryName: 'Lỗi phần mềm', assetName: 'Laptop Dell XPS 13',
  ),
  Ticket(
    ticketId: 2, requesterId: 6, assigneeId: null, categoryId: 2, assetId: 2,
    subject: 'Máy in tầng 2 bị kẹt giấy',
    description: 'Máy in HP LaserJet tại tầng 2 liên tục báo lỗi kẹt giấy dù đã lấy giấy ra.',
    status: 'Pending', priority: 'Medium', createdAt: DateTime(2026, 3, 12, 9, 0),
    requesterName: 'Trần Thị B', assigneeName: null, categoryName: 'Lỗi phần cứng', assetName: 'Máy in HP LaserJet',
  ),
  Ticket(
    ticketId: 3, requesterId: 7, assigneeId: 2, categoryId: 4, assetId: null,
    subject: 'Xin cấp quyền truy cập thư mục chung',
    description: 'Xin cấp quyền đọc/ghi vào thư mục \\\\server\\shared\\KinhDoanh.',
    status: 'Resolved', priority: 'Low', createdAt: DateTime(2026, 3, 11, 14, 0),
    requesterName: 'Lê Văn C', assigneeName: 'Nhân Viên IT 1', categoryName: 'Yêu cầu cấp quyền', assetName: null,
  ),
  Ticket(
    ticketId: 4, requesterId: 5, assigneeId: 3, categoryId: 3, assetId: 3,
    subject: 'Không vào được WiFi công ty',
    description: 'Từ hôm qua laptop không kết nối được WiFi công ty, báo "Không có internet".',
    status: 'Open', priority: 'High', createdAt: DateTime(2026, 3, 11, 10, 0),
    requesterName: 'Nguyễn Văn Khách', assigneeName: 'Nhân Viên IT 2', categoryName: 'Lỗi mạng', assetName: 'Router tầng 2',
  ),
  Ticket(
    ticketId: 5, requesterId: 8, assigneeId: null, categoryId: 2, assetId: 5,
    subject: 'Máy in báo hết mực',
    description: 'Máy in Canon tại phòng kế toán báo hết mực, cần thay hộp mực mới.',
    status: 'Pending', priority: 'Low', createdAt: DateTime(2026, 3, 10, 15, 30),
    requesterName: 'Phạm Thị D', assigneeName: null, categoryName: 'Lỗi phần cứng', assetName: 'Máy in Canon',
  ),
  // ── TEST: WaitingConfirmation flow ──────────────────────────────────────────
  Ticket(
    ticketId: 6, requesterId: 5, assigneeId: 2, categoryId: 5, assetId: 4,
    subject: 'Cài đặt phần mềm diệt virus',
    description: 'Laptop không có phần mềm diệt virus, cần cài đặt và cấu hình tự động cập nhật.',
    status: 'WaitingConfirmation', priority: 'Medium', createdAt: DateTime(2026, 3, 11, 9, 0),
    requesterName: 'Nguyễn Văn Khách', assigneeName: 'Nhân Viên IT 1',
    categoryName: 'Cài đặt / Nâng cấp', assetName: 'Laptop Lenovo ThinkPad',
  ),
];

// ── TICKET COMMENTS ──────────────────────────────
final List<TicketComment> mockComments = [
  TicketComment(commentId: 1, ticketId: 1, userId: 5, commentText: 'Cho tôi hỏi lỗi này xuất hiện từ lúc nào?', createdAt: DateTime(2026, 3, 12, 8, 45), authorName: 'Nguyễn Văn Khách', authorRole: 'Customer'),
  TicketComment(commentId: 2, ticketId: 1, userId: 2, commentText: 'Từ khoảng 8 giờ sáng hôm nay. Tôi đã thử đổi mật khẩu nhưng vẫn không được.', createdAt: DateTime(2026, 3, 12, 9, 0), authorName: 'Nhân Viên IT 1', authorRole: 'IT'),
  TicketComment(commentId: 3, ticketId: 1, userId: 5, commentText: 'Tôi đang kiểm tra lại. Bạn thử xóa cache trình duyệt và thử lại nhé.', createdAt: DateTime(2026, 3, 12, 9, 15), authorName: 'Nguyễn Văn Khách', authorRole: 'Customer'),
  TicketComment(commentId: 4, ticketId: 4, userId: 5, commentText: 'Từ tối hôm qua không kết nối được.', createdAt: DateTime(2026, 3, 11, 10, 10), authorName: 'Nguyễn Văn Khách', authorRole: 'Customer'),
  TicketComment(commentId: 5, ticketId: 4, userId: 3, commentText: 'Bạn thử quên WiFi rồi kết nối lại xem sao?', createdAt: DateTime(2026, 3, 11, 10, 30), authorName: 'Nhân Viên IT 2', authorRole: 'IT'),
];
