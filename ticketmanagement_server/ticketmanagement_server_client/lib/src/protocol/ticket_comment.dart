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

abstract class TicketComment implements _i1.SerializableModel {
  TicketComment._({
    this.id,
    required this.ticketId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
  });

  factory TicketComment({
    int? id,
    required int ticketId,
    required int userId,
    required String commentText,
    required DateTime createdAt,
  }) = _TicketCommentImpl;

  factory TicketComment.fromJson(Map<String, dynamic> jsonSerialization) {
    return TicketComment(
      id: jsonSerialization['id'] as int?,
      ticketId: jsonSerialization['ticketId'] as int,
      userId: jsonSerialization['userId'] as int,
      commentText: jsonSerialization['commentText'] as String,
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

  String commentText;

  DateTime createdAt;

  /// Returns a shallow copy of this [TicketComment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TicketComment copyWith({
    int? id,
    int? ticketId,
    int? userId,
    String? commentText,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TicketComment',
      if (id != null) 'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'commentText': commentText,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TicketCommentImpl extends TicketComment {
  _TicketCommentImpl({
    int? id,
    required int ticketId,
    required int userId,
    required String commentText,
    required DateTime createdAt,
  }) : super._(
         id: id,
         ticketId: ticketId,
         userId: userId,
         commentText: commentText,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TicketComment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TicketComment copyWith({
    Object? id = _Undefined,
    int? ticketId,
    int? userId,
    String? commentText,
    DateTime? createdAt,
  }) {
    return TicketComment(
      id: id is int? ? id : this.id,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      commentText: commentText ?? this.commentText,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
