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

abstract class EmergencyContact implements _i1.SerializableModel {
  EmergencyContact._({
    this.id,
    this.userId,
    required this.name,
    required this.phoneNumber,
    this.description,
    required this.sortOrder,
  });

  factory EmergencyContact({
    int? id,
    int? userId,
    required String name,
    required String phoneNumber,
    String? description,
    required int sortOrder,
  }) = _EmergencyContactImpl;

  factory EmergencyContact.fromJson(Map<String, dynamic> jsonSerialization) {
    return EmergencyContact(
      id: jsonSerialization['id'] as int?,
      userId: jsonSerialization['userId'] as int?,
      name: jsonSerialization['name'] as String,
      phoneNumber: jsonSerialization['phoneNumber'] as String,
      description: jsonSerialization['description'] as String?,
      sortOrder: jsonSerialization['sortOrder'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int? userId;

  String name;

  String phoneNumber;

  String? description;

  int sortOrder;

  /// Returns a shallow copy of this [EmergencyContact]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  EmergencyContact copyWith({
    int? id,
    int? userId,
    String? name,
    String? phoneNumber,
    String? description,
    int? sortOrder,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'EmergencyContact',
      if (id != null) 'id': id,
      if (userId != null) 'userId': userId,
      'name': name,
      'phoneNumber': phoneNumber,
      if (description != null) 'description': description,
      'sortOrder': sortOrder,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _EmergencyContactImpl extends EmergencyContact {
  _EmergencyContactImpl({
    int? id,
    int? userId,
    required String name,
    required String phoneNumber,
    String? description,
    required int sortOrder,
  }) : super._(
         id: id,
         userId: userId,
         name: name,
         phoneNumber: phoneNumber,
         description: description,
         sortOrder: sortOrder,
       );

  /// Returns a shallow copy of this [EmergencyContact]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  EmergencyContact copyWith({
    Object? id = _Undefined,
    Object? userId = _Undefined,
    String? name,
    String? phoneNumber,
    Object? description = _Undefined,
    int? sortOrder,
  }) {
    return EmergencyContact(
      id: id is int? ? id : this.id,
      userId: userId is int? ? userId : this.userId,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      description: description is String? ? description : this.description,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
