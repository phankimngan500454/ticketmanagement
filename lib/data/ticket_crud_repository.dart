// ignore_for_file: avoid_print
// ============================================================
//  ticket_crud_repository.dart
//  Tạo / truy vấn / phân công / cập nhật trạng thái ticket
// ============================================================
import 'repository_base.dart';
import '../models/ticket.dart';
import '../services/sp_client.dart';

mixin TicketCrudRepository on RepositoryBase {
  // ── Lấy tất cả ticket (Admin) ────────────────────────────────
  Future<List<Ticket>> getAllTickets() async {
    await warmCache();
    final raw = await client.ticket.getTickets(0, 1); // roleId 1 = Admin
    return raw.map(mapTicket).toList();
  }

  // ── Lấy ticket theo người gửi (Customer) ────────────────────
  Future<List<Ticket>> getTicketsByRequester(int requesterId) async {
    await warmCache();
    final raw = await client.ticket.getTickets(requesterId, 3);
    final tickets = raw.map(mapTicket).toList();

    // Nếu user là Tài chính (không phải Bảo hiểm), chỉ hiện bệnh án có đánh dấu tài chính = CÓ
    final user = currentUser;
    if (user != null) {
      final p = user.permissions ?? '';
      final isFin = p.contains('finance');
      final isIns = p.contains('insurance');
      if (isFin && !isIns) {
        return tickets.where((t) {
          if (t.ticketType == 'reopen_medical' && t.requesterId != requesterId) {
            // Chỉ hiện bệnh án người khác nếu có ảnh hưởng tài chính
            return (t.description ?? '').toLowerCase().contains('ảnh hưởng tài chính: có');
          }
          return true;
        }).toList();
      }
    }
    return tickets;
  }

  // ── Lấy ticket chưa được phân công ──────────────────────────
  Future<List<Ticket>> getUnassignedTickets() async {
    await warmCache();
    final raw = await client.ticket.getUnassignedTickets();
    return raw.map(mapTicket).where((t) => t.ticketType != 'feedback' && t.ticketType != 'reopen_medical').toList();
  }

  // ── Lấy ticket theo nhân viên IT ────────────────────────────
  Future<List<Ticket>> getTicketsByAssignee(int assigneeId) async {
    await warmCache();
    final raw = await client.ticket.getTickets(assigneeId, 2);
    return raw.where((t) => t.status != 'Resolved').map(mapTicket).where((t) => t.ticketType != 'feedback' && t.ticketType != 'reopen_medical').toList();
  }

  // ── Lấy chi tiết một ticket theo ID ─────────────────────────
  Future<Ticket?> getTicketById(int ticketId) async {
    await warmCache();
    final t = await client.ticket.getTicketById(ticketId);
    return t == null ? null : mapTicket(t);
  }

  // ── Tạo ticket mới ──────────────────────────────────────────
  Future<Ticket> createTicket({
    required int requesterId,
    String? requesterName,
    required int categoryId,
    String? categoryName,
    required String subject,
    required String description,
    required String priority,
    int? assetId,
    String? assetName,
    DateTime? deadline,
    String? ticketType,
  }) async {
    await warmCache();
    final t = await client.ticket.createTicket(
      requesterId, categoryId, subject, description, priority, assetId, ticketType,
    );
    return mapTicket(t);
  }

  // ── Phân công nhân viên IT ───────────────────────────────────
  Future<Ticket> assignTicket(int ticketId, int? assigneeId,
      [String? assigneeName]) async {
    await warmCache();
    final t = await client.ticket.assignTicket(ticketId, assigneeId);
    if (t == null) throw Exception('Ticket not found');
    return mapTicket(t);
  }

  // ── Cập nhật trạng thái ticket ──────────────────────────────
  // Các trạng thái hợp lệ: Open | Pending | WaitingConfirmation | Resolved | Cancelled
  Future<Ticket> updateStatus(int ticketId, String status) async {
    await warmCache();
    final t = await client.ticket.updateStatus(ticketId, status);
    if (t == null) throw Exception('Ticket not found');
    return mapTicket(t);
  }

  // ── Lấy danh sách góp ý/mở BA (Dành cho Dashboard Xét duyệt) ────────────
  Future<List<Ticket>> getFeedbackTickets() async {
    await warmCache();
    final user = currentUser;
    if (user == null) return [];
    
    int roleId = user.role == 'Admin' ? 1 
               : user.role == 'IT' ? 2 
               : user.role == 'Manager' ? 4 : 3;

    final raw = await client.ticket.getTickets(user.userId, roleId); 

    final p = user.permissions ?? '';
    final isIns = p.contains('insurance');
    final isFin = p.contains('finance');

    return raw.where((t) {
      // Chỉ quan tâm feedback và reopen_medical
      if (t.ticketType != 'feedback' && t.ticketType != 'reopen_medical') return false;

      // Nếu là Customer thì bị giới hạn bởi quyền
      if (t.ticketType == 'reopen_medical' && roleId == 3) {
        // Chưa duyệt (Open) → chỉ hiện cho người tạo
        if (t.status == 'Open') {
          return t.requesterId == user.userId;
        }

        if (isFin && !isIns) {
          // Tài chính chỉ thấy bệnh án có đánh dấu "Ảnh hưởng tài chính: CÓ"
          return (t.description ?? '').toLowerCase().contains('ảnh hưởng tài chính: có');
        }
        // Bảo hiểm thấy tất cả bệnh án đã qua duyệt (Resolved/Pending/WaitingConfirmation/Cancelled)
        if (isIns) return true;
        
        // Nếu không có quyền duyệt mà lọt vào đây (do requesterId), thì nó là phiếu do họ tạo
        return t.requesterId == user.userId;
      }
      return true;
    }).map(mapTicket).toList();
  }
}
