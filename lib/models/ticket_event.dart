// ============================================================
//  ticket_event.dart — Flutter app model for TicketEvent
//  Maps from Serverpod TicketEvent to a local model with
//  the actor's display name resolved from userCache.
// ============================================================

class TicketEvent {
  final int eventId;
  final int ticketId;
  final int userId;
  final String eventType;
  final String? oldValue;
  final String? newValue;
  final String? description;
  final DateTime createdAt;
  final String? userName; // resolved from userCache

  TicketEvent({
    required this.eventId,
    required this.ticketId,
    required this.userId,
    required this.eventType,
    this.oldValue,
    this.newValue,
    this.description,
    required this.createdAt,
    this.userName,
  });
}
