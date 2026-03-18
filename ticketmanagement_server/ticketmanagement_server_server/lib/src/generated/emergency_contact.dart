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

abstract class EmergencyContact
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = EmergencyContactTable();

  static const db = EmergencyContactRepository._();

  @override
  int? id;

  int? userId;

  String name;

  String phoneNumber;

  String? description;

  int sortOrder;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static EmergencyContactInclude include() {
    return EmergencyContactInclude._();
  }

  static EmergencyContactIncludeList includeList({
    _i1.WhereExpressionBuilder<EmergencyContactTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmergencyContactTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmergencyContactTable>? orderByList,
    EmergencyContactInclude? include,
  }) {
    return EmergencyContactIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EmergencyContact.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(EmergencyContact.t),
      include: include,
    );
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

class EmergencyContactUpdateTable
    extends _i1.UpdateTable<EmergencyContactTable> {
  EmergencyContactUpdateTable(super.table);

  _i1.ColumnValue<int, int> userId(int? value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> name(String value) => _i1.ColumnValue(
    table.name,
    value,
  );

  _i1.ColumnValue<String, String> phoneNumber(String value) => _i1.ColumnValue(
    table.phoneNumber,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<int, int> sortOrder(int value) => _i1.ColumnValue(
    table.sortOrder,
    value,
  );
}

class EmergencyContactTable extends _i1.Table<int?> {
  EmergencyContactTable({super.tableRelation})
    : super(tableName: 'emergency_contacts') {
    updateTable = EmergencyContactUpdateTable(this);
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    name = _i1.ColumnString(
      'name',
      this,
    );
    phoneNumber = _i1.ColumnString(
      'phoneNumber',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    sortOrder = _i1.ColumnInt(
      'sortOrder',
      this,
    );
  }

  late final EmergencyContactUpdateTable updateTable;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnString name;

  late final _i1.ColumnString phoneNumber;

  late final _i1.ColumnString description;

  late final _i1.ColumnInt sortOrder;

  @override
  List<_i1.Column> get columns => [
    id,
    userId,
    name,
    phoneNumber,
    description,
    sortOrder,
  ];
}

class EmergencyContactInclude extends _i1.IncludeObject {
  EmergencyContactInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => EmergencyContact.t;
}

class EmergencyContactIncludeList extends _i1.IncludeList {
  EmergencyContactIncludeList._({
    _i1.WhereExpressionBuilder<EmergencyContactTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(EmergencyContact.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => EmergencyContact.t;
}

class EmergencyContactRepository {
  const EmergencyContactRepository._();

  /// Returns a list of [EmergencyContact]s matching the given query parameters.
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
  Future<List<EmergencyContact>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<EmergencyContactTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmergencyContactTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmergencyContactTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<EmergencyContact>(
      where: where?.call(EmergencyContact.t),
      orderBy: orderBy?.call(EmergencyContact.t),
      orderByList: orderByList?.call(EmergencyContact.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [EmergencyContact] matching the given query parameters.
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
  Future<EmergencyContact?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<EmergencyContactTable>? where,
    int? offset,
    _i1.OrderByBuilder<EmergencyContactTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<EmergencyContactTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<EmergencyContact>(
      where: where?.call(EmergencyContact.t),
      orderBy: orderBy?.call(EmergencyContact.t),
      orderByList: orderByList?.call(EmergencyContact.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [EmergencyContact] by its [id] or null if no such row exists.
  Future<EmergencyContact?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<EmergencyContact>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [EmergencyContact]s in the list and returns the inserted rows.
  ///
  /// The returned [EmergencyContact]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<EmergencyContact>> insert(
    _i1.DatabaseSession session,
    List<EmergencyContact> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<EmergencyContact>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [EmergencyContact] and returns the inserted row.
  ///
  /// The returned [EmergencyContact] will have its `id` field set.
  Future<EmergencyContact> insertRow(
    _i1.DatabaseSession session,
    EmergencyContact row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<EmergencyContact>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [EmergencyContact]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<EmergencyContact>> update(
    _i1.DatabaseSession session,
    List<EmergencyContact> rows, {
    _i1.ColumnSelections<EmergencyContactTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<EmergencyContact>(
      rows,
      columns: columns?.call(EmergencyContact.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EmergencyContact]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<EmergencyContact> updateRow(
    _i1.DatabaseSession session,
    EmergencyContact row, {
    _i1.ColumnSelections<EmergencyContactTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<EmergencyContact>(
      row,
      columns: columns?.call(EmergencyContact.t),
      transaction: transaction,
    );
  }

  /// Updates a single [EmergencyContact] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<EmergencyContact?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<EmergencyContactUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<EmergencyContact>(
      id,
      columnValues: columnValues(EmergencyContact.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [EmergencyContact]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<EmergencyContact>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<EmergencyContactUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<EmergencyContactTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<EmergencyContactTable>? orderBy,
    _i1.OrderByListBuilder<EmergencyContactTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<EmergencyContact>(
      columnValues: columnValues(EmergencyContact.t.updateTable),
      where: where(EmergencyContact.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(EmergencyContact.t),
      orderByList: orderByList?.call(EmergencyContact.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [EmergencyContact]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<EmergencyContact>> delete(
    _i1.DatabaseSession session,
    List<EmergencyContact> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<EmergencyContact>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [EmergencyContact].
  Future<EmergencyContact> deleteRow(
    _i1.DatabaseSession session,
    EmergencyContact row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<EmergencyContact>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<EmergencyContact>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<EmergencyContactTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<EmergencyContact>(
      where: where(EmergencyContact.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<EmergencyContactTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<EmergencyContact>(
      where: where?.call(EmergencyContact.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [EmergencyContact] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<EmergencyContactTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<EmergencyContact>(
      where: where(EmergencyContact.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
