// =============================================================
// ticket_detail_screen.dart
// Màn hình Chi tiết Yêu cầu (dùng chung cho User & Admin/IT)
// =============================================================

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/ticket_comment.dart';
import '../../models/ticket_attachment.dart';
import '../../models/user.dart';
import '../../models/asset.dart';

// ─────────────────────────────────────────────────────────────
// WIDGET: TicketDetailScreen
//   - [ticket]      : Ticket cần hiển thị chi tiết
//   - [isAdmin]     : true → hiển thị thêm tính năng Admin/IT
//   - [currentUser] : Người dùng đang đăng nhập
// ─────────────────────────────────────────────────────────────
class TicketDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final bool isAdmin;
  final User currentUser;

  const TicketDetailScreen({
    super.key,
    required this.ticket,
    required this.currentUser,
    this.isAdmin = false,
  });

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  // ── Repository & Controllers ─────────────────────────────────
  final _repo = TicketRepository.instance;
  final TextEditingController _chatController = TextEditingController(); // Input chat
  final ScrollController _scrollController = ScrollController();         // Cuộn danh sách chat

  // ── State variables ──────────────────────────────────────────
  late Ticket _ticket;                          // Bản sao ticket (cập nhật khi có thay đổi)
  List<TicketComment> _comments = [];          // Danh sách bình luận / tin nhắn
  List<TicketAttachmentModel> _attachments = []; // Danh sách file đính kèm
  List<User> _itStaff = [];                    // Danh sách nhân viên IT (chỉ Admin cần)
  bool _loadingComments = true;                // Đang tải dữ liệu ban đầu?
  bool _uploadingFile = false;                 // Đang upload file?
  Asset? _linkedAsset;                         // Thông tin thiết bị liên kết đầy đủ
  Timer? _refreshTimer;                        // Auto-refresh realtime

  // ── Theme  ───────────────────────────────────────────────────
  static const Color _themeColor = Color(0xFF3949AB); // Màu chủ đạo (indigo)

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _loadData();
    // Auto-refresh mỗi 10s để cập nhật comments và trạng thái mới nhất
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════
  // TÍNH NĂNG 1 — TẢI DỮ LIỆU BAN ĐẦU
  // Gọi song song: comments + IT staff (Admin) + ticket mới nhất + attachments
  // Sau đó load thêm asset info nếu ticket có assetId
  // ════════════════════════════════════════════════════════════
  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repo.getComments(_ticket.ticketId),
        if (widget.isAdmin) _repo.getITStaff() else Future.value(<User>[]),
        _repo.getTicketById(_ticket.ticketId).then((t) => t ?? _ticket).catchError((_) => _ticket),
        _repo.getAttachments(_ticket.ticketId),
      ]);

      if (mounted) {
        setState(() {
          _comments = List<TicketComment>.from(results[0] as List);
          _itStaff = List<User>.from(results[1] as List);
          _ticket = results[2] as Ticket;
          _attachments = List<TicketAttachmentModel>.from(results[3] as List);
          _loadingComments = false;
        });
        // Load full asset info nếu ticket có assetId
        if (_ticket.assetId != null) {
          try {
            final assets = await _repo.getAssets();
            _linkedAsset = assets.firstWhere(
              (a) => a.assetId == _ticket.assetId,
              orElse: () => Asset(
                assetId: 0, assetName: _ticket.assetName ?? '', assetCode: '',
                assetGroup: '', assetType: '', assetModel: '', status: '', categoryId: null),
            );
            if (mounted) setState(() {});
          } catch (_) {}
        }
      }
    } catch (e) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  // ════════════════════════════════════════════════════════════
  // TÍNH NĂNG 2 — FILE ĐÍNH KÈM
  // 2a. Upload file: chọn file (tối đa 5MB), encode base64, gửi lên server
  // 2b. Xoá file: hiện dialog xác nhận trước khi xoá
  // 2c. Xem ảnh: mở dialog xem ảnh toàn màn hình (InteractiveViewer)
  // 2d. _getMimeType: ánh xạ đuôi file → MIME type
  // ════════════════════════════════════════════════════════════
  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    // 5MB limit
    if (file.size > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ File không được vượt quá 5MB'), backgroundColor: Colors.red));
      }
      return;
    }
    setState(() => _uploadingFile = true);
    try {
      final base64Data = base64Encode(file.bytes!);
      final mimeType = _getMimeType(file.extension ?? 'bin');
      final attachment = await _repo.uploadAttachment(
        ticketId: _ticket.ticketId,
        uploaderId: widget.currentUser.userId,
        fileName: file.name,
        mimeType: mimeType,
        fileData: base64Data,
        fileSize: file.size,
      );
      if (mounted) {
        setState(() { _attachments.add(attachment); _uploadingFile = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('📎 Đã đính kèm: ${file.name}'),
          backgroundColor: const Color(0xFF3949AB),
          behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // 2b. Xoá file đính kèm (yêu cầu xác nhận)
  Future<void> _deleteAttachment(TicketAttachmentModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá file đính kèm?'),
        content: Text(a.fileName),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.deleteAttachment(a.id);
    if (mounted) setState(() => _attachments.removeWhere((x) => x.id == a.id));
  }

  // 2d. Ánh xạ đuôi file → MIME type
  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'gif': return 'image/gif';
      case 'pdf': return 'application/pdf';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      default: return 'application/octet-stream';
    }
  }

  // 2c. Xem file đính kèm (chỉ hỗ trợ xem ảnh trực tiếp)
  void _viewAttachment(TicketAttachmentModel a) {
    if (!a.isImage) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📄 ${a.fileName} (${a.fileSizeLabel}) — chỉ xem trực tiếp được ảnh'),
        behavior: SnackBarBehavior.floating));
      return;
    }
    final bytes = base64Decode(a.fileData);
    showDialog(context: context, builder: (ctx) {
      final maxH = MediaQuery.of(ctx).size.height * 0.85;
      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppBar(
              title: Text(a.fileName, style: const TextStyle(fontSize: 14)),
              backgroundColor: const Color(0xFF3949AB),
              foregroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 44,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx))
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(bytes, fit: BoxFit.contain)),
            ),
          ]),
        ),
      );
    });

  }


  // ════════════════════════════════════════════════════════════
  // TÍNH NĂNG 3 — CHAT / TRAO ĐỔI
  // Gửi bình luận, thêm vào danh sách và cuộn xuống cuối
  // Chat bị khóa khi ticket Cancelled hoặc Resolved
  // ════════════════════════════════════════════════════════════
  Future<void> _sendMessage() async {
    if (_chatController.text.trim().isEmpty) return;
    final text = _chatController.text.trim();
    _chatController.clear();
    final comment = await _repo.addComment(
      ticketId: _ticket.ticketId,
      userId: widget.currentUser.userId,
      commentText: text,
    );
    setState(() => _comments.add(comment));
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  // ════════════════════════════════════════════════════════════
  // TÍNH NĂNG 4 — PHÂN CÔNG NHÂN VIÊN IT (chỉ Admin)
  // Hiện bottom sheet danh sách IT staff, chọn → gọi assignTicket
  // ════════════════════════════════════════════════════════════
  void _showAssignBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('Chọn người xử lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
          const SizedBox(height: 6),
          Text('Phân công nhân viên IT cho ticket này', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const SizedBox(height: 16),
          ..._itStaff.map((staff) => ListTile(
            leading: CircleAvatar(backgroundColor: _themeColor.withValues(alpha: 0.12), child: const Icon(Icons.person, color: _themeColor, size: 20)),
            title: Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Text(staff.deptName ?? '', style: const TextStyle(fontSize: 11)),
            trailing: _ticket.assigneeId == staff.userId
                ? const Icon(Icons.check_circle, color: Color(0xFF43A047))
                : const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () async {
              Navigator.pop(context);
              final updated = await _repo.assignTicket(_ticket.ticketId, staff.userId);
              setState(() => _ticket = updated);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ Đã giao việc cho ${staff.fullName}'),
                  backgroundColor: const Color(0xFF43A047),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
          )),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS — Màu sắc theo Priority & Status
  // ════════════════════════════════════════════════════════════
  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High': return const Color(0xFFE53935);
      case 'Medium': return const Color(0xFFFB8C00);
      default: return const Color(0xFF29B6F6);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFFE53935);
      case 'Pending': return const Color(0xFFFB8C00);
      case 'Resolved': return const Color(0xFF43A047);
      case 'WaitingConfirmation': return const Color(0xFFF59E0B);
      case 'Cancelled': return const Color(0xFF78909C);
      default: return Colors.grey;
    }
  }

  // ════════════════════════════════════════════════════════════
  // TÍNH NĂNG 5 — QUẢN LÝ TRẠNG THÁI TICKET
  // 5a. _cancelTicket    : Customer hủy ticket (→ Cancelled)
  // 5b. _markResolved    : IT/Admin đánh dấu xong (→ WaitingConfirmation)
  // 5c. _customerConfirm : Customer xác nhận (→ Resolved) hoặc mở lại (→ Open)
  //
  // Ticket bị KHÓA (isLocked) khi status = Cancelled hoặc Resolved:
  //   - Ẩn tất cả nút hành động
  //   - Chat input thay bằng banner thông báo
  // ════════════════════════════════════════════════════════════
  Future<void> _cancelTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(children: [
          Icon(Icons.cancel_outlined, color: Color(0xFF78909C)),
          SizedBox(width: 8),
          Text('Hủy yêu cầu?'),
        ]),
        content: const Text(
          'Bạn có chắc muốn hủy yêu cầu này không?\nHành động này không thể hoàn tác.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF78909C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hủy yêu cầu'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final updated = await _repo.updateStatus(_ticket.ticketId, 'Cancelled');
      if (mounted) {
        setState(() => _ticket = updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('🚫 Yêu cầu đã được hủy'),
          backgroundColor: const Color(0xFF78909C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // 5b. IT/Admin: hoàn thành → chờ customer xác nhận
  Future<void> _markResolved() async {
    try {
      final updated = await _repo.updateStatus(_ticket.ticketId, 'WaitingConfirmation');
      if (mounted) {
        setState(() => _ticket = updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✅ Đã gửi yêu cầu xác nhận'),
          backgroundColor: const Color(0xFFF59E0B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // 5c. Customer xác nhận kết quả (true=Resolved, false=mở lại)
  Future<void> _customerConfirm(bool confirm) async {
    try {
      final newStatus = confirm ? 'Resolved' : 'Open';
      final updated = await _repo.updateStatus(_ticket.ticketId, newStatus);
      if (mounted) {
        setState(() => _ticket = updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(confirm ? '✅ Yêu cầu đã được xác nhận hoàn thành' : '🔄 Đã mở lại yêu cầu'),
          backgroundColor: confirm ? const Color(0xFF43A047) : const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  // ════════════════════════════════════════════════════════════
  // TÍNH NĂNG 6 — ĐỀ XUẤT DEADLINE (Customer / IT Staff)
  // Hiện bottom sheet chọn ngày → gọi proposeDeadline
  // Admin sẽ xem xét và duyệt / điều chỉnh (xem _buildDeadlineCard)
  // Bị ẩn khi ticket đã bị khóa (Cancelled / Resolved)
  // ════════════════════════════════════════════════════════════
  void _showProposeDeadlineSheet() {
    DateTime? picked;
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Đề xuất Deadline', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Chọn ngày hoàn thành mong muốn. Admin sẽ xem xét và phê duyệt.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final result = await showDatePicker(
                context: ctx,
                initialDate: _ticket.proposedDeadline ?? now.add(const Duration(days: 3)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
                builder: (c, child) => Theme(data: Theme.of(c).copyWith(
                    colorScheme: const ColorScheme.light(primary: Color(0xFF3949AB))), child: child!),
              );
              if (result != null) setS(() => picked = result);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: picked != null ? const Color(0xFFEEF2FF) : const Color(0xFFF4F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: picked != null ? const Color(0xFF3949AB) : Colors.grey.shade200,
                  width: picked != null ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, size: 18,
                    color: picked != null ? const Color(0xFF3949AB) : Colors.grey[400]),
                const SizedBox(width: 10),
                Text(
                  picked != null ? fmt(picked!) : 'Chọn ngày...',
                  style: TextStyle(fontSize: 14,
                      color: picked != null ? const Color(0xFF1C1C2E) : Colors.grey[500]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 17),
              label: const Text('Gửi đề xuất', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: picked != null ? const Color(0xFF3949AB) : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: picked == null ? null : () async {
                Navigator.pop(ctx);
                try {
                  final updated = await _repo.proposeDeadline(_ticket.ticketId, widget.currentUser.userId, picked!);
                  if (mounted) {
                    setState(() => _ticket = updated);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('📅 Đã gửi đề xuất deadline, chờ Admin phê duyệt'),
                      backgroundColor: const Color(0xFF3949AB),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                  }
                }
              },
            ),
          ),
        ]),
      )),
    );
  }

  // ════════════════════════════════════════════════════════════
  // BUILD — Cấu trúc màn hình
  //
  // Layout: Column gồm 3 phần chính:
  //   [1] Header gradient  : ticket ID, priority, status, title, requester, asset
  //   [2] ListView nội dung:
  //       - SLA Card        (ẩn khi Cancelled/Resolved)
  //       - Mô tả
  //       - Thiết bị liên quan
  //       - Người xử lý    (Admin)
  //       - Nút Hoàn thành (Admin/IT, chỉ Open/Pending, chưa khóa)
  //       - Deadline Card
  //       - Attachment Card
  //       - Nút Hủy yêu cầu (Customer, chỉ Open/Pending, chưa khóa)
  //       - WaitingConfirmation block (Customer, chưa khóa)
  //       - Danh sách chat
  //   [3] Bottom bar:
  //       - isLocked → Banner khóa (xám/xanh)
  //       - !isLocked → Chat input + nút gửi
  // ════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(_ticket.priority);
    final isAssigned = _ticket.assigneeId != null;
    // isLocked: ticket đã kết thúc → khóa mọi tương tác
    final isLocked = _ticket.status == 'Resolved' || _ticket.status == 'Cancelled';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          // Fallback về dashboard theo role
                          final user = TicketRepository.instance.currentUser;
                          if (user?.role == 'Admin') {
                            context.go('/admin');
                          } else if (user?.role == 'IT') {
                            context.go('/it');
                          } else {
                            context.go('/customer');
                          }
                        }
                      },
                    ),
                    const Expanded(child: Text('Chi tiết yêu cầu', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  ]),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('#TKT-${_ticket.ticketId.toString().padLeft(4, '0')}',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(20)),
                        child: Text(_ticket.priority, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(_ticket.status).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _statusColor(_ticket.status).withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          _ticket.status == 'Open' ? 'Đang mở'
                            : _ticket.status == 'Pending' ? 'Chờ xử lý'
                            : _ticket.status == 'Resolved' ? 'Đã xong'
                            : _ticket.status == 'WaitingConfirmation' ? 'Chờ xác nhận'
                            : _ticket.status == 'Cancelled' ? 'Đã hủy'
                            : _ticket.status,
                          style: TextStyle(fontSize: 11, color: _statusColor(_ticket.status), fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Text(_ticket.subject, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.3)),
                    if (_ticket.status == 'Cancelled') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.cancel_outlined, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 5),
                          Text('Yêu cầu này đã bị hủy bởi người dùng',
                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.8))),
                        ]),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(children: [
                      CircleAvatar(radius: 14, backgroundColor: Colors.white.withValues(alpha: 0.2), child: const Icon(Icons.person, color: Colors.white, size: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        // Tên requester
                        Text(
                          _ticket.requesterName ?? widget.currentUser.fullName,
                          style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        // Phòng ban + SĐT + Category + Thời gian
                        Text(
                          [
                            _ticket.requesterDeptName ?? widget.currentUser.deptName ?? '',
                            _ticket.requesterPhone ?? widget.currentUser.phone,
                            _ticket.categoryName ?? '',
                            _formatExactTime(_ticket.createdAt),
                          ].where((s) => s.isNotEmpty).join(' · '),
                          style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                        ),

                      ])),
                    ]),
                    if (_ticket.assetName != null) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        Icon(Icons.devices, size: 14, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 6),
                        Text(_ticket.assetName!, style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                      ]),
                    ],
                  ]),
                ),
              ]),
            ),
          ),

          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.zero,
              children: [
                // ── SLA Card ──────────────────────────────────────────
                Builder(builder: (ctx) {
                  if (_ticket.status == 'Resolved' || _ticket.status == 'Cancelled') {
                    return const SizedBox.shrink();
                  }
                  final hasFinalDeadline = _ticket.finalDeadline != null;
                  final slaHours = _ticket.priority == 'High' ? 4
                      : _ticket.priority == 'Medium' ? 24
                      : 72;
                  final slaDeadline = _ticket.finalDeadline ??
                      _ticket.createdAt.add(Duration(hours: slaHours));
                  final now = DateTime.now();
                  final total = slaDeadline.difference(_ticket.createdAt).inMinutes.toDouble();
                  final elapsed = now.difference(_ticket.createdAt).inMinutes.toDouble();
                  final progress = (elapsed / total).clamp(0.0, 1.0);
                  final remaining = slaDeadline.difference(now);
                  final isOverdue = remaining.isNegative;
                  final isSoon = !isOverdue && remaining.inHours <= 4;
                  final barColor = isOverdue ? const Color(0xFFE53935)
                      : isSoon ? const Color(0xFFFB8C00)
                      : const Color(0xFF43A047);
                  String remainStr;
                  if (isOverdue) {
                    final abs = remaining.abs();
                    remainStr = abs.inHours >= 1
                        ? 'Trễ ${abs.inHours}h ${abs.inMinutes % 60}p'
                        : 'Trễ ${abs.inMinutes}p';
                  } else {
                    remainStr = remaining.inHours >= 1
                        ? 'Còn ${remaining.inHours}h ${remaining.inMinutes % 60}p'
                        : 'Còn ${remaining.inMinutes}p';
                  }
                  final dlLabel = '${slaDeadline.day.toString().padLeft(2,'0')}/${slaDeadline.month.toString().padLeft(2,'0')} '
                      '${slaDeadline.hour.toString().padLeft(2,'0')}:${slaDeadline.minute.toString().padLeft(2,'0')}';

                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: barColor.withValues(alpha: 0.35)),
                      boxShadow: [BoxShadow(color: barColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Icon(isOverdue ? Icons.warning_rounded : Icons.timer_outlined,
                            size: 16, color: barColor),
                        const SizedBox(width: 6),
                        Text('SLA / Thời hạn xử lý',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: barColor)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(remainStr,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: barColor)),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.event_rounded, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          hasFinalDeadline ? 'Deadline đã xác nhận: $dlLabel' : 'SLA tự động ($slaHours giờ): $dlLabel',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ]),
                    ]),
                  );
                }),

                // ── Card: Vị trí hỗ trợ (Phòng ban + Số phòng) ──────────
                Builder(builder: (ctx) {
                  final dept = _ticket.requesterDeptName;
                  // Parse số phòng từ description (dòng đầu dạng "📍 Vị trí: ...")
                  final lines = _ticket.description.split('\n');
                  String? locationLine;
                  for (final line in lines) {
                    if (line.trimLeft().startsWith('📍 Vị trí:')) {
                      locationLine = line.replaceFirst(RegExp(r'^📍 Vị trí:\s*'), '').trim();
                      break;
                    }
                  }
                  if (dept == null && locationLine == null) return const SizedBox.shrink();
                  return Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF43A047).withValues(alpha: 0.4)),
                      boxShadow: [BoxShadow(color: const Color(0xFF43A047).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF2E7D32)),
                        SizedBox(width: 6),
                        Text('Vị trí hỗ trợ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32))),
                        SizedBox(width: 6),
                        Text('— IT đến đây để hỗ trợ',
                          style: TextStyle(fontSize: 11, color: Color(0xFF388E3C))),
                      ]),
                      const SizedBox(height: 10),
                      if (dept != null)
                        Row(children: [
                          const Icon(Icons.business_rounded, size: 14, color: Color(0xFF388E3C)),
                          const SizedBox(width: 8),
                          Text('Phòng ban: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          Expanded(child: Text(dept,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)))),
                        ]),
                      if (dept != null && locationLine != null) const SizedBox(height: 6),
                      if (locationLine != null)
                        Row(children: [
                          const Icon(Icons.meeting_room_rounded, size: 14, color: Color(0xFF388E3C)),
                          const SizedBox(width: 8),
                          Text('Số phòng: ', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          Expanded(child: Text(locationLine,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)))),
                        ]),
                    ]),
                  );
                }),

                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Row(children: [
                      Icon(Icons.description_outlined, size: 16, color: Color(0xFF3949AB)),
                      SizedBox(width: 6),
                      Text('Mô tả', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3949AB))),
                    ]),
                    const SizedBox(height: 8),
                    // Lọc bỏ dòng "📍 Vị trí:" khỏi mô tả (đã hiển thị riêng ở card trên)
                    Builder(builder: (ctx) {
                      final cleaned = _ticket.description
                          .split('\n')
                          .where((l) => !l.trimLeft().startsWith('📍 Vị trí:'))
                          .join('\n')
                          .trim();
                      return Text(cleaned.isNotEmpty ? cleaned : _ticket.description,
                        style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.5));
                    }),
                  ]),
                ),

                // ── Thiết bị liên quan ────────────────────
                if (_ticket.assetId != null)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF6D4C41).withValues(alpha: 0.25)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Row(children: [
                        Icon(Icons.devices_rounded, size: 16, color: Color(0xFF6D4C41)),
                        SizedBox(width: 6),
                        Text('Thiết bị liên quan',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6D4C41))),
                      ]),
                      const SizedBox(height: 10),
                      if (_linkedAsset != null) ...[
                        _assetInfoRow(Icons.label_rounded, 'Tên thiết bị', _linkedAsset!.assetName),
                        if (_linkedAsset!.assetType.isNotEmpty)
                          _assetInfoRow(Icons.category_rounded, 'Loại', _linkedAsset!.assetType),
                        if (_linkedAsset!.assetModel.isNotEmpty)
                          _assetInfoRow(Icons.info_outline_rounded, 'Model', _linkedAsset!.assetModel),
                        if (_linkedAsset!.assetCode.isNotEmpty)
                          _assetInfoRow(Icons.qr_code_2_rounded, 'Mã / Serial', _linkedAsset!.assetCode),
                      ] else
                        Text(_ticket.assetName ?? '#${_ticket.assetId}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ]),
                  ),

                if (widget.isAdmin)
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white, borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isAssigned ? const Color(0xFF43A047).withValues(alpha: 0.3) : const Color(0xFFE53935).withValues(alpha: 0.3)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAssigned ? const Color(0xFF43A047).withValues(alpha: 0.1) : const Color(0xFFE53935).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.support_agent, color: isAssigned ? const Color(0xFF43A047) : const Color(0xFFE53935), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Người xử lý', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                        const SizedBox(height: 2),
                        Text(_ticket.assigneeName ?? 'CHƯA PHÂN CÔNG',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                color: isAssigned ? const Color(0xFF43A047) : const Color(0xFFE53935))),
                      ])),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.manage_accounts, size: 15),
                        label: Text(isAssigned ? 'Đổi người' : 'Giao việc'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _themeColor, side: const BorderSide(color: _themeColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: _showAssignBottomSheet,
                      ),
                    ]),
                  ),

                if (!isLocked &&
                    (widget.isAdmin || widget.currentUser.role == 'IT') &&
                    isAssigned &&
                    (_ticket.status == 'Open' || _ticket.status == 'Pending'))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Hoàn thành & Gửi xác nhận'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: _markResolved,
                      ),
                    ),
                  ),

                // ── Deadline Card ─────────────────────────
                _buildDeadlineCard(),

                // ── Attachment Card ────────────────────────
                _buildAttachmentSection(),

                // ── Nút Hủy yêu cầu (Customer, chỉ khi Open/Pending, chưa khóa) ──
                if (!isLocked &&
                    !widget.isAdmin && widget.currentUser.role != 'IT' &&
                    (_ticket.status == 'Open' || _ticket.status == 'Pending'))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, size: 17),
                        label: const Text('Hủy yêu cầu'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF78909C),
                          side: const BorderSide(color: Color(0xFF78909C)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        onPressed: _cancelTicket,
                      ),
                    ),
                  ),

                if (!isLocked && !widget.isAdmin && widget.currentUser.role != 'IT' && _ticket.status == 'WaitingConfirmation')
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: const Color(0xFFF59E0B).withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
                    ),
                    child: Column(children: [
                      Container(height: 5, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.vertical(top: Radius.circular(18)))),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                        child: Column(children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.task_alt_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('IT đã hoàn thành xử lý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1C1C2E))),
                              const SizedBox(height: 3),
                              Text('${_ticket.assigneeName ?? 'Nhân viên IT'} đã gửi kết quả xử lý', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                            ])),
                          ]),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3))),
                            child: const Row(children: [
                              Icon(Icons.help_outline_rounded, color: Color(0xFFF59E0B), size: 16),
                              SizedBox(width: 8),
                              Expanded(child: Text('Vấn đề của bạn đã được giải quyết chưa?', style: TextStyle(fontSize: 13, color: Color(0xFF92400E), fontWeight: FontWeight.w500))),
                            ]),
                          ),
                          const SizedBox(height: 14),
                          Row(children: [
                            Expanded(child: DecoratedBox(
                              decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]), borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: const Color(0xFF43A047).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]),
                              child: ElevatedButton.icon(
                                onPressed: () => _customerConfirm(true),
                                icon: const Icon(Icons.check_rounded, size: 17),
                                label: const Text('Xác nhận xong'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: OutlinedButton.icon(
                              onPressed: () => _customerConfirm(false),
                              icon: const Icon(Icons.refresh_rounded, size: 17),
                              label: const Text('Mở lại'),
                              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE53935), side: const BorderSide(color: Color(0xFFE53935)), backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.05), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            )),
                          ]),
                        ]),
                      ),
                    ]),
                  ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Row(children: [
                    const Icon(Icons.chat_bubble_outline, size: 16, color: Color(0xFF3949AB)),
                    const SizedBox(width: 6),
                    Text('Trao đổi (${_comments.length})', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF3949AB))),
                  ]),
                ),

                if (_loadingComments)
                  const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                else if (_comments.isEmpty)
                  Padding(padding: const EdgeInsets.all(24), child: Center(child: Text('Chưa có tin nhắn nào. Hãy bắt đầu trao đổi!', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic), textAlign: TextAlign.center)))
                else
                  ..._comments.map((comment) {
                    final isMe = comment.userId == widget.currentUser.userId;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF3949AB).withValues(alpha: 0.1),
                              child: (comment.authorName != null && comment.authorName!.isNotEmpty)
                                  ? Text(comment.authorName![0].toUpperCase(),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)))
                                  : const Icon(Icons.person, size: 16, color: Color(0xFF3949AB)),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe) Padding(padding: const EdgeInsets.only(bottom: 4, left: 4), child: Text(comment.authorName ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w600))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? const Color(0xFF3949AB) : Colors.white,
                                  borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4), bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18)),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.07), blurRadius: 6, offset: const Offset(0, 2))],
                                ),
                                child: Text(comment.commentText, style: TextStyle(fontSize: 13, color: isMe ? Colors.white : const Color(0xFF1C1C2E), height: 1.4)),
                              ),
                              Padding(padding: const EdgeInsets.only(top: 4, left: 4, right: 4), child: Text(_formatTime(comment.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[400]))),
                            ],
                          )),
                          if (isMe) ...[
                            const SizedBox(width: 8),
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: const Color(0xFF3949AB),
                              child: (widget.currentUser.fullName.isNotEmpty)
                                  ? Text(widget.currentUser.fullName[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white))
                                  : const Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                const SizedBox(height: 80),
              ],
            ),
          ),

          if (isLocked)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              decoration: BoxDecoration(
                color: _ticket.status == 'Cancelled'
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFFF1F8E9),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, -2))],
              ),
              child: SafeArea(
                top: false,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                    _ticket.status == 'Cancelled' ? Icons.lock_rounded : Icons.check_circle_rounded,
                    size: 16,
                    color: _ticket.status == 'Cancelled' ? const Color(0xFF78909C) : const Color(0xFF43A047),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _ticket.status == 'Cancelled'
                        ? 'Yêu cầu đã bị hủy — không thể tương tác'
                        : 'Yêu cầu đã hoàn thành — không thể tương tác',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _ticket.status == 'Cancelled' ? const Color(0xFF78909C) : Colors.green[700],
                    ),
                  ),
                ]),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))]),
              child: SafeArea(top: false, child: Row(children: [
                Expanded(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: const Color(0xFFF0F2F8), borderRadius: BorderRadius.circular(24)),
                  child: TextField(controller: _chatController, maxLines: null, decoration: InputDecoration(hintText: 'Nhập tin nhắn...', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 10))),
                )),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF3949AB)]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF3949AB).withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))]),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ])),
            ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // HELPERS — Định dạng thời gian
  // _formatTime     : hiển thị tương đối (vừa xong / x phút trước / ...)
  // _formatExactTime: hiển thị HH:mm:ss dd/MM/yyyy
  // ════════════════════════════════════════════════════════════
  // Thời gian tương đối cho timestamp tin nhắn
  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  // Thời gian chính xác cho header ticket
  String _formatExactTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')} ${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  // ════════════════════════════════════════════════════════════
  // TÍNH NĂNG 7 — ADMIN: DUYỆT / ĐIỀU CHỈNH DEADLINE
  // 7a. _approveDeadline        : Admin duyệt đề xuất deadline của user
  // 7b. _showAdjustDeadlineSheet: Admin tự chọn ngày khác (ghi đè đề xuất)
  //
  // Deadline có 3 trạng thái:
  //   - Pending  : User đề xuất, Admin chưa xử lý → hiện nút Duyệt / Điều chỉnh
  //   - Approved : Admin đã duyệt (finalDeadline = proposedDeadline)
  //   - Adjusted : Admin tự điều chỉnh ngày khác
  // ════════════════════════════════════════════════════════════
  // 7a. Duyệt deadline đề xuất của user
  Future<void> _approveDeadline() async {
    try {
      final updated = await _repo.approveDeadline(_ticket.ticketId, 'approve');
      if (mounted) {
        setState(() => _ticket = updated);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Đã phê duyệt deadline'),
          backgroundColor: Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
      }
    }
  }

  // 7b. Admin tự chọn deadline khác (có thể kèm ghi chú)
  void _showAdjustDeadlineSheet() {
    DateTime? picked;
    final noteCtrl = TextEditingController();
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Điều chỉnh Deadline', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Chọn ngày deadline cuối cùng. Sẽ ghi đè đề xuất của user.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final result = await showDatePicker(
                context: ctx,
                initialDate: _ticket.proposedDeadline ?? now.add(const Duration(days: 3)),
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
                builder: (c, child) => Theme(data: Theme.of(c).copyWith(
                    colorScheme: const ColorScheme.light(primary: Color(0xFF3949AB))), child: child!),
              );
              if (result != null) setS(() => picked = result);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: picked != null ? const Color(0xFFEEF2FF) : const Color(0xFFF4F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: picked != null ? const Color(0xFF3949AB) : Colors.grey.shade200,
                  width: picked != null ? 1.5 : 1,
                ),
              ),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, size: 18,
                    color: picked != null ? const Color(0xFF3949AB) : Colors.grey[400]),
                const SizedBox(width: 10),
                Text(
                  picked != null ? fmt(picked!) : 'Chọn ngày điều chỉnh...',
                  style: TextStyle(fontSize: 14,
                      color: picked != null ? const Color(0xFF1C1C2E) : Colors.grey[500]),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Ghi chú Admin
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Ghi chú cho user (tuỳ chọn)...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFFF4F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.tune_rounded, size: 17),
              label: const Text('Xác nhận điều chỉnh', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: picked != null ? const Color(0xFF1976D2) : Colors.grey.shade300,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: picked == null ? null : () async {
                final note = noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim();
                Navigator.pop(ctx);
                try {
                  final updated = await _repo.approveDeadline(
                    _ticket.ticketId, 'adjust',
                    finalDeadline: picked,
                    adminNote: note,
                  );

                  if (mounted) {
                    setState(() => _ticket = updated);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('📅 Đã điều chỉnh deadline'),
                      backgroundColor: Color(0xFF1976D2),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                  }
                }
              },
            ),
          ),
        ]),
      )),
    );
  }

  // ════════════════════════════════════════════════════════════
  // WIDGET BUILDER — _buildAttachmentSection
  // Thẻ card chứa danh sách file đính kèm.
  // - Hiện nút “Thêm file” khi ticket chưa khóa
  // - Gọi _buildAttachmentTile cho từng file
  // ════════════════════════════════════════════════════════════
  Widget _buildAttachmentSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          const Icon(Icons.attach_file_rounded, size: 15, color: _themeColor),
          const SizedBox(width: 6),
          Text('Đính kèm (${_attachments.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _themeColor)),
          const Spacer(),
          if (_uploadingFile)
            const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: _themeColor))
          else if (_ticket.status != 'Resolved' && _ticket.status != 'Cancelled')
            GestureDetector(
              onTap: _pickAndUploadFile,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _themeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.upload_file_rounded, size: 13, color: _themeColor),
                  SizedBox(width: 4),
                  Text('Thêm file', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _themeColor)),
                ]),
              ),
            ),
        ]),
        if (_attachments.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text('Chưa có file nào', style: TextStyle(fontSize: 12, color: Colors.grey[400], fontStyle: FontStyle.italic)),
          )
        else
          ...(_attachments.map((a) => _buildAttachmentTile(a))),
      ]),
    );
  }

  // ────────────────────────────────────────────────────────────
  // WIDGET BUILDER — _buildAttachmentTile
  // Một dòng file: thumbnail/icon + tên + kích thước + nút xóa (nếu là chủ sở hữu)
  // Nhấn vào → gọi _viewAttachment
  // ────────────────────────────────────────────────────────────
  Widget _buildAttachmentTile(TicketAttachmentModel a) {
    final isOwner = a.uploaderId == widget.currentUser.userId || widget.isAdmin;
    IconData icon;
    Color iconColor;
    if (a.isImage) { icon = Icons.image_rounded; iconColor = Colors.teal; }
    else if (a.isPdf) { icon = Icons.picture_as_pdf_rounded; iconColor = Colors.red; }
    else if (a.mimeType.contains('word')) { icon = Icons.description_rounded; iconColor = const Color(0xFF1976D2); }
    else if (a.mimeType.contains('excel') || a.mimeType.contains('spreadsheet')) { icon = Icons.table_chart_rounded; iconColor = Colors.green; }
    else { icon = Icons.insert_drive_file_rounded; iconColor = Colors.grey; }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: () => _viewAttachment(a),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F5FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _themeColor.withValues(alpha: 0.1)),
          ),
          child: Row(children: [
            // Thumbnail / icon
            if (a.isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.memory(base64Decode(a.fileData),
                  width: 36, height: 36, fit: BoxFit.cover),
              )
            else
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.fileName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(a.fileSizeLabel,
                style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ])),
            if (isOwner)
              GestureDetector(
                onTap: () => _deleteAttachment(a),
                child: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                ),
              ),
          ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // WIDGET BUILDER — _buildDeadlineCard
  // Hiển thị trạng thái deadline đề xuất (Pending/Approved/Adjusted).
  // User/IT  : thấy nút “Đề xuất / Cập nhật” (nếu chưa khóa)
  // Admin    : thấy nút “Duyệt / Điều chỉnh” (nếu có đề xuất Pending)
  // ════════════════════════════════════════════════════════════
  Widget _buildDeadlineCard() {
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final canPropose = !widget.isAdmin; // Customer AND IT Staff
    final proposed = _ticket.proposedDeadline;
    final finalDL = _ticket.finalDeadline;
    final status = _ticket.deadlineStatus; // 'Pending' | 'Approved' | 'Adjusted' | null

    // Admin không thấy card nếu chưa có đề xuất nào
    if (proposed == null && widget.isAdmin) return const SizedBox.shrink();

    Color statusColor;
    String statusLabel;
    IconData statusIcon;
    if (status == 'Approved') {
      statusColor = Colors.green;
      statusLabel = 'Đã duyệt';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'Adjusted') {
      statusColor = const Color(0xFF1976D2);
      statusLabel = 'Đã điều chỉnh';
      statusIcon = Icons.tune_rounded;
    } else if (status == 'Pending') {
      statusColor = Colors.orange;
      statusLabel = 'Chờ Admin duyệt';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusColor = Colors.grey;
      statusLabel = '';
      statusIcon = Icons.calendar_today_outlined;
    }

    // Admin: chỉ hiện nút hành động khi deadline đang Pending
    final adminCanAct = widget.isAdmin && proposed != null && status == 'Pending';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: proposed != null ? statusColor.withValues(alpha: 0.3) : Colors.grey.shade200,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header row ─────────────────────────────────────
        Row(children: [
          Icon(Icons.event_note_rounded, size: 15, color: _themeColor),
          const SizedBox(width: 6),
          const Text('Deadline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _themeColor)),
          const Spacer(),
          if (canPropose && _ticket.status != 'Resolved' && _ticket.status != 'Cancelled')
            GestureDetector(
              onTap: _showProposeDeadlineSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _themeColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.edit_calendar_rounded, size: 13, color: _themeColor),
                  const SizedBox(width: 4),
                  Text(proposed == null ? 'Đề xuất' : 'Cập nhật',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _themeColor)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 10),

        // ── Proposed deadline row ───────────────────────────
        if (proposed == null)
          Text('Chưa có đề xuất deadline', style: TextStyle(fontSize: 13, color: Colors.grey[400], fontStyle: FontStyle.italic))
        else ...[
          Row(children: [
            Icon(Icons.person_outline, size: 14, color: Colors.grey[500]),
            const SizedBox(width: 5),
            Text('Đề xuất: ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            Text(fmt(proposed), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E))),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 10, color: statusColor),
                const SizedBox(width: 3),
                Text(statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
              ]),
            ),
          ]),
          if (finalDL != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.admin_panel_settings_rounded, size: 14, color: Colors.grey[500]),
              const SizedBox(width: 5),
              Text('Admin quyết định: ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              Text(fmt(finalDL), style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: status == 'Adjusted' ? const Color(0xFF1976D2) : Colors.green)),
            ]),
          ],

          // ── Admin action buttons ────────────────────────
          if (adminCanAct) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _approveDeadline,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Duyệt'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAdjustDeadlineSheet,
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Điều chỉnh'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1976D2),
                    side: const BorderSide(color: Color(0xFF1976D2)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ]),
          ],

        ],
      ]),
    );
  }

  // ────────────────────────────────────────────────────────────
  // WIDGET HELPER — _assetInfoRow
  // Dòng hiển thị một thuộc tính thiết bị (icon + label + value)
  // Dùng trong card Thiết bị liên quan
  // ────────────────────────────────────────────────────────────
  Widget _assetInfoRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(children: [
      Icon(icon, size: 14, color: Colors.grey[400]),
      const SizedBox(width: 8),
      Text('$label: ', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      Expanded(child: Text(value,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E)),
        overflow: TextOverflow.ellipsis)),
    ]),
  );
}
