// ============================================================
//  deadline_repository.dart
//  Đề xuất / duyệt / xác nhận deadline
// ============================================================
import 'repository_base.dart';
import '../models/ticket.dart';
import '../services/sp_client.dart';

mixin DeadlineRepository on RepositoryBase {
  // ── Người dùng / IT đề xuất deadline ────────────────────────
  // deadlineStatus → 'Pending' (chờ Admin duyệt)
  Future<Ticket> proposeDeadline(
      int ticketId, int proposedByUserId, DateTime deadline) async {
    await warmCache();
    final t = await client.ticket
        .proposeDeadline(ticketId, proposedByUserId, deadline);
    if (t == null) throw Exception('Ticket not found');
    return mapTicket(t);
  }

  // ── Admin duyệt hoặc điều chỉnh deadline ────────────────────
  // action = 'approve' → deadlineStatus: 'Approved'
  // action = 'adjust'  → deadlineStatus: 'Adjusted', finalDeadline = ngày Admin chọn
  Future<Ticket> approveDeadline(int ticketId, String action,
      {DateTime? finalDeadline, String? adminNote}) async {
    await warmCache();
    final t = await client.ticket
        .approveDeadline(ticketId, action, finalDeadline, adminNote);
    if (t == null) throw Exception('Ticket not found');
    return mapTicket(t);
  }

  // ── Customer xác nhận deadline (confirmed = true/false) ──────
  Future<Ticket> confirmDeadline(int ticketId, bool confirmed) async {
    await warmCache();
    final t = await client.ticket.confirmDeadline(ticketId, confirmed);
    if (t == null) throw Exception('Ticket not found');
    return mapTicket(t);
  }
}
