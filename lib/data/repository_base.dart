// ignore_for_file: avoid_print
// ============================================================
//  repository_base.dart
//  Cache dùng chung + tất cả model mappers
//  Được extend bởi TicketRepository (singleton facade)
// ============================================================
import 'package:ticketmanagement_server_client/ticketmanagement_server_client.dart'
    as sp;
import '../models/ticket.dart';
import '../models/ticket_comment.dart';
import '../models/ticket_attachment.dart';
import '../models/user.dart';
import '../models/category.dart';
import '../models/asset.dart';
import '../models/department.dart';
import '../services/sp_client.dart';

abstract class RepositoryBase {
  // ── In-memory cache (dùng để join tên hiển thị) ────────────
  List<User> userCache = [];
  List<Category> categoryCache = [];
  List<Asset> assetCache = [];
  List<Department> deptCache = [];

  // ── Session ──────────────────────────────────────────────────
  User? currentUser;

  // ── Helpers ─────────────────────────────────────────────────
  String roleFromId(int id) {
    if (id == 1) return 'Admin';
    if (id == 2) return 'IT';
    if (id == 4) return 'Manager';
    return 'Customer';
  }

  // ── Mappers: SP model → App model ───────────────────────────

  User mapUser(sp.AppUser u) {
    final deptId = u.deptId ?? 0;
    final dept = deptCache.where((d) => d.deptId == deptId).firstOrNull;
    return User(
      userId: u.id ?? 0,
      username: u.username,
      fullName: u.fullName?.isNotEmpty == true ? u.fullName! : u.username,
      phone: u.phone ?? '',
      role: roleFromId(u.roleId),
      createdAt: u.createdAt,
      deptId: deptId,
      deptName: dept?.deptName,
      permissions: u.permissions,
    );
  }

  Ticket mapTicket(sp.Ticket t) {
    final requester = userCache.where((u) => u.userId == t.requesterId).firstOrNull;
    final assignee  = t.assigneeId == null ? null
        : userCache.where((u) => u.userId == t.assigneeId).firstOrNull;
    final category  = categoryCache.where((c) => c.categoryId == t.categoryId).firstOrNull;
    final asset     = t.assetId == null ? null
        : assetCache.where((a) => a.assetId == t.assetId).firstOrNull;

    return Ticket(
      ticketId: t.id ?? 0,
      subject: t.subject,
      description: t.description ?? '',
      status: t.status,
      priority: t.priority,
      createdAt: t.createdAt,
      requesterId: t.requesterId,
      requesterName: requester?.fullName,
      requesterDeptName: requester?.deptName,
      requesterPhone: requester?.phone,
      ticketType: t.ticketType ?? 'ticket',
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

  TicketComment mapComment(sp.TicketComment c) {
    final user = userCache.where((u) => u.userId == c.userId).firstOrNull;
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

  Category mapCategory(sp.Category c) =>
      Category(categoryId: c.id ?? 0, categoryName: c.categoryName);

  Asset mapAsset(sp.Asset a) => Asset(
        assetId:    a.id ?? 0,
        assetName:  a.assetName,
        assetCode:  a.serialNumber ?? '',
        assetGroup: a.assetGroup ?? 'Phần cứng',
        assetType:  a.assetType ?? 'Khác',
        assetModel: a.assetModel ?? '',
        status:     'Active',
        categoryId: a.categoryId,
      );

  TicketAttachmentModel mapAttachment(dynamic a) => TicketAttachmentModel(
        id:         (a.id ?? 0) as int,
        ticketId:   (a.ticketId ?? 0) as int,
        uploaderId: (a.uploaderId ?? 0) as int,
        fileName:   (a.fileName ?? '') as String,
        mimeType:   (a.mimeType ?? '') as String,
        fileData:   (a.fileData ?? '') as String,
        fileSize:   (a.fileSize ?? 0) as int,
        uploadedAt: a.uploadedAt as DateTime,
      );

  // ── Warm cache (gọi trước mỗi query cần join tên) ──────────
  Future<void> warmCache() async {
    // Load departments first (needed by mapUser for deptName join)
    if (deptCache.isEmpty) {
      final depts = await client.reference.getDepartments();
      deptCache = depts.map((d) => Department(deptId: d.id ?? 0, deptName: d.name)).toList();
    }
    await Future.wait([
      if (userCache.isEmpty)
        client.auth.getUsers().then((us) {
          userCache = us.map(mapUser).toList();
        }),
      if (categoryCache.isEmpty)
        client.reference.getCategories().then((cs) {
          categoryCache = cs.map(mapCategory).toList();
        }),
      if (assetCache.isEmpty)
        client.reference.getAssets().then((as_) {
          assetCache = as_.map(mapAsset).toList();
        }),
    ]);
  }
}
