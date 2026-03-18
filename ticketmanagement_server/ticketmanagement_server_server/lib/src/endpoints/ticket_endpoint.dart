import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

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
      return Ticket.db.find(
        session,
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } else if (roleId == 2) {
      return Ticket.db.find(
        session,
        where: (t) => t.assigneeId.equals(userId),
        orderBy: (t) => t.createdAt,
        orderDescending: true,
      );
    } else {
      return Ticket.db.find(
        session,
        where: (t) => t.requesterId.equals(userId),
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

  /// Create a new ticket.
  Future<Ticket> createTicket(
    Session session,
    int requesterId,
    int categoryId,
    String subject,
    String description,
    String priority,
    int? assetId,
  ) async {
    final ticket = Ticket(
      subject: subject,
      description: description,
      status: 'Open',
      priority: priority,
      createdAt: DateTime.now().toUtc(),
      requesterId: requesterId,
      categoryId: categoryId,
      assetId: assetId,
    );
    return Ticket.db.insertRow(session, ticket);
  }

  /// Assign (or unassign) a ticket to an IT staff member.
  Future<Ticket?> assignTicket(
    Session session,
    int ticketId,
    int? assigneeId,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;

    final newStatus =
        assigneeId != null && ticket.status == 'Open' ? 'Pending' : ticket.status;

    return Ticket.db.updateRow(
      session,
      ticket.copyWith(assigneeId: assigneeId, status: newStatus),
    );
  }

  /// Update ticket status.
  Future<Ticket?> updateStatus(
    Session session,
    int ticketId,
    String status,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;
    return Ticket.db.updateRow(session, ticket.copyWith(status: status));
  }

  /// Propose a deadline for a ticket.
  Future<Ticket?> proposeDeadline(
    Session session,
    int ticketId,
    int proposedByUserId,
    DateTime proposedDeadline,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;
    return Ticket.db.updateRow(
      session,
      ticket.copyWith(
        proposedDeadline: proposedDeadline,
        proposedByUserId: proposedByUserId,
        deadlineStatus: 'Pending',
      ),
    );
  }

  /// Admin approves or adjusts a proposed deadline.
  Future<Ticket?> approveDeadline(
    Session session,
    int ticketId,
    String action, // 'approve' | 'adjust'
    DateTime? adjustedDeadline,
    String? adminNote,
  ) async {
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket == null) return null;

    final finalDeadline =
        action == 'approve' ? ticket.proposedDeadline : adjustedDeadline;
    final deadlineStatus = action == 'approve' ? 'Approved' : 'Adjusted';

    return Ticket.db.updateRow(
      session,
      ticket.copyWith(
        finalDeadline: finalDeadline,
        deadlineStatus: deadlineStatus,
        adminNote: adminNote,
      ),
    );
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
    );
  }
}
