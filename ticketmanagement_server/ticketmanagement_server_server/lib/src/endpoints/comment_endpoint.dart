import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/fcm_service.dart';
import 'event_endpoint.dart';

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

    // 📝 Log event: comment added
    final preview = commentText.length > 40
        ? '${commentText.substring(0, 40)}...'
        : commentText;
    await EventEndpoint.logEvent(
      session,
      ticketId: ticketId,
      userId: userId,
      eventType: 'commented',
      description: 'Đã thêm một bình luận mới: "$preview"',
    );

    // 🔔 Notify the other party in this ticket
    final ticket = await Ticket.db.findById(session, ticketId);
    if (ticket != null) {
      final sender = await AppUser.db.findById(session, userId);
      final senderName = sender?.fullName ?? 'Ai đó';
      final preview = commentText.length > 50
          ? '${commentText.substring(0, 50)}...'
          : commentText;

      // If sender is the requester -> notify people handling it
      if (userId == ticket.requesterId) {
        if ((ticket.ticketType ?? 'ticket') == 'feedback' || (ticket.ticketType ?? 'ticket') == 'reopen_medical') {
          await FcmService.sendToRole(
            session,
            roleId: 4, // Manager
            title: '💬 $senderName đã thêm phản hồi',
            body: preview,
            data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
          );
        } else {
          if (ticket.assigneeId != null) {
            await FcmService.sendToUser(
              session,
              targetUserId: ticket.assigneeId!,
              title: '💬 $senderName đã trả lời',
              body: preview,
              data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
            );
          } else {
            await FcmService.sendToRole(
              session,
              roleId: 1, // Admin
              title: '💬 $senderName đã thêm bình luận',
              body: preview,
              data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
            );
            await FcmService.sendToRole(
              session,
              roleId: 2, // IT
              title: '💬 $senderName đã thêm bình luận',
              body: preview,
              data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
            );
          }
        }
      } else {
        // Sender is someone else (Admin/IT/Manager) -> notify requester
        await FcmService.sendToUser(
          session,
          targetUserId: ticket.requesterId,
          title: '💬 $senderName đã phản hồi',
          body: preview,
          data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
        );

        // Also notify assignee if the sender is not the assignee
        if (ticket.assigneeId != null && userId != ticket.assigneeId) {
          await FcmService.sendToUser(
            session,
            targetUserId: ticket.assigneeId!,
            title: '💬 $senderName đã bình luận vào ticket',
            body: preview,
            data: {'ticketId': '$ticketId', 'screen': 'ticket_detail'},
          );
        }
      }
    }

    return saved;
  }
}
