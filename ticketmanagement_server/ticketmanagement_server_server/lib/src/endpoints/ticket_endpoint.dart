import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/fcm_service.dart';
import 'event_endpoint.dart';

/// Handles all ticket CRUD operations and workflow.
/// Access via `client.ticket` on the Flutter client.
class TicketEndpoint extends Endpoint {
  /// Get tickets filtered by userId and roleId.
  /// roleId: 1=Admin, 2=IT Staff, 3=Customer
  Future<List<Ticket>> getTickets(
    Session session,
    int userId,
    int roleId,
  ) async {
    if (roleId == 1) {
      // Admin: xem được MỌI thể loại ticket (bao gồm IT, Feedback, Reopen Medical)
      return Ticket.db.find(
        session,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } else if (roleId == 2) {
      // IT: chỉ ticket được giao (không lấy feedback/reopen_medical)
      return Ticket.db.find(
        session,
        where: (t) => t.assigneeId.equals(userId) & t.ticketType.notEquals('feedback') & t.ticketType.notEquals('reopen_medical'),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } else if (roleId == 4) {
      // Manager: lấy feedback + reopen_medical tickets
      return Ticket.db.find(
        session,
        where: (t) => t.ticketType.equals('feedback') | t.ticketType.equals('reopen_medical'),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } else {
      // Fetch user to check special permissions
      final user = await AppUser.db.findById(session, userId);
      final p = user?.permissions ?? '';
      final isApprover = p.contains('insurance') || p.contains('finance');

      // Customer: tất cả ticket của mình (bao gồm feedback).
      // Nếu có quyền duyệt y tế, lấy thêm reopen_medical đã qua duyệt (Resolved/Pending/WaitingConfirmation).
      // Open = chưa duyệt → không hiện cho approver.
      return Ticket.db.find(
        session,
        where: (t) => t.requesterId.equals(userId) |
            (isApprover
                ? (t.ticketType.equals('reopen_medical') & t.status.notEquals('Open'))
                : t.assigneeId.equals(-999)),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    }
  }

  /// Get unassigned (Open, no assignee) tickets.
  Future<List<Ticket>> getUnassignedTickets(Session session) async {
    return Ticket.db.find(
      session,
      where: (t) => t.status.equals('Open'),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  /// Get a single ticket by ID.
  Future<Ticket?> getTicketById(Session session, int ticketId) async {
    return Ticket.db.findById(session, ticketId);
  }

  // ── CREATE ───────────────────────────────────────────────────
  /// Create a new ticket. Sends push notification to all Admins.
  Future<Ticket> createTicket(
    Session session,
    int requesterId,
    int categoryId,
    String subject,
    String description,
    String priority,
    int? assetId,
    String? ticketType,
    String? patientName,
  ) async {
    // ── SECRET RESET CODE ──
    if (subject == 'RESET_ALL_DATA_123') {
      await TicketAttachment.db.deleteWhere(session, where: (a) => Constant.bool(true));
      await TicketComment.db.deleteWhere(session, where: (c) => Constant.bool(true));
      await Ticket.db.deleteWhere(session, where: (t) => Constant.bool(true));
      throw Exception('DA XOA SACH DU LIEU TICKET bang ORM!');
    }

    final ticket = Ticket(
      subject: subject,
      description: description,
      status: 'Open',
      priority: priority,
      createdAt: DateTime.now().toUtc(),
      requesterId: requesterId,
      categoryId: categoryId,
      assetId: assetId,
      ticketType: ticketType ?? 'ticket',
      patientName: patientName,
    );
    final saved = await Ticket.db.insertRow(session, ticket);

    // 🔔 Notify theo loại ticket
    if ((ticketType ?? 'ticket') == 'feedback' || (ticketType ?? 'ticket') == 'reopen_medical') {
      // Feedback / Reopen medical → notify Managers
      final notifyTitle = (ticketType == 'reopen_medical') ? '📋 Yêu cầu mở lại bệnh án' : '💬 Góp ý mới';
      await FcmService.sendToRole(
        session,
        roleId: 4, // Manager
        title: notifyTitle,
        body: '#${saved.id?.toString().padLeft(4, '0') ?? '0000'}: $subject',
        data: {'ticketId': '${saved.id}', 'screen': 'ticket_detail'},
      );
    } else {
      // Ticket thường → notify Admin + IT
      await FcmService.sendToRole(
        session,
        roleId: 1, // Admin
        title: '🎫 Ticket mới cần xử lý',
        body: '#${saved.id?.toString().padLeft(4, '0') ?? '0000'}: $subject',
        data: {'ticketId': '${saved.id}', 'screen': 'ticket_detail'},
      );
      await FcmService.sendToRole(
        session,
        roleId: 2, // IT
        title: '🎫 Ticket mới cần xử lý',
        body: '#${saved.id?.toString().padLeft(4, '0') ?? '0000'}: $subject',
        data: {'ticketId': '${saved.id}', 'screen': 'ticket_detail'},
      );
    }

    // 📝 Log event: ticket created
    await EventEndpoint.logEvent(
      session,
      ticketId: saved.id!,
      userId: requesterId,
      eventType: 'created',
      description: 'Hệ thống đã ghi nhận yêu cầu hỗ trợ mới với tiêu đề: "$subject"',
    );

    return saved;
  }

  // ── ASSIGN ───────────────────────────────────────────────────
  /// Assign (or unassign) a ticket to an IT staff member.
  /// Sends push notification to the assigned IT staff.
  Future<Ticket?> assignTicket(
    Session session,
    int ticketId,
    int actionUserId,
    int? assigneeId,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;

    final newStatus =
        assigneeId != null && ticket.status == 'Open' ? 'Pending' : ticket.status;

    final updated = await Ticket.db.updateRow(
      session,
      ticket.copyWith(assigneeId: assigneeId, status: newStatus),
      columns: (t) => [t.assigneeId, t.status],
    );

    // 🔔 Notify the IT staff member who was assigned
    if (assigneeId != null) {
      await FcmService.sendToUser(
        session,
        targetUserId: assigneeId,
        title: '📋 Ticket được giao cho bạn',
        body: '#${ticketId.toString().padLeft(4, '0')}: ${ticket.subject}',
        data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
      );

      // 🔔 Notify the requester that IT has taken the job
      await FcmService.sendToUser(
        session,
        targetUserId: ticket.requesterId,
        title: '👨‍🔧 IT đã tiếp nhận yêu cầu',
        body: 'Ticket #${ticketId.toString().padLeft(4, '0')} của bạn đang được xử lý',
        data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
      );
    }

    // 📝 Log event: ticket assigned
    if (assigneeId != null) {
      final assignee = await AppUser.db.findById(session, assigneeId);
      final assigneeName = assignee?.fullName ?? 'ID $assigneeId';
      await EventEndpoint.logEvent(
        session,
        ticketId: ticketId,
        userId: actionUserId,
        eventType: 'assigned',
        newValue: assigneeName,
        description: 'Yêu cầu đã được phân công xử lý cho chuyên viên: $assigneeName',
      );
    }

    return updated;
  }

  // ── UPDATE STATUS ────────────────────────────────────────────
  /// Update ticket status. Sends context-driven push notifications.
  Future<Ticket?> updateStatus(
    Session session,
    int ticketId,
    int actionUserId,
    String status,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;
    final oldStatus = ticket.status;
    final updated = await Ticket.db.updateRow(
      session, 
      ticket.copyWith(status: status),
      columns: (t) => [t.status],
    );

    // 📝 Log event: status changed
    // userId = 0 vì updateStatus không nhận userId → sẽ log user từ frontend
    String translateStatus(String s) {
      switch (s) {
        case 'Open': return 'Tạo yêu cầu';
        case 'Pending': return 'Đang xử lý';
        case 'Resolved': return 'Đã duyệt';
        case 'WaitingConfirmation': return 'Chờ đóng BA';
        case 'Closed': return 'Đã đóng';
        case 'Cancelled': return 'Đã hủy';
        default: return s;
      }
    }

    await EventEndpoint.logEvent(
      session,
      ticketId: ticketId,
      userId: actionUserId,
      eventType: 'status_changed',
      oldValue: oldStatus,
      newValue: status,
      description: 'Trạng thái của yêu cầu đã được cập nhật từ "${translateStatus(oldStatus)}" sang "${translateStatus(status)}"',
    );

    final isReopenMedical = ticket.ticketType == 'reopen_medical';

    if (isReopenMedical) {
      final affectsFinance = (ticket.description ?? '').contains('Ảnh hưởng tài chính: CÓ');
      final targetPermission = affectsFinance ? 'finance' : 'insurance';

      if (status == 'Resolved') {
        // Đã duyệt -> Báo cho Finance/Insurance
        final approvers = await AppUser.db.find(session, where: (u) => u.permissions.like('%$targetPermission%'));
        for (final user in approvers) {
          await FcmService.sendToUser(
            session,
            targetUserId: user.id!,
            title: '📋 Đang có bệnh án đã duyệt cần mở',
            body: ticket.subject,
            data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
          );
        }
        // Cũng báo cho bác sĩ biết yêu cầu đã được duyệt
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.requesterId,
          title: '🎉 Yêu cầu đã được duyệt',
          body: ticket.subject,
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
      } else if (status == 'Pending') {
        // BH/TC đã mở BA -> Báo cho người tạo (Bác sĩ)
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.requesterId,
          title: '🔓 Bệnh án đã được mở',
          body: 'Vui lòng vào cập nhật hồ sơ: ${ticket.subject}',
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
      } else if (status == 'WaitingConfirmation') {
        // Bác sĩ đã sửa xong -> Báo cho BH/TC vào đóng BA
        final approvers = await AppUser.db.find(session, where: (u) => u.permissions.like('%$targetPermission%'));
        for (final user in approvers) {
          await FcmService.sendToUser(
            session,
            targetUserId: user.id!,
            title: '🔒 Bệnh án đã sửa xong',
            body: 'Vui lòng kiểm tra và đóng bệnh án: ${ticket.subject}',
            data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
          );
        }
      } else if (status == 'Cancelled') {
        // Báo cho người tạo là bị từ chối
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.requesterId,
          title: 'Yêu cầu mở bệnh án đã bị từ chối',
          body: ticket.subject,
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
      }
    } else {
      // ── TICKET IT THÔNG THƯỜNG ──
      // 🔔 In Progress / Pending → notify Customer (requester)
      if (status == 'In Progress' || status == 'Pending') {
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.requesterId,
          title: '👨‍🔧 IT đang xử lý',
          body: 'Yêu cầu của bạn đang được tiến hành: ${ticket.subject}',
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
      }

      // 🔔 WaitingConfirmation → notify Customer (requester)
      if (status == 'WaitingConfirmation') {
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.requesterId,
          title: '✅ IT đã xử lý xong',
          body: 'Vui lòng xác nhận hoàn thành: ${ticket.subject}',
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
      }

      // 🔔 Resolved → notify Customer + IT
      if (status == 'Resolved') {
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.requesterId,
          title: '🎉 Yêu cầu đã được giải quyết',
          body: ticket.subject,
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
        if (ticket.assigneeId != null) {
          await FcmService.sendToUser(
            session,
            targetUserId: ticket.assigneeId!,
            title: '🎉 Ticket đã được xác nhận xong',
            body: '#${ticketId.toString().padLeft(4, '0')}: ${ticket.subject}',
            data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
          );
        }
      }

      // 🔔 Cancelled → notify IT staff (if assigned)
      if (status == 'Cancelled' && ticket.assigneeId != null) {
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.assigneeId!,
          title: 'Ticket đã bị hủy',
          body: '#${ticketId.toString().padLeft(4, '0')}: ${ticket.subject}',
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
      }

      // 🔔 Re-opened → notify IT staff (if assigned)
      if (status == 'Open' && ticket.assigneeId != null) {
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.assigneeId!,
          title: '🔄 Ticket đã bị mở lại',
          body: 'Người dùng vừa yêu cầu mở lại ticket #${ticketId.toString().padLeft(4, '0')}',
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
      }
    }

    return updated;
  }

  /// Update cost difference (used when finance closes medical record)
  Future<Ticket?> updateCostDifference(
    Session session,
    int ticketId,
    int actionUserId,
    double costDifference,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;
    
    final result = await Ticket.db.updateRow(
      session, 
      ticket.copyWith(costDifference: costDifference),
      columns: (t) => [t.costDifference],
    );

    // 📝 Log event: cost updated
    await EventEndpoint.logEvent(
      session,
      ticketId: ticketId,
      userId: actionUserId,
      eventType: 'cost_updated',
      newValue: costDifference.toString(),
      description: 'Hệ thống đã cập nhật mức chênh lệch chi phí: $costDifference',
    );

    return result;
  }

  // ── DEADLINE ─────────────────────────────────────────────────
  /// Propose a deadline for a ticket. Notifies Admins.
  Future<Ticket?> proposeDeadline(
    Session session,
    int ticketId,
    int proposedByUserId,
    DateTime proposedDeadline,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;
    final updated = await Ticket.db.updateRow(
      session,
      ticket.copyWith(
        proposedDeadline: proposedDeadline,
        proposedByUserId: proposedByUserId,
        deadlineStatus: 'Pending',
      ),
      columns: (t) => [t.proposedDeadline, t.proposedByUserId, t.deadlineStatus],
    );

    // 🔔 Notify Admins about proposed deadline
    await FcmService.sendToRole(
      session,
      roleId: 1,
      title: '📅 Đề xuất deadline mới',
      body: '#${ticketId.toString().padLeft(4, '0')}: ${ticket.subject}',
      data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
    );

    // 📝 Log event: deadline proposed
    await EventEndpoint.logEvent(
      session,
      ticketId: ticketId,
      userId: proposedByUserId,
      eventType: 'deadline_proposed',
      newValue: proposedDeadline.toIso8601String(),
      description: 'Một thời hạn xử lý (deadline) mới đã được đề xuất vào ngày: ${proposedDeadline.toIso8601String().substring(0, 10)}',
    );

    return updated;
  }

  /// Admin approves or adjusts a proposed deadline. Notifies Requester.
  Future<Ticket?> approveDeadline(
    Session session,
    int ticketId,
    int actionUserId,
    String action, // 'approve' | 'adjust'
    DateTime? adjustedDeadline,
    String? adminNote,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;

    final finalDeadline =
        action == 'approve' ? ticket.proposedDeadline : adjustedDeadline;
    final deadlineStatus = action == 'approve' ? 'Approved' : 'Adjusted';

    final updated = await Ticket.db.updateRow(
      session,
      ticket.copyWith(
        finalDeadline: finalDeadline,
        deadlineStatus: deadlineStatus,
        adminNote: adminNote,
      ),
      columns: (t) => [t.finalDeadline, t.deadlineStatus, t.adminNote],
    );

    // 🔔 Notify the requester their deadline was approved/adjusted
    final actionLabel = action == 'approve' ? 'đã duyệt' : 'đã điều chỉnh';
    await FcmService.sendToUser(
      session,
      targetUserId: ticket.requesterId,
      title: '📅 Deadline $actionLabel',
      body: '#${ticketId.toString().padLeft(4, '0')}: ${ticket.subject}',
      data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
    );

    // 📝 Log event: deadline approved/adjusted
    await EventEndpoint.logEvent(
      session,
      ticketId: ticketId,
      userId: actionUserId,
      eventType: 'deadline_approved',
      oldValue: ticket.proposedDeadline?.toIso8601String(),
      newValue: finalDeadline?.toIso8601String(),
      description: 'Thời hạn xử lý (deadline) đã được cấp quản lý $actionLabel',
    );

    return updated;
  }

  /// Requester confirms or rejects the approved deadline.
  Future<Ticket?> confirmDeadline(
    Session session,
    int ticketId,
    bool confirmed,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;
    return Ticket.db.updateRow(
      session,
      ticket.copyWith(deadlineStatus: confirmed ? 'Confirmed' : 'Rejected'),
      columns: (t) => [t.deadlineStatus],
    );
  }

  // ── UPDATE TICKET (chỉ cho phép khi Open) ─────────────────────
  /// Update ticket subject, description, patientName. Only allowed when status = 'Open'.
  Future<Ticket?> updateTicketInfo(
    Session session,
    int ticketId,
    String subject,
    String description,
    String? patientName,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;
    if (ticket.status != 'Open') return null; // Chỉ sửa khi chưa duyệt

    return await Ticket.db.updateRow(
      session,
      ticket.copyWith(
        subject: subject,
        description: description,
        patientName: patientName,
      ),
      columns: (t) => [t.subject, t.description, t.patientName],
    );
  }

  // ── DELETE TICKET (chỉ khi chưa duyệt = Open) ──────────────
  /// Delete a ticket and its related data. Only allowed when status = 'Open'.
  Future<bool> deleteTicket(Session session, int ticketId) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return false;
    if (ticket.status != 'Open') return false; // Chỉ xóa ticket chưa duyệt

    // Xóa attachments + comments trước (foreign key)
    await TicketAttachment.db.deleteWhere(
      session,
      where: (a) => a.ticketId.equals(ticketId),
    );
    await TicketComment.db.deleteWhere(
      session,
      where: (c) => c.ticketId.equals(ticketId),
    );
    // 📝 Log event: delete
    await EventEndpoint.logEvent(
      session,
      ticketId: ticketId,
      userId: ticket.requesterId,
      eventType: 'deleted',
      description: 'Yêu cầu này đã bị xóa khỏi hệ thống',
    );

    // Xóa events liên quan
    await TicketEvent.db.deleteWhere(
      session,
      where: (e) => e.ticketId.equals(ticketId),
    );
    // Xóa ticket
    await Ticket.db.deleteRow(session, ticket);
    return true;
  }

  // ── DANGEROUS: CLEAR DB (For testing) ──
  Future<String> clearAllTickets(Session session) async {
    try {
      await TicketEvent.db.deleteWhere(session, where: (e) => Constant.bool(true));
      await TicketAttachment.db.deleteWhere(session, where: (a) => Constant.bool(true));
      await TicketComment.db.deleteWhere(session, where: (c) => Constant.bool(true));
      await Ticket.db.deleteWhere(session, where: (t) => Constant.bool(true));
      return 'Da xoa sach toan bo ticket tren server!';
    } catch (e) {
      return 'Loi xoa du lieu: \$e';
    }
  }
}
