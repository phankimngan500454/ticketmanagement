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

abstract class TicketEvent
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = TicketEventTable();

  static const db = TicketEventRepository._();

  @override
  int? id;

  int ticketId;

  int userId;

  String eventType;

  String? oldValue;

  String? newValue;

  String? description;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static TicketEventInclude include() {
    return TicketEventInclude._();
  }

  static TicketEventIncludeList includeList({
    _i1.WhereExpressionBuilder<TicketEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketEventTable>? orderByList,
    TicketEventInclude? include,
  }) {
    return TicketEventIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TicketEvent.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TicketEvent.t),
      include: include,
    );
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

class TicketEventUpdateTable extends _i1.UpdateTable<TicketEventTable> {
  TicketEventUpdateTable(super.table);

  _i1.ColumnValue<int, int> ticketId(int value) => _i1.ColumnValue(
    table.ticketId,
    value,
  );

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> eventType(String value) => _i1.ColumnValue(
    table.eventType,
    value,
  );

  _i1.ColumnValue<String, String> oldValue(String? value) => _i1.ColumnValue(
    table.oldValue,
    value,
  );

  _i1.ColumnValue<String, String> newValue(String? value) => _i1.ColumnValue(
    table.newValue,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class TicketEventTable extends _i1.Table<int?> {
  TicketEventTable({super.tableRelation}) : super(tableName: 'ticket_events') {
    updateTable = TicketEventUpdateTable(this);
    ticketId = _i1.ColumnInt(
      'ticketId',
      this,
    );
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    eventType = _i1.ColumnString(
      'eventType',
      this,
    );
    oldValue = _i1.ColumnString(
      'oldValue',
      this,
    );
    newValue = _i1.ColumnString(
      'newValue',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final TicketEventUpdateTable updateTable;

  late final _i1.ColumnInt ticketId;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnString eventType;

  late final _i1.ColumnString oldValue;

  late final _i1.ColumnString newValue;

  late final _i1.ColumnString description;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    ticketId,
    userId,
    eventType,
    oldValue,
    newValue,
    description,
    createdAt,
  ];
}

class TicketEventInclude extends _i1.IncludeObject {
  TicketEventInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TicketEvent.t;
}

class TicketEventIncludeList extends _i1.IncludeList {
  TicketEventIncludeList._({
    _i1.WhereExpressionBuilder<TicketEventTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TicketEvent.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TicketEvent.t;
}

class TicketEventRepository {
  const TicketEventRepository._();

  /// Returns a list of [TicketEvent]s matching the given query parameters.
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
  Future<List<TicketEvent>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketEventTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketEventTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TicketEvent>(
      where: where?.call(TicketEvent.t),
      orderBy: orderBy?.call(TicketEvent.t),
      orderByList: orderByList?.call(TicketEvent.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TicketEvent] matching the given query parameters.
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
  Future<TicketEvent?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketEventTable>? where,
    int? offset,
    _i1.OrderByBuilder<TicketEventTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketEventTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TicketEvent>(
      where: where?.call(TicketEvent.t),
      orderBy: orderBy?.call(TicketEvent.t),
      orderByList: orderByList?.call(TicketEvent.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TicketEvent] by its [id] or null if no such row exists.
  Future<TicketEvent?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TicketEvent>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TicketEvent]s in the list and returns the inserted rows.
  ///
  /// The returned [TicketEvent]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<TicketEvent>> insert(
    _i1.DatabaseSession session,
    List<TicketEvent> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<TicketEvent>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [TicketEvent] and returns the inserted row.
  ///
  /// The returned [TicketEvent] will have its `id` field set.
  Future<TicketEvent> insertRow(
    _i1.DatabaseSession session,
    TicketEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TicketEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TicketEvent]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TicketEvent>> update(
    _i1.DatabaseSession session,
    List<TicketEvent> rows, {
    _i1.ColumnSelections<TicketEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TicketEvent>(
      rows,
      columns: columns?.call(TicketEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TicketEvent]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TicketEvent> updateRow(
    _i1.DatabaseSession session,
    TicketEvent row, {
    _i1.ColumnSelections<TicketEventTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TicketEvent>(
      row,
      columns: columns?.call(TicketEvent.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TicketEvent] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TicketEvent?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<TicketEventUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TicketEvent>(
      id,
      columnValues: columnValues(TicketEvent.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TicketEvent]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TicketEvent>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<TicketEventUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TicketEventTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketEventTable>? orderBy,
    _i1.OrderByListBuilder<TicketEventTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TicketEvent>(
      columnValues: columnValues(TicketEvent.t.updateTable),
      where: where(TicketEvent.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TicketEvent.t),
      orderByList: orderByList?.call(TicketEvent.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TicketEvent]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TicketEvent>> delete(
    _i1.DatabaseSession session,
    List<TicketEvent> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TicketEvent>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TicketEvent].
  Future<TicketEvent> deleteRow(
    _i1.DatabaseSession session,
    TicketEvent row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TicketEvent>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TicketEvent>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TicketEventTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TicketEvent>(
      where: where(TicketEvent.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketEventTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TicketEvent>(
      where: where?.call(TicketEvent.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TicketEvent] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TicketEventTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TicketEvent>(
      where: where(TicketEvent.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
