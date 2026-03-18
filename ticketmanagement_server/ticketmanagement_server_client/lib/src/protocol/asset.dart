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

abstract class Asset implements _i1.SerializableModel {
  Asset._({
    this.id,
    required this.assetName,
    this.assetType,
    this.serialNumber,
    this.categoryId,
    this.assetGroup,
    this.assetModel,
  });

  factory Asset({
    int? id,
    required String assetName,
    String? assetType,
    String? serialNumber,
    int? categoryId,
    String? assetGroup,
    String? assetModel,
  }) = _AssetImpl;

  factory Asset.fromJson(Map<String, dynamic> jsonSerialization) {
    return Asset(
      id: jsonSerialization['id'] as int?,
      assetName: jsonSerialization['assetName'] as String,
      assetType: jsonSerialization['assetType'] as String?,
      serialNumber: jsonSerialization['serialNumber'] as String?,
      categoryId: jsonSerialization['categoryId'] as int?,
      assetGroup: jsonSerialization['assetGroup'] as String?,
      assetModel: jsonSerialization['assetModel'] as String?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String assetName;

  String? assetType;

  String? serialNumber;

  int? categoryId;

  String? assetGroup;

  String? assetModel;

  /// Returns a shallow copy of this [Asset]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Asset copyWith({
    int? id,
    String? assetName,
    String? assetType,
    String? serialNumber,
    int? categoryId,
    String? assetGroup,
    String? assetModel,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Asset',
      if (id != null) 'id': id,
      'assetName': assetName,
      if (assetType != null) 'assetType': assetType,
      if (serialNumber != null) 'serialNumber': serialNumber,
      if (categoryId != null) 'categoryId': categoryId,
      if (assetGroup != null) 'assetGroup': assetGroup,
      if (assetModel != null) 'assetModel': assetModel,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AssetImpl extends Asset {
  _AssetImpl({
    int? id,
    required String assetName,
    String? assetType,
    String? serialNumber,
    int? categoryId,
    String? assetGroup,
    String? assetModel,
  }) : super._(
         id: id,
         assetName: assetName,
         assetType: assetType,
         serialNumber: serialNumber,
         categoryId: categoryId,
         assetGroup: assetGroup,
         assetModel: assetModel,
       );

  /// Returns a shallow copy of this [Asset]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Asset copyWith({
    Object? id = _Undefined,
    String? assetName,
    Object? assetType = _Undefined,
    Object? serialNumber = _Undefined,
    Object? categoryId = _Undefined,
    Object? assetGroup = _Undefined,
    Object? assetModel = _Undefined,
  }) {
    return Asset(
      id: id is int? ? id : this.id,
      assetName: assetName ?? this.assetName,
      assetType: assetType is String? ? assetType : this.assetType,
      serialNumber: serialNumber is String? ? serialNumber : this.serialNumber,
      categoryId: categoryId is int? ? categoryId : this.categoryId,
      assetGroup: assetGroup is String? ? assetGroup : this.assetGroup,
      assetModel: assetModel is String? ? assetModel : this.assetModel,
    );
  }
}
