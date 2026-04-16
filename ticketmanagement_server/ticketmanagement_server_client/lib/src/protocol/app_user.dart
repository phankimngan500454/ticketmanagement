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

abstract class AppUser implements _i1.SerializableModel {
  AppUser._({
    this.id,
    required this.username,
    required this.passwordHash,
    this.fullName,
    this.phone,
    required this.roleId,
    required this.createdAt,
    this.deptId,
    this.fcmToken,
    this.permissions,
  });

  factory AppUser({
    int? id,
    required String username,
    required String passwordHash,
    String? fullName,
    String? phone,
    required int roleId,
    required DateTime createdAt,
    int? deptId,
    String? fcmToken,
    String? permissions,
  }) = _AppUserImpl;

  factory AppUser.fromJson(Map<String, dynamic> jsonSerialization) {
    return AppUser(
      id: jsonSerialization['id'] as int?,
      username: jsonSerialization['username'] as String,
      passwordHash: jsonSerialization['passwordHash'] as String,
      fullName: jsonSerialization['fullName'] as String?,
      phone: jsonSerialization['phone'] as String?,
      roleId: jsonSerialization['roleId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      deptId: jsonSerialization['deptId'] as int?,
      fcmToken: jsonSerialization['fcmToken'] as String?,
      permissions: jsonSerialization['permissions'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String username;

  String passwordHash;

  String? fullName;

  String? phone;

  int roleId;

  DateTime createdAt;

  int? deptId;

  String? fcmToken;

  String? permissions;

  /// Returns a shallow copy of this [AppUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AppUser copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? fullName,
    String? phone,
    int? roleId,
    DateTime? createdAt,
    int? deptId,
    String? fcmToken,
    String? permissions,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AppUser',
      if (id != null) 'id': id,
      'username': username,
      'passwordHash': passwordHash,
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      'roleId': roleId,
      'createdAt': createdAt.toJson(),
      if (deptId != null) 'deptId': deptId,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (permissions != null) 'permissions': permissions,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AppUserImpl extends AppUser {
  _AppUserImpl({
    int? id,
    required String username,
    required String passwordHash,
    String? fullName,
    String? phone,
    required int roleId,
    required DateTime createdAt,
    int? deptId,
    String? fcmToken,
    String? permissions,
  }) : super._(
         id: id,
         username: username,
         passwordHash: passwordHash,
         fullName: fullName,
         phone: phone,
         roleId: roleId,
         createdAt: createdAt,
         deptId: deptId,
         fcmToken: fcmToken,
         permissions: permissions,
       );

  /// Returns a shallow copy of this [AppUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AppUser copyWith({
    Object? id = _Undefined,
    String? username,
    String? passwordHash,
    Object? fullName = _Undefined,
    Object? phone = _Undefined,
    int? roleId,
    DateTime? createdAt,
    Object? deptId = _Undefined,
    Object? fcmToken = _Undefined,
    Object? permissions = _Undefined,
  }) {
    return AppUser(
      id: id is int? ? id : this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      fullName: fullName is String? ? fullName : this.fullName,
      phone: phone is String? ? phone : this.phone,
      roleId: roleId ?? this.roleId,
      createdAt: createdAt ?? this.createdAt,
      deptId: deptId is int? ? deptId : this.deptId,
      fcmToken: fcmToken is String? ? fcmToken : this.fcmToken,
      permissions: permissions is String? ? permissions : this.permissions,
    );
  }
}
