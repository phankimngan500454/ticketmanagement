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

abstract class Ticket implements _i1.SerializableModel {
  Ticket._({
    this.id,
    required this.subject,
    this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.requesterId,
    this.assigneeId,
    required this.categoryId,
    this.assetId,
    this.proposedDeadline,
    this.finalDeadline,
    this.deadlineStatus,
    this.adminNote,
    this.proposedByUserId,
  });

  factory Ticket({
    int? id,
    required String subject,
    String? description,
    required String status,
    required String priority,
    required DateTime createdAt,
    required int requesterId,
    int? assigneeId,
    required int categoryId,
    int? assetId,
    DateTime? proposedDeadline,
    DateTime? finalDeadline,
    String? deadlineStatus,
    String? adminNote,
    int? proposedByUserId,
  }) = _TicketImpl;

  factory Ticket.fromJson(Map<String, dynamic> jsonSerialization) {
    return Ticket(
      id: jsonSerialization['id'] as int?,
      subject: jsonSerialization['subject'] as String,
      description: jsonSerialization['description'] as String?,
      status: jsonSerialization['status'] as String,
      priority: jsonSerialization['priority'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      requesterId: jsonSerialization['requesterId'] as int,
      assigneeId: jsonSerialization['assigneeId'] as int?,
      categoryId: jsonSerialization['categoryId'] as int,
      assetId: jsonSerialization['assetId'] as int?,
      proposedDeadline: jsonSerialization['proposedDeadline'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['proposedDeadline'],
            ),
      finalDeadline: jsonSerialization['finalDeadline'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['finalDeadline'],
            ),
      deadlineStatus: jsonSerialization['deadlineStatus'] as String?,
      adminNote: jsonSerialization['adminNote'] as String?,
      proposedByUserId: jsonSerialization['proposedByUserId'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String subject;

  String? description;

  String status;

  String priority;

  DateTime createdAt;

  int requesterId;

  int? assigneeId;

  int categoryId;

  int? assetId;

  DateTime? proposedDeadline;

  DateTime? finalDeadline;

  String? deadlineStatus;

  String? adminNote;

  int? proposedByUserId;

  /// Returns a shallow copy of this [Ticket]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Ticket copyWith({
    int? id,
    String? subject,
    String? description,
    String? status,
    String? priority,
    DateTime? createdAt,
    int? requesterId,
    int? assigneeId,
    int? categoryId,
    int? assetId,
    DateTime? proposedDeadline,
    DateTime? finalDeadline,
    String? deadlineStatus,
    String? adminNote,
    int? proposedByUserId,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Ticket',
      if (id != null) 'id': id,
      'subject': subject,
      if (description != null) 'description': description,
      'status': status,
      'priority': priority,
      'createdAt': createdAt.toJson(),
      'requesterId': requesterId,
      if (assigneeId != null) 'assigneeId': assigneeId,
      'categoryId': categoryId,
      if (assetId != null) 'assetId': assetId,
      if (proposedDeadline != null)
        'proposedDeadline': proposedDeadline?.toJson(),
      if (finalDeadline != null) 'finalDeadline': finalDeadline?.toJson(),
      if (deadlineStatus != null) 'deadlineStatus': deadlineStatus,
      if (adminNote != null) 'adminNote': adminNote,
      if (proposedByUserId != null) 'proposedByUserId': proposedByUserId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TicketImpl extends Ticket {
  _TicketImpl({
    int? id,
    required String subject,
    String? description,
    required String status,
    required String priority,
    required DateTime createdAt,
    required int requesterId,
    int? assigneeId,
    required int categoryId,
    int? assetId,
    DateTime? proposedDeadline,
    DateTime? finalDeadline,
    String? deadlineStatus,
    String? adminNote,
    int? proposedByUserId,
  }) : super._(
         id: id,
         subject: subject,
         description: description,
         status: status,
         priority: priority,
         createdAt: createdAt,
         requesterId: requesterId,
         assigneeId: assigneeId,
         categoryId: categoryId,
         assetId: assetId,
         proposedDeadline: proposedDeadline,
         finalDeadline: finalDeadline,
         deadlineStatus: deadlineStatus,
         adminNote: adminNote,
         proposedByUserId: proposedByUserId,
       );

  /// Returns a shallow copy of this [Ticket]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Ticket copyWith({
    Object? id = _Undefined,
    String? subject,
    Object? description = _Undefined,
    String? status,
    String? priority,
    DateTime? createdAt,
    int? requesterId,
    Object? assigneeId = _Undefined,
    int? categoryId,
    Object? assetId = _Undefined,
    Object? proposedDeadline = _Undefined,
    Object? finalDeadline = _Undefined,
    Object? deadlineStatus = _Undefined,
    Object? adminNote = _Undefined,
    Object? proposedByUserId = _Undefined,
  }) {
    return Ticket(
      id: id is int? ? id : this.id,
      subject: subject ?? this.subject,
      description: description is String? ? description : this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      requesterId: requesterId ?? this.requesterId,
      assigneeId: assigneeId is int? ? assigneeId : this.assigneeId,
      categoryId: categoryId ?? this.categoryId,
      assetId: assetId is int? ? assetId : this.assetId,
      proposedDeadline: proposedDeadline is DateTime?
          ? proposedDeadline
          : this.proposedDeadline,
      finalDeadline: finalDeadline is DateTime?
          ? finalDeadline
          : this.finalDeadline,
      deadlineStatus: deadlineStatus is String?
          ? deadlineStatus
          : this.deadlineStatus,
      adminNote: adminNote is String? ? adminNote : this.adminNote,
      proposedByUserId: proposedByUserId is int?
          ? proposedByUserId
          : this.proposedByUserId,
    );
  }
}
