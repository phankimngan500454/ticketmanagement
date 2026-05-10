/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class TicketEvent implements _i1.SerializableModel {
  TicketEvent._({
    this.id,
    required this.ticketId,
    required this.userId,
    required this.eventType,
    this.oldValue,
    this.newValue,
    this.description,
    required this.createdAt,
  });

  factory TicketEvent({
    int? id,
    required int ticketId,
    required int userId,
    required String eventType,
    String? oldValue,
    String? newValue,
    String? description,
    required DateTime createdAt,
  }) = _TicketEventImpl;

  factory TicketEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return TicketEvent(
      id: jsonSerialization['id'] as int?,
      ticketId: jsonSerialization['ticketId'] as int,
      userId: jsonSerialization['userId'] as int,
      eventType: jsonSerialization['eventType'] as String,
      oldValue: jsonSerialization['oldValue'] as String?,
      newValue: jsonSerialization['newValue'] as String?,
      description: jsonSerialization['description'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int ticketId;

  int userId;

  String eventType;

  String? oldValue;

  String? newValue;

  String? description;

  DateTime createdAt;

  /// Returns a shallow copy of this [TicketEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TicketEvent copyWith({
    int? id,
    int? ticketId,
    int? userId,
    String? eventType,
    String? oldValue,
    String? newValue,
    String? description,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TicketEvent',
      if (id != null) 'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'eventType': eventType,
      if (oldValue != null) 'oldValue': oldValue,
      if (newValue != null) 'newValue': newValue,
      if (description != null) 'description': description,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TicketEventImpl extends TicketEvent {
  _TicketEventImpl({
    int? id,
    required int ticketId,
    required int userId,
    required String eventType,
    String? oldValue,
    String? newValue,
    String? description,
    required DateTime createdAt,
  }) : super._(
         id: id,
         ticketId: ticketId,
         userId: userId,
         eventType: eventType,
         oldValue: oldValue,
         newValue: newValue,
         description: description,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TicketEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TicketEvent copyWith({
    Object? id = _Undefined,
    int? ticketId,
    int? userId,
    String? eventType,
    Object? oldValue = _Undefined,
    Object? newValue = _Undefined,
    Object? description = _Undefined,
    DateTime? createdAt,
  }) {
    return TicketEvent(
      id: id is int? ? id : this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      eventType: eventType ?? this.eventType,
      oldValue: oldValue is String? ? oldValue : this.oldValue,
      newValue: newValue is String? ? newValue : this.newValue,
      description: description is String? ? description : this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
