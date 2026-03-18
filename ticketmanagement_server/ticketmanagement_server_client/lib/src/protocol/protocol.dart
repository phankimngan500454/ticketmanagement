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
import 'app_user.dart' as _i2;
import 'asset.dart' as _i3;
import 'category.dart' as _i4;
import 'department.dart' as _i5;
import 'emergency_contact.dart' as _i6;
import 'greetings/greeting.dart' as _i7;
import 'ticket.dart' as _i8;
import 'ticket_attachment.dart' as _i9;
import 'ticket_comment.dart' as _i10;
import 'package:ticketmanagement_server_client/src/protocol/ticket_attachment.dart'
    as _i11;
import 'package:ticketmanagement_server_client/src/protocol/app_user.dart'
    as _i12;
import 'package:ticketmanagement_server_client/src/protocol/ticket_comment.dart'
    as _i13;
import 'package:ticketmanagement_server_client/src/protocol/category.dart'
    as _i14;
import 'package:ticketmanagement_server_client/src/protocol/asset.dart' as _i15;
import 'package:ticketmanagement_server_client/src/protocol/department.dart'
    as _i16;
import 'package:ticketmanagement_server_client/src/protocol/emergency_contact.dart'
    as _i17;
import 'package:ticketmanagement_server_client/src/protocol/ticket.dart'
    as _i18;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i19;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i20;
export 'app_user.dart';
export 'asset.dart';
export 'category.dart';
export 'department.dart';
export 'emergency_contact.dart';
export 'greetings/greeting.dart';
export 'ticket.dart';
export 'ticket_attachment.dart';
export 'ticket_comment.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.AppUser) {
      return _i2.AppUser.fromJson(data) as T;
    }
    if (t == _i3.Asset) {
      return _i3.Asset.fromJson(data) as T;
    }
    if (t == _i4.Category) {
      return _i4.Category.fromJson(data) as T;
    }
    if (t == _i5.Department) {
      return _i5.Department.fromJson(data) as T;
    }
    if (t == _i6.EmergencyContact) {
      return _i6.EmergencyContact.fromJson(data) as T;
    }
    if (t == _i7.Greeting) {
      return _i7.Greeting.fromJson(data) as T;
    }
    if (t == _i8.Ticket) {
      return _i8.Ticket.fromJson(data) as T;
    }
    if (t == _i9.TicketAttachment) {
      return _i9.TicketAttachment.fromJson(data) as T;
    }
    if (t == _i10.TicketComment) {
      return _i10.TicketComment.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.AppUser?>()) {
      return (data != null ? _i2.AppUser.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Asset?>()) {
      return (data != null ? _i3.Asset.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Category?>()) {
      return (data != null ? _i4.Category.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.Department?>()) {
      return (data != null ? _i5.Department.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.EmergencyContact?>()) {
      return (data != null ? _i6.EmergencyContact.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Greeting?>()) {
      return (data != null ? _i7.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Ticket?>()) {
      return (data != null ? _i8.Ticket.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.TicketAttachment?>()) {
      return (data != null ? _i9.TicketAttachment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.TicketComment?>()) {
      return (data != null ? _i10.TicketComment.fromJson(data) : null) as T;
    }
    if (t == List<_i11.TicketAttachment>) {
      return (data as List)
              .map((e) => deserialize<_i11.TicketAttachment>(e))
              .toList()
          as T;
    }
    if (t == List<_i12.AppUser>) {
      return (data as List).map((e) => deserialize<_i12.AppUser>(e)).toList()
          as T;
    }
    if (t == List<_i13.TicketComment>) {
      return (data as List)
              .map((e) => deserialize<_i13.TicketComment>(e))
              .toList()
          as T;
    }
    if (t == List<_i14.Category>) {
      return (data as List).map((e) => deserialize<_i14.Category>(e)).toList()
          as T;
    }
    if (t == List<_i15.Asset>) {
      return (data as List).map((e) => deserialize<_i15.Asset>(e)).toList()
          as T;
    }
    if (t == List<_i16.Department>) {
      return (data as List).map((e) => deserialize<_i16.Department>(e)).toList()
          as T;
    }
    if (t == List<_i17.EmergencyContact>) {
      return (data as List)
              .map((e) => deserialize<_i17.EmergencyContact>(e))
              .toList()
          as T;
    }
    if (t == List<_i18.Ticket>) {
      return (data as List).map((e) => deserialize<_i18.Ticket>(e)).toList()
          as T;
    }
    try {
      return _i19.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i20.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.AppUser => 'AppUser',
      _i3.Asset => 'Asset',
      _i4.Category => 'Category',
      _i5.Department => 'Department',
      _i6.EmergencyContact => 'EmergencyContact',
      _i7.Greeting => 'Greeting',
      _i8.Ticket => 'Ticket',
      _i9.TicketAttachment => 'TicketAttachment',
      _i10.TicketComment => 'TicketComment',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst(
        'ticketmanagement_server.',
        '',
      );
    }

    switch (data) {
      case _i2.AppUser():
        return 'AppUser';
      case _i3.Asset():
        return 'Asset';
      case _i4.Category():
        return 'Category';
      case _i5.Department():
        return 'Department';
      case _i6.EmergencyContact():
        return 'EmergencyContact';
      case _i7.Greeting():
        return 'Greeting';
      case _i8.Ticket():
        return 'Ticket';
      case _i9.TicketAttachment():
        return 'TicketAttachment';
      case _i10.TicketComment():
        return 'TicketComment';
    }
    className = _i19.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i20.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'AppUser') {
      return deserialize<_i2.AppUser>(data['data']);
    }
    if (dataClassName == 'Asset') {
      return deserialize<_i3.Asset>(data['data']);
    }
    if (dataClassName == 'Category') {
      return deserialize<_i4.Category>(data['data']);
    }
    if (dataClassName == 'Department') {
      return deserialize<_i5.Department>(data['data']);
    }
    if (dataClassName == 'EmergencyContact') {
      return deserialize<_i6.EmergencyContact>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i7.Greeting>(data['data']);
    }
    if (dataClassName == 'Ticket') {
      return deserialize<_i8.Ticket>(data['data']);
    }
    if (dataClassName == 'TicketAttachment') {
      return deserialize<_i9.TicketAttachment>(data['data']);
    }
    if (dataClassName == 'TicketComment') {
      return deserialize<_i10.TicketComment>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i19.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i20.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i19.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i20.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
