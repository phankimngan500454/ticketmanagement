// ============================================================
//  comment_repository.dart
//  Lấy và gửi bình luận / tin nhắn trong ticket
// ============================================================
import 'repository_base.dart';
import '../models/ticket_comment.dart';
import '../services/sp_client.dart';

mixin CommentRepository on RepositoryBase {
  // ── Lấy danh sách bình luận của ticket ──────────────────────
  Future<List<TicketComment>> getComments(int ticketId) async {
    await warmCache();
    final raw = await client.comment.getComments(ticketId);
    return raw.map(mapComment).toList();
  }

  // ── Gửi bình luận mới ───────────────────────────────────────
  Future<TicketComment> addComment({
    required int ticketId,
    required int userId,
    String? authorName,
    String? authorRole,
    required String commentText,
  }) async {
    await warmCache();
    final c = await client.comment.addComment(ticketId, userId, commentText);
    return mapComment(c);
  }
}
