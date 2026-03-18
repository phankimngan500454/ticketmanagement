// ignore_for_file: avoid_print
import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart'
    as sp;
import '../models/ticket.dart';
import '../models/ticket_comment.dart';
import '../models/ticket_attachment.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/asset.dart';
import '../models/department.dart';
import '../models/emergency_contact.dart';
import '../services/sp_client.dart';

// ============================================================
//  TicketRepository — dùng Serverpod Client
// ============================================================
class TicketRepository {
  TicketRepository._();
  static final TicketRepository instance = TicketRepository._();

  // ── Cache để join tên hiển thị ──────────────────────────────
  List<User> _userCache = [];
  List<Category> _categoryCache = [];
  List<Asset> _assetCache = [];

  // ── Model mappers ───────────────────────────────────────────
  User _mapUser(sp.AppUser u) => User(
        userId: u.id ?? 0,
        fullName: u.fullName?.isNotEmpty == true ? u.fullName! : u.username,
        phone: u.phone ?? '',
        role: _roleFromId(u.roleId),
        createdAt: u.createdAt,
        deptId: u.deptId ?? 0,
        deptName: null,
      );

  String _roleFromId(int id) {
    if (id == 1) return 'Admin';
    if (id == 2) return 'IT';
    return 'Customer';
  }

  Ticket _mapTicket(sp.Ticket t) {
    final requester = _userCache.where((u) => u.userId == t.requesterId).firstOrNull;
    final assignee  = t.assigneeId == null ? null
        : _userCache.where((u) => u.userId == t.assigneeId).firstOrNull;
    final category  = _categoryCache.where((c) => c.categoryId == t.categoryId).firstOrNull;
    final asset     = t.assetId == null ? null
        : _assetCache.where((a) => a.assetId == t.assetId).firstOrNull;

    return Ticket(
      ticketId: t.id ?? 0,
      subject: t.subject,
      description: t.description ?? '',
      status: t.status,
      priority: t.priority,
      createdAt: t.createdAt,
      requesterId: t.requesterId,
      requesterName: requester?.fullName,
      assigneeId: t.assigneeId,
      assigneeName: assignee?.fullName,
      categoryId: t.categoryId,
      categoryName: category?.categoryName,
      assetId: t.assetId,
      assetName: asset?.assetName,
      proposedDeadline: t.proposedDeadline,
      finalDeadline: t.finalDeadline,
      deadlineStatus: t.deadlineStatus,
    );
  }

  TicketComment _mapComment(sp.TicketComment c) {
    final user = _userCache.where((u) => u.userId == c.userId).firstOrNull;
    return TicketComment(
      commentId: c.id ?? 0,
      ticketId: c.ticketId,
      userId: c.userId,
      authorName: user?.fullName ?? 'User #${c.userId}',
      authorRole: user?.role ?? 'Customer',
      commentText: c.commentText,
      createdAt: c.createdAt,
    );
  }

  Category _mapCategory(sp.Category c) =>
      Category(categoryId: c.id ?? 0, categoryName: c.categoryName);

  Asset _mapAsset(sp.Asset a) => Asset(
        assetId:    a.id ?? 0,
        assetName:  a.assetName,
        assetCode:  a.serialNumber ?? '',
        assetGroup: a.assetGroup ?? 'Phần cứng',
        assetType:  a.assetType ?? 'Khác',
        assetModel: a.assetModel ?? '',
        status:     'Active',
        categoryId: a.categoryId,
      );

  // ── Warm cache ──────────────────────────────────────────────
  Future<void> _warmCache() async {
    await Future.wait([
      if (_userCache.isEmpty)
        client.auth.getUsers().then((us) {
          _userCache = us.map(_mapUser).toList();
        }),
      if (_categoryCache.isEmpty)
        client.reference.getCategories().then((cs) {
          _categoryCache = cs.map(_mapCategory).toList();
        }),
      if (_assetCache.isEmpty)
        client.reference.getAssets().then((as_) {
          _assetCache = as_.map(_mapAsset).toList();
        }),
    ]);
  }

  // ==========================================================
  //  AUTH
  // ==========================================================
  Future<User?> login(String username, String password) async {
    try {
      final u = await client.auth.login(username, password);
      if (u == null) return null;
      _userCache = [];
      return _mapUser(u);
    } catch (e) {
      print('[SP] login error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    _userCache = [];
    _categoryCache = [];
    _assetCache = [];
  }

  // ==========================================================
  //  USERS
  // ==========================================================
  Future<List<User>> getUsers() async {
    final us = await client.auth.getUsers();
    _userCache = us.map(_mapUser).toList();
    return _userCache;
  }

  Future<List<User>> getITStaff() async {
    final staff = await client.auth.getITStaff();
    final mapped = staff.map(_mapUser).toList();
    for (final u in mapped) {
      if (!_userCache.any((c) => c.userId == u.userId)) _userCache.add(u);
    }
    return mapped;
  }

  // ==========================================================
  //  TICKETS
  // ==========================================================
  Future<List<Ticket>> getAllTickets() async {
    await _warmCache();
    final raw = await client.ticket.getTickets(0, 1); // roleId 1 = Admin → tất cả
    return raw.map(_mapTicket).toList();
  }

  Future<List<Ticket>> getTicketsByRequester(int requesterId) async {
    await _warmCache();
    final raw = await client.ticket.getTickets(requesterId, 3);
    return raw.map(_mapTicket).toList();
  }

  Future<List<Ticket>> getUnassignedTickets() async {
    await _warmCache();
    final raw = await client.ticket.getUnassignedTickets();
    return raw.map(_mapTicket).toList();
  }

  Future<List<Ticket>> getTicketsByAssignee(int assigneeId) async {
    await _warmCache();
    final raw = await client.ticket.getTickets(assigneeId, 2);
    return raw.where((t) => t.status != 'Resolved').map(_mapTicket).toList();
  }

  Future<Ticket?> getTicketById(int ticketId) async {
    await _warmCache();
    final t = await client.ticket.getTicketById(ticketId);
    return t == null ? null : _mapTicket(t);
  }

  Future<Ticket> createTicket({
    required int requesterId,
    String? requesterName,
    required int categoryId,
    String? categoryName,
    required String subject,
    required String description,
    required String priority,
    int? assetId,
    String? assetName,
    DateTime? deadline,
  }) async {
    await _warmCache();
    final t = await client.ticket.createTicket(
      requesterId, categoryId, subject, description, priority, assetId,
    );
    return _mapTicket(t);
  }

  Future<Ticket> assignTicket(int ticketId, int? assigneeId, [String? assigneeName]) async {
    await _warmCache();
    final t = await client.ticket.assignTicket(ticketId, assigneeId);
    if (t == null) throw Exception('Ticket not found');
    return _mapTicket(t);
  }

  Future<Ticket> updateStatus(int ticketId, String status) async {
    await _warmCache();
    final t = await client.ticket.updateStatus(ticketId, status);
    if (t == null) throw Exception('Ticket not found');
    return _mapTicket(t);
  }

  // ==========================================================
  //  DEADLINE
  // ==========================================================
  Future<Ticket> proposeDeadline(int ticketId, int proposedByUserId, DateTime deadline) async {
    await _warmCache();
    final t = await client.ticket.proposeDeadline(ticketId, proposedByUserId, deadline);
    if (t == null) throw Exception('Ticket not found');
    return _mapTicket(t);
  }

  Future<Ticket> approveDeadline(int ticketId, String action, {DateTime? finalDeadline, String? adminNote}) async {
    await _warmCache();
    final t = await client.ticket.approveDeadline(ticketId, action, finalDeadline, adminNote);
    if (t == null) throw Exception('Ticket not found');
    return _mapTicket(t);
  }

  Future<Ticket> confirmDeadline(int ticketId, bool confirmed) async {
    await _warmCache();
    final t = await client.ticket.confirmDeadline(ticketId, confirmed);
    if (t == null) throw Exception('Ticket not found');
    return _mapTicket(t);
  }

  // ==========================================================
  //  COMMENTS
  // ==========================================================
  Future<List<TicketComment>> getComments(int ticketId) async {
    await _warmCache();
    final raw = await client.comment.getComments(ticketId);
    return raw.map(_mapComment).toList();
  }

  Future<TicketComment> addComment({
    required int ticketId,
    required int userId,
    String? authorName,
    String? authorRole,
    required String commentText,
  }) async {
    await _warmCache();
    final c = await client.comment.addComment(ticketId, userId, commentText);
    return _mapComment(c);
  }

  // ==========================================================
  //  REFERENCE DATA
  // ==========================================================
  Future<List<Category>> getCategories() async {
    final cats = await client.reference.getCategories();
    _categoryCache = cats.map(_mapCategory).toList();
    return _categoryCache;
  }

  Future<Category> upsertCategory(Category cat) async {
    final spCat = await client.reference.upsertCategory(
      sp.Category(
        id: cat.categoryId == 0 ? null : cat.categoryId,
        categoryName: cat.categoryName,
      ));
    _categoryCache = [];
    return _mapCategory(spCat);
  }

  Future<void> deleteCategory(int categoryId) async {
    await client.reference.deleteCategory(categoryId);
    _categoryCache = [];
  }

  Future<List<Asset>> getAssets() async {
    final assets = await client.reference.getAssets();
    _assetCache = assets.map(_mapAsset).toList();
    return _assetCache;
  }

  Future<Asset> upsertAsset(Asset asset) async {
    final spAsset = await client.reference.upsertAsset(
      sp.Asset(
        id: asset.assetId == 0 ? null : asset.assetId,
        assetName: asset.assetName,
        assetType: asset.assetType.isEmpty ? null : asset.assetType,
        serialNumber: asset.assetCode.isEmpty ? null : asset.assetCode,
        categoryId: asset.categoryId,
        assetGroup: asset.assetGroup.isEmpty ? null : asset.assetGroup,
        assetModel: asset.assetModel.isEmpty ? null : asset.assetModel,
      ));
    _assetCache = [];
    return _mapAsset(spAsset);
  }

  Future<void> deleteAsset(int assetId) async {
    await client.reference.deleteAsset(assetId);
    _assetCache = [];
  }

  Future<List<Department>> getDepartments() async {
    final depts = await client.reference.getDepartments();
    return depts
        .map((d) => Department(deptId: d.id ?? 0, deptName: d.name))
        .toList();
  }

  // ==========================================================
  //  USER MANAGEMENT (Admin only)
  // ==========================================================
  Future<User> updateUser({
    required int userId,
    required String fullName,
    String? phone,
    required int roleId,
    int? deptId,
  }) async {
    final u = await client.auth.updateUser(userId, fullName, phone, roleId, deptId);
    if (u == null) throw Exception('User not found');
    _userCache = [];
    return _mapUser(u);
  }

  Future<bool> resetPassword(int userId, String newPassword) async {
    return client.auth.resetPassword(userId, newPassword);
  }

  Future<bool> deleteUser(int userId) async {
    _userCache = [];
    return client.auth.deleteUser(userId);
  }

  Future<User?> register({
    required String username,
    required String password,
    required String fullName,
    String? phone,
    required int roleId,
    int? deptId,
  }) async {
    final u = await client.auth.register(username, password, fullName, phone, roleId, deptId);
    if (u == null) return null;
    _userCache = [];
    return _mapUser(u);
  }

  // ==========================================================
  //  EMERGENCY CONTACTS
  // ==========================================================
  Future<List<EmergencyContact>> getEmergencyContacts() async {
    final list = await client.reference.getEmergencyContacts();
    return list.map((e) => EmergencyContact.fromSp(e)).toList();
  }

  Future<EmergencyContact> upsertEmergencyContact(EmergencyContact contact) async {
    final spContact = sp.EmergencyContact(
      id: contact.id,
      userId: contact.userId,
      name: contact.name,
      phoneNumber: contact.phoneNumber,
      description: contact.description,
      sortOrder: contact.sortOrder,
    );
    final result = await client.reference.upsertEmergencyContact(spContact);
    return EmergencyContact.fromSp(result);
  }

  Future<void> deleteEmergencyContact(int id) async {
    await client.reference.deleteEmergencyContact(id);
  }

  // ==========================================================
  //  ATTACHMENTS
  // ==========================================================
  TicketAttachmentModel _mapAttachment(dynamic a) => TicketAttachmentModel(
    id: (a.id ?? 0) as int,
    ticketId: (a.ticketId ?? 0) as int,
    uploaderId: (a.uploaderId ?? 0) as int,
    fileName: (a.fileName ?? '') as String,
    mimeType: (a.mimeType ?? '') as String,
    fileData: (a.fileData ?? '') as String,
    fileSize: (a.fileSize ?? 0) as int,
    uploadedAt: a.uploadedAt as DateTime,
  );

  Future<List<TicketAttachmentModel>> getAttachments(int ticketId) async {
    final list = await client.attachment.getAttachments(ticketId);
    return list.map(_mapAttachment).toList();
  }

  Future<TicketAttachmentModel> uploadAttachment({
    required int ticketId,
    required int uploaderId,
    required String fileName,
    required String mimeType,
    required String fileData,
    required int fileSize,
  }) async {
    final a = await client.attachment.uploadAttachment(
      ticketId, uploaderId, fileName, mimeType, fileData, fileSize);
    return _mapAttachment(a);
  }

  Future<void> deleteAttachment(int attachmentId) async {
    await client.attachment.deleteAttachment(attachmentId);
  }
}
