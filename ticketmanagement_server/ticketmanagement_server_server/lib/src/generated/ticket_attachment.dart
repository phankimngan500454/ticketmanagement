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

abstract class TicketAttachment
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
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

  static final t = TicketAttachmentTable();

  static const db = TicketAttachmentRepository._();

  @override
  int? id;

  int ticketId;

  int uploaderId;

  String fileName;

  String mimeType;

  String fileData;

  int fileSize;

  DateTime uploadedAt;

  @override
  _i1.Table<int?> get table => t;

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
  Map<String, dynamic> toJsonForProtocol() {
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

  static TicketAttachmentInclude include() {
    return TicketAttachmentInclude._();
  }

  static TicketAttachmentIncludeList includeList({
    _i1.WhereExpressionBuilder<TicketAttachmentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketAttachmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketAttachmentTable>? orderByList,
    TicketAttachmentInclude? include,
  }) {
    return TicketAttachmentIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TicketAttachment.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(TicketAttachment.t),
      include: include,
    );
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

class TicketAttachmentUpdateTable
    extends _i1.UpdateTable<TicketAttachmentTable> {
  TicketAttachmentUpdateTable(super.table);

  _i1.ColumnValue<int, int> ticketId(int value) => _i1.ColumnValue(
    table.ticketId,
    value,
  );

  _i1.ColumnValue<int, int> uploaderId(int value) => _i1.ColumnValue(
    table.uploaderId,
    value,
  );

  _i1.ColumnValue<String, String> fileName(String value) => _i1.ColumnValue(
    table.fileName,
    value,
  );

  _i1.ColumnValue<String, String> mimeType(String value) => _i1.ColumnValue(
    table.mimeType,
    value,
  );

  _i1.ColumnValue<String, String> fileData(String value) => _i1.ColumnValue(
    table.fileData,
    value,
  );

  _i1.ColumnValue<int, int> fileSize(int value) => _i1.ColumnValue(
    table.fileSize,
    value,
  );

  _i1.ColumnValue<DateTime, DateTime> uploadedAt(DateTime value) =>
      _i1.ColumnValue(
        table.uploadedAt,
        value,
      );
}

class TicketAttachmentTable extends _i1.Table<int?> {
  TicketAttachmentTable({super.tableRelation})
    : super(tableName: 'ticket_attachments') {
    updateTable = TicketAttachmentUpdateTable(this);
    ticketId = _i1.ColumnInt(
      'ticketId',
      this,
    );
    uploaderId = _i1.ColumnInt(
      'uploaderId',
      this,
    );
    fileName = _i1.ColumnString(
      'fileName',
      this,
    );
    mimeType = _i1.ColumnString(
      'mimeType',
      this,
    );
    fileData = _i1.ColumnString(
      'fileData',
      this,
    );
    fileSize = _i1.ColumnInt(
      'fileSize',
      this,
    );
    uploadedAt = _i1.ColumnDateTime(
      'uploadedAt',
      this,
    );
  }

  late final TicketAttachmentUpdateTable updateTable;

  late final _i1.ColumnInt ticketId;

  late final _i1.ColumnInt uploaderId;

  late final _i1.ColumnString fileName;

  late final _i1.ColumnString mimeType;

  late final _i1.ColumnString fileData;

  late final _i1.ColumnInt fileSize;

  late final _i1.ColumnDateTime uploadedAt;

  @override
  List<_i1.Column> get columns => [
    id,
    ticketId,
    uploaderId,
    fileName,
    mimeType,
    fileData,
    fileSize,
    uploadedAt,
  ];
}

class TicketAttachmentInclude extends _i1.IncludeObject {
  TicketAttachmentInclude._();

  @override
  Map<String, _i1.Include?> get includes => {};

  @override
  _i1.Table<int?> get table => TicketAttachment.t;
}

class TicketAttachmentIncludeList extends _i1.IncludeList {
  TicketAttachmentIncludeList._({
    _i1.WhereExpressionBuilder<TicketAttachmentTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(TicketAttachment.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => TicketAttachment.t;
}

class TicketAttachmentRepository {
  const TicketAttachmentRepository._();

  /// Returns a list of [TicketAttachment]s matching the given query parameters.
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
  Future<List<TicketAttachment>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketAttachmentTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketAttachmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketAttachmentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<TicketAttachment>(
      where: where?.call(TicketAttachment.t),
      orderBy: orderBy?.call(TicketAttachment.t),
      orderByList: orderByList?.call(TicketAttachment.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [TicketAttachment] matching the given query parameters.
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
  Future<TicketAttachment?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketAttachmentTable>? where,
    int? offset,
    _i1.OrderByBuilder<TicketAttachmentTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<TicketAttachmentTable>? orderByList,
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<TicketAttachment>(
      where: where?.call(TicketAttachment.t),
      orderBy: orderBy?.call(TicketAttachment.t),
      orderByList: orderByList?.call(TicketAttachment.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [TicketAttachment] by its [id] or null if no such row exists.
  Future<TicketAttachment?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<TicketAttachment>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [TicketAttachment]s in the list and returns the inserted rows.
  ///
  /// The returned [TicketAttachment]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<TicketAttachment>> insert(
    _i1.DatabaseSession session,
    List<TicketAttachment> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<TicketAttachment>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [TicketAttachment] and returns the inserted row.
  ///
  /// The returned [TicketAttachment] will have its `id` field set.
  Future<TicketAttachment> insertRow(
    _i1.DatabaseSession session,
    TicketAttachment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<TicketAttachment>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [TicketAttachment]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<TicketAttachment>> update(
    _i1.DatabaseSession session,
    List<TicketAttachment> rows, {
    _i1.ColumnSelections<TicketAttachmentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<TicketAttachment>(
      rows,
      columns: columns?.call(TicketAttachment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TicketAttachment]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<TicketAttachment> updateRow(
    _i1.DatabaseSession session,
    TicketAttachment row, {
    _i1.ColumnSelections<TicketAttachmentTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<TicketAttachment>(
      row,
      columns: columns?.call(TicketAttachment.t),
      transaction: transaction,
    );
  }

  /// Updates a single [TicketAttachment] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<TicketAttachment?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<TicketAttachmentUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<TicketAttachment>(
      id,
      columnValues: columnValues(TicketAttachment.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [TicketAttachment]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<TicketAttachment>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<TicketAttachmentUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<TicketAttachmentTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<TicketAttachmentTable>? orderBy,
    _i1.OrderByListBuilder<TicketAttachmentTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<TicketAttachment>(
      columnValues: columnValues(TicketAttachment.t.updateTable),
      where: where(TicketAttachment.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(TicketAttachment.t),
      orderByList: orderByList?.call(TicketAttachment.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [TicketAttachment]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<TicketAttachment>> delete(
    _i1.DatabaseSession session,
    List<TicketAttachment> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<TicketAttachment>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [TicketAttachment].
  Future<TicketAttachment> deleteRow(
    _i1.DatabaseSession session,
    TicketAttachment row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<TicketAttachment>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<TicketAttachment>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TicketAttachmentTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<TicketAttachment>(
      where: where(TicketAttachment.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<TicketAttachmentTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<TicketAttachment>(
      where: where?.call(TicketAttachment.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [TicketAttachment] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<TicketAttachmentTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<TicketAttachment>(
      where: where(TicketAttachment.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
