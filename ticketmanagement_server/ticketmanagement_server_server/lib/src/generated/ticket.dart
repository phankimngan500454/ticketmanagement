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

abstract class Ticket implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = TicketTable();

  static const db = TicketRepository._();

  @override
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

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static TicketInclude include() {
    return TicketInclude._();
  }

  static TicketIncludeList includeList({
    _i1.WhereExpressionBuilder<TicketTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketTable>? orderByList,
    TicketInclude? include,
  }) {
    return TicketIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Ticket.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(Ticket.t),
      include: include,
    );
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

class TicketUpdateTable extends _i1.UpdateTable<TicketTable> {
  TicketUpdateTable(super.table);

  _i1.ColumnValue<String, String> subject(String value) => _i1.ColumnValue(
    table.subject,
    value,
  );

  _i1.ColumnValue<String, String> description(String? value) => _i1.ColumnValue(
    table.description,
    value,
  );

  _i1.ColumnValue<String, String> status(String value) => _i1.ColumnValue(
    table.status,
    value,
  );

  _i1.ColumnValue<String, String> priority(String value) => _i1.ColumnValue(
    table.priority,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );

  _i1.ColumnValue<int, int> requesterId(int value) => _i1.ColumnValue(
    table.requesterId,
    value,
  );

  _i1.ColumnValue<int, int> assigneeId(int? value) => _i1.ColumnValue(
    table.assigneeId,
    value,
  );

  _i1.ColumnValue<int, int> categoryId(int value) => _i1.ColumnValue(
    table.categoryId,
    value,
  );

  _i1.ColumnValue<int, int> assetId(int? value) => _i1.ColumnValue(
    table.assetId,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> proposedDeadline(DateTime? value) =>
      _i1.ColumnValue(
        table.proposedDeadline,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> finalDeadline(DateTime? value) =>
      _i1.ColumnValue(
        table.finalDeadline,
        value,
      );

  _i1.ColumnValue<String, String> deadlineStatus(String? value) =>
      _i1.ColumnValue(
        table.deadlineStatus,
        value,
      );

  _i1.ColumnValue<String, String> adminNote(String? value) => _i1.ColumnValue(
    table.adminNote,
    value,
  );

  _i1.ColumnValue<int, int> proposedByUserId(int? value) => _i1.ColumnValue(
    table.proposedByUserId,
    value,
  );
}

class TicketTable extends _i1.Table<int?> {
  TicketTable({super.tableRelation}) : super(tableName: 'tickets') {
    updateTable = TicketUpdateTable(this);
    subject = _i1.ColumnString(
      'subject',
      this,
    );
    description = _i1.ColumnString(
      'description',
      this,
    );
    status = _i1.ColumnString(
      'status',
      this,
    );
    priority = _i1.ColumnString(
      'priority',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
    requesterId = _i1.ColumnInt(
      'requesterId',
      this,
    );
    assigneeId = _i1.ColumnInt(
      'assigneeId',
      this,
    );
    categoryId = _i1.ColumnInt(
      'categoryId',
      this,
    );
    assetId = _i1.ColumnInt(
      'assetId',
      this,
    );
    proposedDeadline = _i1.ColumnDateTime(
      'proposedDeadline',
      this,
    );
    finalDeadline = _i1.ColumnDateTime(
      'finalDeadline',
      this,
    );
    deadlineStatus = _i1.ColumnString(
      'deadlineStatus',
      this,
    );
    adminNote = _i1.ColumnString(
      'adminNote',
      this,
    );
    proposedByUserId = _i1.ColumnInt(
      'proposedByUserId',
      this,
    );
  }

  late final TicketUpdateTable updateTable;

  late final _i1.ColumnString subject;

  late final _i1.ColumnString description;

  late final _i1.ColumnString status;

  late final _i1.ColumnString priority;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnInt requesterId;

  late final _i1.ColumnInt assigneeId;

  late final _i1.ColumnInt categoryId;

  late final _i1.ColumnInt assetId;

  late final _i1.ColumnDateTime proposedDeadline;

  late final _i1.ColumnDateTime finalDeadline;

  late final _i1.ColumnString deadlineStatus;

  late final _i1.ColumnString adminNote;

  late final _i1.ColumnInt proposedByUserId;

  @override
  List<_i1.Column> get columns => [
    id,
    subject,
    description,
    status,
    priority,
    createdAt,
    requesterId,
    assigneeId,
    categoryId,
    assetId,
    proposedDeadline,
    finalDeadline,
    deadlineStatus,
    adminNote,
    proposedByUserId,
  ];
}

class TicketInclude extends _i1.IncludeObject {
  TicketInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => Ticket.t;
}

class TicketIncludeList extends _i1.IncludeList {
  TicketIncludeList._({
    _i1.WhereExpressionBuilder<TicketTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Ticket.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => Ticket.t;
}

class TicketRepository {
  const TicketRepository._();

  /// Returns a list of [Ticket]s matching the given query parameters.
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
  Future<List<Ticket>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Ticket>(
      where: where?.call(Ticket.t),
      orderBy: orderBy?.call(Ticket.t),
      orderByList: orderByList?.call(Ticket.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Ticket] matching the given query parameters.
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
  Future<Ticket?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketTable>? where,
    int? offset,
    _i1.OrderByBuilder<TicketTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Ticket>(
      where: where?.call(Ticket.t),
      orderBy: orderBy?.call(Ticket.t),
      orderByList: orderByList?.call(Ticket.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Ticket] by its [id] or null if no such row exists.
  Future<Ticket?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Ticket>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Ticket]s in the list and returns the inserted rows.
  ///
  /// The returned [Ticket]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<Ticket>> insert(
    _i1.DatabaseSession session,
    List<Ticket> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<Ticket>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [Ticket] and returns the inserted row.
  ///
  /// The returned [Ticket] will have its `id` field set.
  Future<Ticket> insertRow(
    _i1.DatabaseSession session,
    Ticket row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<Ticket>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [Ticket]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<Ticket>> update(
    _i1.DatabaseSession session,
    List<Ticket> rows, {
    _i1.ColumnSelections<TicketTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<Ticket>(
      rows,
      columns: columns?.call(Ticket.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Ticket]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Ticket> updateRow(
    _i1.DatabaseSession session,
    Ticket row, {
    _i1.ColumnSelections<TicketTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<Ticket>(
      row,
      columns: columns?.call(Ticket.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Ticket] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Ticket?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<TicketUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<Ticket>(
      id,
      columnValues: columnValues(Ticket.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Ticket]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<Ticket>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<TicketUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TicketTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketTable>? orderBy,
    _i1.OrderByListBuilder<TicketTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<Ticket>(
      columnValues: columnValues(Ticket.t.updateTable),
      where: where(Ticket.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Ticket.t),
      orderByList: orderByList?.call(Ticket.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [Ticket]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<Ticket>> delete(
    _i1.DatabaseSession session,
    List<Ticket> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<Ticket>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [Ticket].
  Future<Ticket> deleteRow(
    _i1.DatabaseSession session,
    Ticket row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Ticket>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<Ticket>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TicketTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<Ticket>(
      where: where(Ticket.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<Ticket>(
      where: where?.call(Ticket.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Ticket] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TicketTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Ticket>(
      where: where(Ticket.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
