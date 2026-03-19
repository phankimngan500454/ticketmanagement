// ============================================================
//  attachment_repository.dart
//  Upload / lấy / xóa file đính kèm của ticket
//  Giới hạn: tối đa 5MB / file, encode base64
// ============================================================
import 'repository_base.dart';
import '../models/ticket_attachment.dart';
import '../services/sp_client.dart';

mixin AttachmentRepository on RepositoryBase {
  // ── Lấy danh sách file đính kèm ─────────────────────────────
  Future<List<TicketAttachmentModel>> getAttachments(int ticketId) async {
    final list = await client.attachment.getAttachments(ticketId);
    return list.map(mapAttachment).toList();
  }

  // ── Upload file mới (base64) ─────────────────────────────────
  Future<TicketAttachmentModel> uploadAttachment({
    required int ticketId,
    required int uploaderId,
    required String fileName,
    required String mimeType,
    required String fileData, // base64 encoded
    required int fileSize,
  }) async {
    final a = await client.attachment.uploadAttachment(
        ticketId, uploaderId, fileName, mimeType, fileData, fileSize);
    return mapAttachment(a);
  }

  // ── Xóa file đính kèm ───────────────────────────────────────
  Future<void> deleteAttachment(int attachmentId) async {
    await client.attachment.deleteAttachment(attachmentId);
  }
}
