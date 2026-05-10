import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

/// Handles ticket event log (activity history).
/// Access via `client.event` on the Flutter client.
class EventEndpoint extends Endpoint {
  /// Get all events for a ticket, ordered by createdAt ascending.
  Future<List<TicketEvent>> getEvents(Session session, int ticketId) async {
    return TicketEvent.db.find(
      session,
      where: (e) => e.ticketId.equals(ticketId),
      orderBy: (e) => e.createdAt,
    );
  }

  /// Helper: log an event for a ticket.
  /// Called internally from other endpoints.
  static Future<void> logEvent(
    Session session, {
    required int ticketId,
    required int userId,
    required String eventType,
    String? oldValue,
    String? newValue,
    String? description,
  }) async {
    final event = TicketEvent(
      ticketId: ticketId,
      userId: userId,
      eventType: eventType,
      oldValue: oldValue,
      newValue: newValue,
      description: description,
      createdAt: DateTime.now().toUtc(),
    );
    await TicketEvent.db.insertRow(session, event);
  }
}
