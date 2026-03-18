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

abstract class TicketAttachment implements _i1.SerializableModel {
  TicketAttachment._({
    this.id,
    required this.ticketId,
    required this.uploaderId,
    required this.fileName,
    required this.mimeType,
    required this.fileData,
    required this.fileSize,
    required this.uploadedAt,
  });

  factory TicketAttachment({
    int? id,
    required int ticketId,
    required int uploaderId,
    required String fileName,
    required String mimeType,
    required String fileData,
    required int fileSize,
    required DateTime uploadedAt,
  }) = _TicketAttachmentImpl;

  factory TicketAttachment.fromJson(Map<String, dynamic> jsonSerialization) {
    return TicketAttachment(
      id: jsonSerialization['id'] as int?,
      ticketId: jsonSerialization['ticketId'] as int,
      uploaderId: jsonSerialization['uploaderId'] as int,
      fileName: jsonSerialization['fileName'] as String,
      mimeType: jsonSerialization['mimeType'] as String,
      fileData: jsonSerialization['fileData'] as String,
      fileSize: jsonSerialization['fileSize'] as int,
      uploadedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['uploadedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int ticketId;

  int uploaderId;

  String fileName;

  String mimeType;

  String fileData;

  int fileSize;

  DateTime uploadedAt;

  /// Returns a shallow copy of this [TicketAttachment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TicketAttachment copyWith({
    int? id,
    int? ticketId,
    int? uploaderId,
    String? fileName,
    String? mimeType,
    String? fileData,
    int? fileSize,
    DateTime? uploadedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TicketAttachment',
      if (id != null) 'id': id,
      'ticketId': ticketId,
      'uploaderId': uploaderId,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileData': fileData,
      'fileSize': fileSize,
      'uploadedAt': uploadedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TicketAttachmentImpl extends TicketAttachment {
  _TicketAttachmentImpl({
    int? id,
    required int ticketId,
    required int uploaderId,
    required String fileName,
    required String mimeType,
    required String fileData,
    required int fileSize,
    required DateTime uploadedAt,
  }) : super._(
         id: id,
         ticketId: ticketId,
         uploaderId: uploaderId,
         fileName: fileName,
         mimeType: mimeType,
         fileData: fileData,
         fileSize: fileSize,
         uploadedAt: uploadedAt,
       );

  /// Returns a shallow copy of this [TicketAttachment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TicketAttachment copyWith({
    Object? id = _Undefined,
    int? ticketId,
    int? uploaderId,
    String? fileName,
    String? mimeType,
    String? fileData,
    int? fileSize,
    DateTime? uploadedAt,
  }) {
    return TicketAttachment(
      id: id is int? ? id : this.id,
      ticketId: ticketId ?? this.ticketId,
      uploaderId: uploaderId ?? this.uploaderId,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileData: fileData ?? this.fileData,
      fileSize: fileSize ?? this.fileSize,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}
