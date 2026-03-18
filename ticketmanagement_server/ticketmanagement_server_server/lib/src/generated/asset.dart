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
import 'package:serverpod/serverpod.dart' as _i1;

abstract class Asset implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = AssetTable();

  static const db = AssetRepository._();

  @override
  int? id;

  String assetName;

  String? assetType;

  String? serialNumber;

  int? categoryId;

  String? assetGroup;

  String? assetModel;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static AssetInclude include() {
    return AssetInclude._();
  }

  static AssetIncludeList includeList({
    _i1.WhereExpressionBuilder<AssetTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AssetTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AssetTable>? orderByList,
    AssetInclude? include,
  }) {
    return AssetIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Asset.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Asset.t),
      include: include,
    );
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

class AssetUpdateTable extends _i1.UpdateTable<AssetTable> {
  AssetUpdateTable(super.table);

  _i1.ColumnValue<String, String> assetName(String value) => _i1.ColumnValue(
    table.assetName,
    value,
  );

  _i1.ColumnValue<String, String> assetType(String? value) => _i1.ColumnValue(
    table.assetType,
    value,
  );

  _i1.ColumnValue<String, String> serialNumber(String? value) =>
      _i1.ColumnValue(
        table.serialNumber,
        value,
      );

  _i1.ColumnValue<int, int> categoryId(int? value) => _i1.ColumnValue(
    table.categoryId,
    value,
  );

  _i1.ColumnValue<String, String> assetGroup(String? value) => _i1.ColumnValue(
    table.assetGroup,
    value,
  );

  _i1.ColumnValue<String, String> assetModel(String? value) => _i1.ColumnValue(
    table.assetModel,
    value,
  );
}

class AssetTable extends _i1.Table<int?> {
  AssetTable({super.tableRelation}) : super(tableName: 'assets') {
    updateTable = AssetUpdateTable(this);
    assetName = _i1.ColumnString(
      'assetName',
      this,
    );
    assetType = _i1.ColumnString(
      'assetType',
      this,
    );
    serialNumber = _i1.ColumnString(
      'serialNumber',
      this,
    );
    categoryId = _i1.ColumnInt(
      'categoryId',
      this,
    );
    assetGroup = _i1.ColumnString(
      'assetGroup',
      this,
    );
    assetModel = _i1.ColumnString(
      'assetModel',
      this,
    );
  }

  late final AssetUpdateTable updateTable;

  late final _i1.ColumnString assetName;

  late final _i1.ColumnString assetType;

  late final _i1.ColumnString serialNumber;

  late final _i1.ColumnInt categoryId;

  late final _i1.ColumnString assetGroup;

  late final _i1.ColumnString assetModel;

  @override
  List<_i1.Column> get columns => [
    id,
    assetName,
    assetType,
    serialNumber,
    categoryId,
    assetGroup,
    assetModel,
  ];
}

class AssetInclude extends _i1.IncludeObject {
  AssetInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Asset.t;
}

class AssetIncludeList extends _i1.IncludeList {
  AssetIncludeList._({
    _i1.WhereExpressionBuilder<AssetTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Asset.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Asset.t;
}

class AssetRepository {
  const AssetRepository._();

  /// Returns a list of [Asset]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Asset>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AssetTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AssetTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AssetTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Asset>(
      where: where?.call(Asset.t),
      orderBy: orderBy?.call(Asset.t),
      orderByList: orderByList?.call(Asset.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Asset] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Asset?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AssetTable>? where,
    int? offset,
    _i1.OrderByBuilder<AssetTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<AssetTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Asset>(
      where: where?.call(Asset.t),
      orderBy: orderBy?.call(Asset.t),
      orderByList: orderByList?.call(Asset.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Asset] by its [id] or null if no such row exists.
  Future<Asset?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Asset>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Asset]s in the list and returns the inserted rows.
  ///
  /// The returned [Asset]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Asset>> insert(
    _i1.DatabaseSession session,
    List<Asset> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Asset>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Asset] and returns the inserted row.
  ///
  /// The returned [Asset] will have its `id` field set.
  Future<Asset> insertRow(
    _i1.DatabaseSession session,
    Asset row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Asset>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Asset]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Asset>> update(
    _i1.DatabaseSession session,
    List<Asset> rows, {
    _i1.ColumnSelections<AssetTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Asset>(
      rows,
      columns: columns?.call(Asset.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Asset]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Asset> updateRow(
    _i1.DatabaseSession session,
    Asset row, {
    _i1.ColumnSelections<AssetTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Asset>(
      row,
      columns: columns?.call(Asset.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Asset] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Asset?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<AssetUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Asset>(
      id,
      columnValues: columnValues(Asset.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Asset]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Asset>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<AssetUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<AssetTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<AssetTable>? orderBy,
    _i1.OrderByListBuilder<AssetTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Asset>(
      columnValues: columnValues(Asset.t.updateTable),
      where: where(Asset.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Asset.t),
      orderByList: orderByList?.call(Asset.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Asset]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Asset>> delete(
    _i1.DatabaseSession session,
    List<Asset> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Asset>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Asset].
  Future<Asset> deleteRow(
    _i1.DatabaseSession session,
    Asset row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Asset>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Asset>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AssetTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Asset>(
      where: where(Asset.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<AssetTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Asset>(
      where: where?.call(Asset.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Asset] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<AssetTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Asset>(
      where: where(Asset.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
