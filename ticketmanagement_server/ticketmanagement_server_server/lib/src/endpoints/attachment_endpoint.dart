import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Handles file attachment CRUD for tickets.
/// Files stored as base64 strings in DB.
class AttachmentEndpoint extends Endpoint {
  /// Upload a file attachment for a ticket.
  Future<TicketAttachment> uploadAttachment(
    Session session,
    int ticketId,
    int uploaderId,
    String fileName,
    String mimeType,
    String fileData, // base64
    int fileSize,
  ) async {
    final attachment = TicketAttachment(
      ticketId: ticketId,
      uploaderId: uploaderId,
      fileName: fileName,
      mimeType: mimeType,
      fileData: fileData,
      fileSize: fileSize,
      uploadedAt: DateTime.now().toUtc(),
    );
    return TicketAttachment.db.insertRow(session, attachment);
  }

  /// Get all attachments for a ticket.
  Future<List<TicketAttachment>> getAttachments(
    Session session,
    int ticketId,
  ) async {
    return TicketAttachment.db.find(
      session,
      where: (a) => a.ticketId.equals(ticketId),
      orderBy: (a) => a.uploadedAt,
    );
  }

  /// Delete an attachment by ID.
  Future<void> deleteAttachment(Session session, int attachmentId) async {
    final a = await TicketAttachment.db.findById(session, attachmentId);
    if (a != null) await TicketAttachment.db.deleteRow(session, a);
  }
}
