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
    return raw.map(mapTicket).toList();
  }

  // ── Lấy ticket chưa được phân công ──────────────────────────
  Future<List<Ticket>> getUnassignedTickets() async {
    await warmCache();
    final raw = await client.ticket.getUnassignedTickets();
    return raw.map(mapTicket).toList();
  }

  // ── Lấy ticket theo nhân viên IT ────────────────────────────
  Future<List<Ticket>> getTicketsByAssignee(int assigneeId) async {
    await warmCache();
    final raw = await client.ticket.getTickets(assigneeId, 2);
    // Lọc bỏ Resolved vì IT chỉ cần xem ticket đang xử lý
    return raw.where((t) => t.status != 'Resolved').map(mapTicket).toList();
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
  }) async {
    await warmCache();
    final t = await client.ticket.createTicket(
      requesterId, categoryId, subject, description, priority, assetId,
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
}
