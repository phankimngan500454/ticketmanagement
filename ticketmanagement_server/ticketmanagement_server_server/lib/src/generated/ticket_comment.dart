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

abstract class TicketComment
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = TicketCommentTable();

  static const db = TicketCommentRepository._();

  @override
  int? id;

  int ticketId;

  int userId;

  String commentText;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TicketComment',
      if (id != null) 'id': id,
      'ticketId': ticketId,
      'userId': userId,
      'commentText': commentText,
      'createdAt': createdAt.toJson(),
    };
  }

  static TicketCommentInclude include() {
    return TicketCommentInclude._();
  }

  static TicketCommentIncludeList includeList({
    _i1.WhereExpressionBuilder<TicketCommentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketCommentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketCommentTable>? orderByList,
    TicketCommentInclude? include,
  }) {
    return TicketCommentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TicketComment.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TicketComment.t),
      include: include,
    );
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

class TicketCommentUpdateTable extends _i1.UpdateTable<TicketCommentTable> {
  TicketCommentUpdateTable(super.table);

  _i1.ColumnValue<int, int> ticketId(int value) => _i1.ColumnValue(
    table.ticketId,
    value,
  );

  _i1.ColumnValue<int, int> userId(int value) => _i1.ColumnValue(
    table.userId,
    value,
  );

  _i1.ColumnValue<String, String> commentText(String value) => _i1.ColumnValue(
    table.commentText,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(
        table.createdAt,
        value,
      );
}

class TicketCommentTable extends _i1.Table<int?> {
  TicketCommentTable({super.tableRelation})
    : super(tableName: 'ticket_comments') {
    updateTable = TicketCommentUpdateTable(this);
    ticketId = _i1.ColumnInt(
      'ticketId',
      this,
    );
    userId = _i1.ColumnInt(
      'userId',
      this,
    );
    commentText = _i1.ColumnString(
      'commentText',
      this,
    );
    createdAt = _i1.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final TicketCommentUpdateTable updateTable;

  late final _i1.ColumnInt ticketId;

  late final _i1.ColumnInt userId;

  late final _i1.ColumnString commentText;

  late final _i1.ColumnDateTime createdAt;

  @override
  List<_i1.Column> get columns => [
    id,
    ticketId,
    userId,
    commentText,
    createdAt,
  ];
}

class TicketCommentInclude extends _i1.IncludeObject {
  TicketCommentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TicketComment.t;
}

class TicketCommentIncludeList extends _i1.IncludeList {
  TicketCommentIncludeList._({
    _i1.WhereExpressionBuilder<TicketCommentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TicketComment.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TicketComment.t;
}

class TicketCommentRepository {
  const TicketCommentRepository._();

  /// Returns a list of [TicketComment]s matching the given query parameters.
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
  Future<List<TicketComment>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketCommentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketCommentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketCommentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TicketComment>(
      where: where?.call(TicketComment.t),
      orderBy: orderBy?.call(TicketComment.t),
      orderByList: orderByList?.call(TicketComment.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TicketComment] matching the given query parameters.
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
  Future<TicketComment?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketCommentTable>? where,
    int? offset,
    _i1.OrderByBuilder<TicketCommentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketCommentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TicketComment>(
      where: where?.call(TicketComment.t),
      orderBy: orderBy?.call(TicketComment.t),
      orderByList: orderByList?.call(TicketComment.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TicketComment] by its [id] or null if no such row exists.
  Future<TicketComment?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TicketComment>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TicketComment]s in the list and returns the inserted rows.
  ///
  /// The returned [TicketComment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<TicketComment>> insert(
    _i1.DatabaseSession session,
    List<TicketComment> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<TicketComment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [TicketComment] and returns the inserted row.
  ///
  /// The returned [TicketComment] will have its `id` field set.
  Future<TicketComment> insertRow(
    _i1.DatabaseSession session,
    TicketComment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TicketComment>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TicketComment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TicketComment>> update(
    _i1.DatabaseSession session,
    List<TicketComment> rows, {
    _i1.ColumnSelections<TicketCommentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TicketComment>(
      rows,
      columns: columns?.call(TicketComment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TicketComment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TicketComment> updateRow(
    _i1.DatabaseSession session,
    TicketComment row, {
    _i1.ColumnSelections<TicketCommentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TicketComment>(
      row,
      columns: columns?.call(TicketComment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TicketComment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TicketComment?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<TicketCommentUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TicketComment>(
      id,
      columnValues: columnValues(TicketComment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TicketComment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TicketComment>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<TicketCommentUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<TicketCommentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketCommentTable>? orderBy,
    _i1.OrderByListBuilder<TicketCommentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TicketComment>(
      columnValues: columnValues(TicketComment.t.updateTable),
      where: where(TicketComment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TicketComment.t),
      orderByList: orderByList?.call(TicketComment.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TicketComment]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TicketComment>> delete(
    _i1.DatabaseSession session,
    List<TicketComment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TicketComment>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TicketComment].
  Future<TicketComment> deleteRow(
    _i1.DatabaseSession session,
    TicketComment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TicketComment>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TicketComment>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TicketCommentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TicketComment>(
      where: where(TicketComment.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketCommentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TicketComment>(
      where: where?.call(TicketComment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TicketComment] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TicketCommentTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TicketComment>(
      where: where(TicketComment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
