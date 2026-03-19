import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/fcm_service.dart';

/// Handles ticket comments.
/// Access via `client.comment` on the Flutter client.
class CommentEndpoint extends Endpoint {
  /// Get all comments for a ticket.
  Future<List<TicketComment>> getComments(Session session, int ticketId) async {
    return TicketComment.db.find(
      session,
      where: (c) => c.ticketId.equals(ticketId),
      orderBy: (c) => c.createdAt,
    );
  }

  /// Add a comment to a ticket. Sends push notification to the other party.
  Future<TicketComment> addComment(
    Session session,
    int ticketId,
    int userId,
    String commentText,
  ) async {
    final comment = TicketComment(
      ticketId: ticketId,
      userId: userId,
      commentText: commentText,
      createdAt: DateTime.now().toUtc(),
    );
    final saved = await TicketComment.db.insertRow(session, comment);

    // 🔔 Notify the other party in this ticket
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket != null) {
      final sender = await AppUser.db.findById(session, userId);
      final senderName = sender?.fullName ?? 'Ai đó';
      final preview = commentText.length > 50
          ? '${commentText.substring(0, 50)}...'
          : commentText;

      // If sender is the requester → notify IT assignee and Admin
      if (userId == ticket.requesterId) {
        if (ticket.assigneeId != null) {
          await FcmService.sendToUser(
            session,
            targetUserId: ticket.assigneeId!,
            title: '💬 $senderName đã trả lời',
            body: preview,
            data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
          );
        }
      } else {
        // Sender is IT/Admin → notify requester
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.requesterId,
          title: '💬 IT phản hồi ticket của bạn',
          body: preview,
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );
      }
    }

    return saved;
  }
}
