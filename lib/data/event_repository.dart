// ignore_for_file: avoid_print
// ============================================================
//  event_repository.dart
//  Mixin: lấy nhật ký sự kiện (event log) cho ticket
// ============================================================

import '../models/ticket_event.dart';
import '../services/sp_client.dart';
import 'repository_base.dart';

mixin EventRepository on RepositoryBase {
  /// Fetch all events for a ticket, ordered by createdAt ascending.
  Future<List<TicketEvent>> getEvents(int ticketId) async {
    try {
      await warmCache();
      final spEvents = await client.event.getEvents(ticketId);
      return spEvents.map(mapEvent).toList();
    } catch (e) {
      print('[EventRepository] getEvents error: $e');
      return [];
    }
  }
}
