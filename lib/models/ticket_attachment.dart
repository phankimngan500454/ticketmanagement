/// Local model for ticket attachments (maps to TicketAttachment Serverpod model).
class TicketAttachmentModel {
  final int id;
  final int ticketId;
  final int uploaderId;
  final String fileName;
  final String mimeType;
  final String fileData; // base64
  final int fileSize;
  final DateTime uploadedAt;

  const TicketAttachmentModel({
    required this.id,
    required this.ticketId,
    required this.uploaderId,
    required this.fileName,
    required this.mimeType,
    required this.fileData,
    required this.fileSize,
    required this.uploadedAt,
  });

  bool get isImage => mimeType.startsWith('image/');
  bool get isPdf => mimeType == 'application/pdf';

  String get fileSizeLabel {
    if (fileSize < 1024) return '${fileSize}B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB';
  }
}
