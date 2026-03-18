import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

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

  /// Add a comment to a ticket.
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
    return TicketComment.db.insertRow(session, comment);
  }
}
