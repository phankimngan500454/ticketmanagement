// =============================================================
// feedback_detail_screen.dart
// Màn hình Chi tiết Góp ý — đơn giản, không có deadline/SLA/IT
// =============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/ticket_comment.dart';
import '../../models/ticket_attachment.dart';
import '../../models/user.dart';
import 'package:flutter/services.dart';

class FeedbackDetailScreen extends StatefulWidget {
  final Ticket ticket;
  final User currentUser;
  final bool isEmbedded;

  const FeedbackDetailScreen({
    super.key,
    required this.ticket,
    required this.currentUser,
    this.isEmbedded = false,
  });

  @override
  State<FeedbackDetailScreen> createState() => _FeedbackDetailScreenState();
}

class _FeedbackDetailScreenState extends State<FeedbackDetailScreen> {
  final _repo = TicketRepository.instance;
  final _noteCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  late Ticket _ticket;
  List<TicketComment> _comments = [];
  List<TicketAttachmentModel> _attachments = [];
  bool _loading = true;
  bool _uploadingFile = false;
  Timer? _refreshTimer;

  bool get _isReopenMedical => _ticket.ticketType == 'reopen_medical';

  List<TicketAttachmentModel> get _initialAttachments =>
      _attachments.where((a) => a.uploadedAt.difference(_ticket.createdAt).inMinutes <= 2).toList();

  List<TicketAttachmentModel> get _chatAttachments =>
      _attachments.where((a) => a.uploadedAt.difference(_ticket.createdAt).inMinutes > 2).toList();

  List<dynamic> get _chatItems {
    final list = <dynamic>[..._comments, ..._chatAttachments];
    list.sort((a, b) {
      final dtA = a is TicketComment ? a.createdAt : (a as TicketAttachmentModel).uploadedAt;
      final dtB = b is TicketComment ? b.createdAt : (b as TicketAttachmentModel).uploadedAt;
      return dtA.compareTo(dtB);
    });
    return list;
  }

  Color get _themeColor => _isReopenMedical ? const Color(0xFF2563EB) : const Color(0xFF00897B);
  Color get _themeDark => _isReopenMedical ? const Color(0xFF1D4ED8) : const Color(0xFF00695C);
  String get _typeLabel => _isReopenMedical ? 'Mở lại bệnh án' : 'Góp ý';
  String get _typePrefix => _isReopenMedical ? '#BA' : '#GY';

  Map<String, String> get _statusMap => _isReopenMedical ? {
    'Open': 'Chờ duyệt',
    'Resolved': 'Đã duyệt',
    'Pending': 'Đang mở BA',
    'WaitingConfirmation': 'Chờ đóng BA',
    'Closed': 'Đã đóng BA',
    'Cancelled': 'Từ chối',
  } : {
    'Open': 'Đang xử lý',
    'Pending': 'Đang xem xét',
    'Resolved': 'Đã tiếp nhận',
    'Cancelled': 'Đã huỷ',
  };

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFF3B82F6);
      case 'Pending': return const Color(0xFFF59E0B);
      case 'WaitingConfirmation': return const Color(0xFFE67E22);
      case 'Resolved': return const Color(0xFF10B981);
      case 'Closed': return const Color(0xFF64748B);
      case 'Cancelled': return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _ticket = widget.ticket;
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _noteCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _repo.getComments(_ticket.ticketId),
        _repo.getTicketById(_ticket.ticketId).then((t) => t ?? _ticket).catchError((_) => _ticket),
        _repo.getAttachments(_ticket.ticketId),
      ]);
      if (mounted) {
        setState(() {
          _comments = List<TicketComment>.from(results[0] as List);
          _ticket = results[1] as Ticket;
          _attachments = List<TicketAttachmentModel>.from(results[2] as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── XỬ LÝ FILE ĐÍNH KÈM ──────────────────────────────────────
  Future<void> _pickAndUploadFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    if (file.size > 5 * 1024 * 1024) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18), SizedBox(width: 8), Expanded(child: Text('File không được vượt quá 5MB'))]),
          backgroundColor: Colors.red,
        ));
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
        setState(() {
          _attachments.add(attachment);
          _uploadingFile = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [const Icon(Icons.attach_file_rounded, color: Colors.white, size: 18), const SizedBox(width: 8), Expanded(child: Text('Đã đính kèm: ${file.name}'))]),
          backgroundColor: _themeColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Row(children: [Icon(Icons.error_outline, color: Colors.white, size: 18), SizedBox(width: 8), Expanded(child: Text('Đã xảy ra lỗi, vui lòng thử lại!'))]),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _deleteAttachment(TicketAttachmentModel a) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá file đính kèm?'),
        content: Text(a.fileName),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Xoá', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await _repo.deleteAttachment(a.id);
    if (mounted) setState(() => _attachments.removeWhere((x) => x.id == a.id));
  }

  String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
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

  void _viewAttachment(TicketAttachmentModel a) {
    if (!a.isImage) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${a.fileName} (${a.fileSizeLabel}) — chỉ xem trực tiếp được ảnh'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    final bytes = base64Decode(a.fileData);
    showDialog(
      context: context,
      builder: (ctx) {
        final maxH = MediaQuery.of(ctx).size.height * 0.85;
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(a.fileName, style: const TextStyle(fontSize: 14)),
                  backgroundColor: _themeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  toolbarHeight: 44,
                  automaticallyImplyLeading: false,
                  actions: [
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                  ],
                ),
                Flexible(child: InteractiveViewer(child: Image.memory(bytes, fit: BoxFit.contain))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _attachmentBubble(TicketAttachmentModel a) {
    final isMe = a.uploaderId == widget.currentUser.userId;
    final isOwner = isMe || _isManager;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 14, backgroundColor: _themeColor.withValues(alpha: 0.1),
              child: const Icon(Icons.person, size: 14)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isMe ? _themeColor.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _viewAttachment(a),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: a.isImage
                          ? Image.memory(base64Decode(a.fileData), width: 200, fit: BoxFit.cover)
                          : Container(
                              width: 200, padding: const EdgeInsets.all(12),
                              color: Colors.grey.shade100,
                              child: Row(
                                children: [
                                  const Icon(Icons.insert_drive_file, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(a.fileName, maxLines: 1, overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                    ),
                  ),
                  if (isOwner)
                    InkWell(
                      onTap: () => _deleteAttachment(a),
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(radius: 14, backgroundColor: _themeColor.withValues(alpha: 0.1),
              child: Text(widget.currentUser.fullName[0].toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _themeColor))),
          ],
        ],
      ),
    );
  }

  Future<void> _sendNote() async {
    final text = _noteCtrl.text.trim();
    if (text.isEmpty) return;
    
    // Web fix: delay clear to avoid 'Range end x is out of text of length 0'
    Future.delayed(Duration.zero, () {
      if (mounted) _noteCtrl.clear();
    });
    try {
      final comment = await _repo.addComment(
        ticketId: _ticket.ticketId,
        userId: widget.currentUser.userId,
        commentText: text,
      );
      setState(() => _comments.add(comment));
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lỗi gửi ghi chú!'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    try {
      final updated = await _repo.updateStatus(_ticket.ticketId, newStatus);
      if (mounted) {
        setState(() => _ticket = updated);
        
        String msg = '✅ Cập nhật thành công.';
        if (_isReopenMedical) {
          switch (newStatus) {
            case 'Resolved': msg = '✅ Đã duyệt yêu cầu mở lại bệnh án.'; break;
            case 'Pending': msg = '✅ Hồ sơ chuyển sang trạng thái "Đang mở BA" cho bác sĩ.'; break;
            case 'WaitingConfirmation': msg = '✅ Đã xác nhận sửa xong. Chờ đóng bệnh án.'; break;
            case 'Cancelled': msg = '🚫 Yêu cầu mở lại bệnh án đã bị từ chối.'; break;
            case 'Closed': msg = '🔒 Hoàn tất: Bệnh án đã được đóng và khóa lại thành công.'; break;
          }
        } else {
          switch (newStatus) {
            case 'Pending': msg = '✅ Đã chuyển góp ý sang trạng thái "Đang xem xét".'; break;
            case 'Resolved': msg = '✅ Đã xử lý xong góp ý này.'; break;
            case 'Cancelled': msg = '🚫 Đã hủy/từ chối góp ý này.'; break;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
          backgroundColor: _statusColor(newStatus),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Lỗi cập nhật trạng thái! Vui lòng thử lại.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  // ── Dialog đóng bệnh án (có nhập chi phí chênh lệch) ──────────
  Future<void> _showCloseMedicalDialog() async {
    final TextEditingController costController = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: Color(0xFF78909C)),
              SizedBox(width: 8),
              Text('Đóng bệnh án', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_affectsFinance) ...[
                const Text('Nhập chi phí chênh lệch để thông báo cho người dùng (nếu có, có thể bỏ trống).', style: TextStyle(fontSize: 13, height: 1.4)),
                const SizedBox(height: 16),
                TextField(
                  controller: costController,
                  decoration: InputDecoration(
                    labelText: 'Chi phí chênh lệch (VNĐ)',
                    hintText: 'VD: 50.000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.monetization_on_outlined, color: Colors.orange),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ] else ...[
                const Text('Bác sĩ đã hoàn tất việc cập nhật hồ sơ. Bạn có chắc chắn muốn đóng và khóa lại bệnh án này không?', style: TextStyle(fontSize: 14, height: 1.4)),
              ]
            ],
          ),
          actions: [
            if (isSubmitting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF78909C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  setS(() => isSubmitting = true);
                  final cost = _affectsFinance ? costController.text.trim() : '';

                  // Gửi comment thông báo chi phí chênh lệch (nếu có)
                  if (cost.isNotEmpty) {
                    try {
                      final senderRole = 'Tài chính';
                      final comment = await _repo.addComment(
                        ticketId: _ticket.ticketId,
                        userId: widget.currentUser.userId,
                        commentText: '💰 Thông báo từ $senderRole:\nPhát sinh chi phí chênh lệch: $cost VNĐ',
                      );
                      if (mounted) {
                        setState(() => _comments.add(comment));
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (_scrollCtrl.hasClients) {
                            _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                          }
                        });
                      }
                    } catch (_) {} // Ignore comment error
                  }

                  // Lưu costDifference vào DB (trường riêng cho thống kê)
                  try {
                    if (cost.isNotEmpty) {
                      final double? parsedCost = double.tryParse(cost.replaceAll(RegExp(r'[^0-9.]'), ''));
                      if (parsedCost != null) {
                        await _repo.updateCostDifference(_ticket.ticketId, parsedCost);
                      }
                    }

                    // Đóng bệnh án → Closed (khác với Cancelled = từ chối)
                    final updated = await _repo.updateStatus(_ticket.ticketId, 'Closed');
                    if (mounted && context.mounted) {
                      setState(() => _ticket = updated);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('🔒 Đã đóng bệnh án thành công!'),
                          backgroundColor: const Color(0xFF43A047),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (e) {
                    setS(() => isSubmitting = false);
                    if (mounted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Đã xảy ra lỗi, vui lòng thử lại!'),
                          backgroundColor: Colors.red.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Đóng bệnh án'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  void _showRejectDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối yêu cầu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vui lòng nhập lý do từ chối để người dùng biết mạch lạc:', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ví dụ: Thiếu thông tin, không hợp lệ...',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Hủy', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            onPressed: () async {
              FocusScope.of(ctx).unfocus(); // Unfocus to prevent web cursor crashes
              Navigator.pop(ctx);
              final reason = ctrl.text.trim();
              ctrl.dispose(); // clean up memory

              if (reason.isNotEmpty) {
                // Send a note internally so the user sees it in the chat
                try {
                  final comment = await _repo.addComment(
                    ticketId: _ticket.ticketId,
                    userId: widget.currentUser.userId,
                    commentText: '🚫 Lý do từ chối: $reason',
                  );
                  if (mounted) {
                    setState(() => _comments.add(comment));
                  }
                } catch (e) {
                  // ignore failure to send note
                }
              }
              _updateStatus('Cancelled');
            },
            child: const Text('Xác nhận từ chối', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Xóa ticket (chỉ khi Open, chưa duyệt) ──────────────────
  Future<void> _deleteTicket() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Xóa yêu cầu?'),
          ],
        ),
        content: const Text(
          'Bạn có chắc muốn xóa yêu cầu này không?\nHành động này không thể hoàn tác.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Không', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final result = await _repo.deleteTicket(_ticket.ticketId);
      if (result && mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('🗑️ Đã xóa yêu cầu'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        if (context.canPop()) {
          context.pop(true);
        } else {
          context.go(widget.currentUser.role == 'Admin' ? '/admin' : widget.currentUser.role == 'Manager' ? '/manager' : '/customer');
        }
      } else if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể xóa (yêu cầu đã được duyệt)'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã xảy ra lỗi, vui lòng thử lại!'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // ── Chỉnh sửa ticket (chỉ khi Open) ──────────────────
  void _editTicket() {
    // Parse existing fields from description
    final lines = _ticket.description.split('\n');
    String mvp = '', requester = '', phone = '', reason = '';
    bool affectsFinance = false;
    bool parsingReason = false;
    final List<String> reasonLines = [];

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (line.contains('Lý do mở lại') || parsingReason) {
        if (line.contains('Lý do mở lại') && line.contains(':')) {
          final afterColon = line.substring(line.indexOf(':') + 1).trim();
          if (afterColon.isNotEmpty) reasonLines.add(afterColon);
          parsingReason = true;
        } else {
          reasonLines.add(line);
        }
        continue;
      }
      final colonIdx = line.indexOf(':');
      if (colonIdx > 0) {
        final key = line.substring(0, colonIdx).replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '').trim().toLowerCase();
        final value = line.substring(colonIdx + 1).trim();
        if (key.contains('viện phí') || key.contains('mvp')) mvp = value;
        else if (key.contains('người yêu cầu')) requester = value;
        else if (key.contains('sđt') || key.contains('điện thoại')) phone = value;
        else if (key.contains('tài chính')) affectsFinance = value.toUpperCase() == 'CÓ';
      }
    }
    reason = reasonLines.join('\n').trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final mvpCtrl = TextEditingController(text: mvp);
        final requesterCtrl = TextEditingController(text: requester);
        final phoneCtrl = TextEditingController(text: phone);
        final reasonCtrl = TextEditingController(text: reason);
        final patientCtrl = TextEditingController(text: _ticket.patientName ?? '');
        bool finance = affectsFinance;
        bool submitting = false;

        return StatefulBuilder(
          builder: (ctx, setS) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Row(
              children: [
                Icon(Icons.edit_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text('Chỉnh sửa yêu cầu', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _editField('Mã viện phí', mvpCtrl, Icons.receipt_long_outlined),
                    const SizedBox(height: 12),
                    _editField('Tên bệnh nhân', patientCtrl, Icons.personal_injury_outlined),
                    const SizedBox(height: 12),
                    _editField('Tên người yêu cầu', requesterCtrl, Icons.person_outline),
                    const SizedBox(height: 12),
                    _editField('SĐT', phoneCtrl, Icons.phone_outlined),
                    const SizedBox(height: 12),
                    Text('Lý do mở lại', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Nhập lý do...',
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_outlined, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Text('Ảnh hưởng tài chính', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Switch(
                          value: finance,
                          onChanged: (v) => setS(() => finance = v),
                          activeColor: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              if (submitting)
                const Padding(
                  padding: EdgeInsets.all(10),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else ...[
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    setS(() => submitting = true);
                    try {
                      final newSubject = 'Mở lại bệnh án - MVP: ${mvpCtrl.text.trim()}';
                      final newDesc = [
                        '🏥 Mã viện phí của bệnh nhân: ${mvpCtrl.text.trim()}',
                        '👤 Tên người yêu cầu: ${requesterCtrl.text.trim()}',
                        '📞 SĐT: ${phoneCtrl.text.trim()}',
                        '💰 Ảnh hưởng tài chính: ${finance ? "CÓ" : "KHÔNG"}',
                        '',
                        '📝 Lý do mở lại:',
                        reasonCtrl.text.trim(),
                      ].join('\n');

                      final updated = await _repo.updateTicket(
                        _ticket.ticketId,
                        subject: newSubject,
                        description: newDesc,
                        patientName: patientCtrl.text.trim().isEmpty ? null : patientCtrl.text.trim(),
                      );
                      if (mounted && context.mounted) {
                        setState(() => _ticket = updated);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('✅ Đã cập nhật yêu cầu'),
                            backgroundColor: const Color(0xFF43A047),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      }
                    } catch (e) {
                      setS(() => submitting = false);
                      if (mounted && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Đã xảy ra lỗi, vui lòng thử lại!'),
                            backgroundColor: Colors.red.shade700,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Lưu'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFFF8F9FF),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    final local = dt.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  bool get _isManager => widget.currentUser.role == 'Manager' || widget.currentUser.role == 'Admin';
  bool get _isInsurance => (widget.currentUser.permissions ?? '').contains('insurance');
  bool get _isFinance => (widget.currentUser.permissions ?? '').contains('finance');
  bool get _affectsFinance => _ticket.description.contains('Ảnh hưởng tài chính: CÓ');
  bool get _canOpenCloseBA => _affectsFinance ? _isFinance : _isInsurance;
  bool get _isLocked {
    if (_isReopenMedical) {
      // Bệnh án: khóa khi đã đóng BA (Closed) hoặc từ chối (Cancelled)
      return _ticket.status == 'Closed' || _ticket.status == 'Cancelled';
    }
    return _ticket.status == 'Resolved' || _ticket.status == 'Cancelled';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_ticket.status);
    final themeColor = _themeColor;
    final themeDark = _themeDark;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // ── HEADER ─────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(children: [
                  // Back button
                  if (!widget.isEmbedded)
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          if (widget.currentUser.role == 'Admin') {
                            context.go('/admin');
                          } else {
                            context.go(widget.currentUser.role == 'Manager' ? '/manager' : '/customer');
                          }
                        }
                      },
                    )
                  else
                    const SizedBox(width: 16),
                  
                  if (!widget.isEmbedded) ...[
                    // #GY-xxxx badge
                    Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200)
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_isReopenMedical ? Icons.folder_open_rounded : Icons.feedback_rounded, size: 13, color: themeDark),
                      const SizedBox(width: 4),
                      Text('$_typePrefix-${_ticket.ticketId.toString().padLeft(4, '0')}',
                        style: TextStyle(color: themeDark, fontSize: 13, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  ],
                  const Spacer(),
                  // Edit & Delete buttons (chỉ khi Open = chờ duyệt)
                  if (_ticket.status == 'Open' && (_ticket.requesterId == widget.currentUser.userId || _isManager)) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_rounded, size: 20),
                      color: const Color(0xFF2563EB),
                      tooltip: 'Chỉnh sửa',
                      onPressed: _editTicket,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: Colors.red,
                      tooltip: 'Xóa',
                      onPressed: _deleteTicket,
                    ),
                   ],
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Tiêu đề + trạng thái cùng hàng
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: Text(_ticket.subject,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), height: 1.3)),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                      ),
                      child: Text(
                        _statusMap[_ticket.status] ?? _ticket.status,
                        style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  // Requester info + ngày bên phải
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    CircleAvatar(radius: 13, backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(
                        (_ticket.requesterName ?? '?')[0].toUpperCase(),
                        style: const TextStyle(color: Color(0xFF2563EB), fontSize: 11, fontWeight: FontWeight.bold),
                      )),
                    const SizedBox(width: 8),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_ticket.requesterName ?? 'N/A',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w600)),
                      if (_ticket.requesterDeptName != null)
                        Text(_ticket.requesterDeptName!,
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ])),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(_formatTime(_ticket.createdAt),
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                  ]),
                ]),
              ),
            ]),
          ),
        ),

        // ── BODY ───────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    // ── Nội dung góp ý ──────────────────────────────
                    _sectionCard(
                      icon: Icons.description_outlined,
                      title: 'Nội dung $_typeLabel',
                      child: _buildParsedDescription(_ticket.description),
                    ),

                    // ── Hình ảnh đính kèm ────────────────────────────
                    if (_initialAttachments.isNotEmpty)
                      _sectionCard(
                        icon: Icons.photo_library_outlined,
                        title: 'Đính kèm (${_initialAttachments.length})',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Image thumbnails grid
                          if (_initialAttachments.any((a) => a.isImage))
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              ..._initialAttachments.where((a) => a.isImage).map((a) {
                                final bytes = base64Decode(a.fileData);
                                return GestureDetector(
                                  onTap: () => _viewImage(a.fileName, bytes),
                                  child: Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Stack(children: [
                                        Positioned.fill(child: Image.memory(bytes, fit: BoxFit.cover)),
                                        Positioned(right: 4, bottom: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                );
                              }),
                            ]),
                          // Non-image files
                          ..._initialAttachments.where((a) => !a.isImage).map((a) {
                            return Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(children: [
                                Icon(Icons.attach_file_rounded, size: 16, color: _themeColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(a.fileName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis)),
                                Text(a.fileSizeLabel,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                              ]),
                            );
                          }),
                        ]),
                      ),


                    // ── Xét duyệt (Manager/Admin only) ─────────
                    if (_isManager && !_isLocked && (_isReopenMedical ? _ticket.status == 'Open' : true))
                      _sectionCard(
                        icon: Icons.fact_check_rounded,
                        title: _isReopenMedical ? 'Phê duyệt yêu cầu' : 'Tiếp nhận góp ý',
                        child: Row(
                          children: [
                            Expanded(child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                                foregroundColor: const Color(0xFFE53935),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _showRejectDialog,
                              icon: const Icon(Icons.close_rounded, size: 18),
                              label: const Text('Từ chối', style: TextStyle(fontWeight: FontWeight.bold)),
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF43A047),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shadowColor: const Color(0xFF43A047).withValues(alpha: 0.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: () => _updateStatus('Resolved'),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: Text(_isReopenMedical ? 'Duyệt yêu cầu' : 'Đã tiếp nhận', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            )),
                          ]
                        ),
                      ),

                    // ══════════════════════════════════════════════════════
                    // WORKFLOW BỆNH ÁN — chỉ cho reopen_medical
                    // Resolved → BH mở BA (Pending) → Customer sửa xong
                    // (WaitingConfirmation) → BH đóng BA (Cancelled)
                    // ══════════════════════════════════════════════════════

                    // ── Bảo hiểm / Tài chính: "Đã mở lại BA" (khi Resolved) ──
                    if (_isReopenMedical && _ticket.status == 'Resolved' && _canOpenCloseBA)
                      _workflowCard(
                        icon: Icons.folder_open_rounded,
                        title: 'Xác nhận mở lại bệnh án',
                        subtitle: 'Yêu cầu đã được duyệt. Nhấn để xác nhận đã mở lại bệnh án cho ${_ticket.requesterName ?? 'người yêu cầu'} sửa.',
                        buttonLabel: 'Đã mở lại bệnh án',
                        buttonColor: const Color(0xFF2563EB),
                        onPressed: () => _updateStatus('Pending'),
                      ),

                    // ── Customer: "Đã sửa xong" (khi Pending = BA đang mở) ──
                    if (_isReopenMedical && _ticket.status == 'Pending' &&
                        _ticket.requesterId == widget.currentUser.userId)
                      _workflowCard(
                        icon: Icons.edit_note_rounded,
                        title: 'Bệnh án đã được mở',
                        subtitle: 'Phòng ban phụ trách đã mở lại bệnh án. Khi sửa xong, nhấn nút bên dưới để thông báo.',
                        buttonLabel: 'Đã sửa xong',
                        buttonColor: const Color(0xFF43A047),
                        onPressed: () => _updateStatus('WaitingConfirmation'),
                      ),

                    // ── Bảo hiểm / Tài chính: "Đóng bệnh án" (khi WaitingConfirmation) ──
                    if (_isReopenMedical && _ticket.status == 'WaitingConfirmation' && _canOpenCloseBA)
                      _workflowCard(
                        icon: Icons.lock_rounded,
                        title: '${_ticket.requesterName ?? 'Người yêu cầu'} đã sửa xong',
                        subtitle: '${_ticket.requesterName ?? 'Người yêu cầu'} đã hoàn tất chỉnh sửa. Nhấn để đóng/khóa lại bệnh án.',
                        buttonLabel: 'Đóng bệnh án',
                        buttonColor: const Color(0xFF78909C),
                        onPressed: _showCloseMedicalDialog,
                      ),

                    // ── Banner khi đã đóng ─────────────────────────
                    if (_isLocked || (!_isReopenMedical && _ticket.status == 'Resolved'))
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: statusColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(children: [
                          Icon(
                            _ticket.status == 'Closed'
                                ? Icons.lock_rounded
                                : _ticket.status == 'Cancelled'
                                    ? Icons.cancel_rounded
                                    : Icons.check_circle_rounded,
                            size: 20, color: statusColor,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(
                            _isReopenMedical && _ticket.status == 'Closed'
                                ? 'Bệnh án đã được đóng/khóa lại thành công.'
                                : _ticket.status == 'Cancelled'
                                    ? '$_typeLabel này đã bị từ chối.'
                                    : '$_typeLabel này đã được xem xét và hoàn thành.',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: statusColor),
                          )),
                        ]),
                      ),

                    // ── Hình ảnh đính kèm ────────────────────────────
                    if (_initialAttachments.isNotEmpty)
                      _sectionCard(
                        icon: Icons.photo_library_outlined,
                        title: 'Đính kèm (${_initialAttachments.length})',
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          // Image thumbnails grid
                          if (_initialAttachments.any((a) => a.isImage))
                            Wrap(spacing: 8, runSpacing: 8, children: [
                              ..._initialAttachments.where((a) => a.isImage).map((a) {
                                final bytes = base64Decode(a.fileData);
                                return GestureDetector(
                                  onTap: () => _viewImage(a.fileName, bytes),
                                  child: Container(
                                    width: 80, height: 80,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(9),
                                      child: Stack(children: [
                                        Positioned.fill(child: Image.memory(bytes, fit: BoxFit.cover)),
                                        Positioned(right: 4, bottom: 4,
                                          child: Container(
                                            padding: const EdgeInsets.all(3),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.5),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                                          ),
                                        ),
                                      ]),
                                    ),
                                  ),
                                );
                              }),
                            ]),
                          // Non-image files
                          ..._initialAttachments.where((a) => !a.isImage).map((a) {
                            return Container(
                              margin: const EdgeInsets.only(top: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(children: [
                                Icon(Icons.attach_file_rounded, size: 16, color: _themeColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(a.fileName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  overflow: TextOverflow.ellipsis)),
                                Text(a.fileSizeLabel,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                              ]),
                            );
                          }),
                        ]),
                      ),

                    // ── Phản hồi / Comments ─────────────────────────
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        const Icon(Icons.chat_bubble_outline, size: 16),
                        const SizedBox(width: 6),
                        Text('Phản hồi khi xảy ra sự cố (${_chatItems.length})',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: themeDark)),
                      ]),
                    ),

                    if (_chatItems.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(child: Text('Chưa có phản hồi nào',
                          style: TextStyle(fontSize: 13, color: Colors.grey[400]))),
                      )
                    else
                      ...(_chatItems.map((item) {
                        if (item is TicketComment) return _commentBubble(item);
                        if (item is TicketAttachmentModel) return _attachmentBubble(item);
                        return const SizedBox.shrink();
                      })),

                    const SizedBox(height: 80), // space for bottom input
                  ],
                ),
        ),

        // ── BOTTOM INPUT ───────────────────────────────────────
        if (!_isLocked)
          Container(
            padding: EdgeInsets.fromLTRB(8, 10, 8, MediaQuery.of(context).padding.bottom + 10),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(children: [
              if (_uploadingFile)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                IconButton(
                  icon: Icon(Icons.image_outlined, color: Colors.grey.shade600),
                  onPressed: _pickAndUploadFile,
                  tooltip: 'Gửi hình ảnh',
                ),
              Expanded(
                child: TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    hintText: 'Viết phản hồi...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF4F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: themeColor, width: 1.5),
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _noteCtrl,
                      builder: (context, value, child) {
                        return value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                onPressed: () => _noteCtrl.clear(),
                                splashRadius: 16,
                                padding: EdgeInsets.zero,
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                  ),
                  style: const TextStyle(fontSize: 14),
                  onSubmitted: (_) => _sendNote(),
                ),
              ),
              const SizedBox(width: 6),
              Material(
                color: themeColor,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _sendNote,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ]),
          )
        else
          Container(
            padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
            decoration: BoxDecoration(
              color: _isLocked && _ticket.status == 'Resolved' ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(
                _ticket.status == 'Resolved' ? Icons.lock_rounded
                    : _ticket.status == 'Closed' ? Icons.lock_outline_rounded
                    : Icons.block_rounded,
                size: 15, color: statusColor,
              ),
              const SizedBox(width: 6),
              Text(
                _ticket.status == 'Resolved'
                    ? '$_typeLabel đã hoàn thành'
                    : _ticket.status == 'Closed'
                        ? '$_typeLabel đã được đóng và khóa thành công'
                        : '$_typeLabel đã bị từ chối',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor),
              ),
            ]),
          ),
      ]),
    );
  }

  // ── HELPER WIDGETS ─────────────────────────────────────────

  Widget _workflowCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color buttonColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: buttonColor.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        Container(
          height: 5,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [buttonColor, buttonColor.withValues(alpha: 0.6)]),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: buttonColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: buttonColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1C1C2E))),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ])),
            ]),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: Icon(icon, size: 18),
                label: Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: onPressed,
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  void _viewImage(String fileName, List<int> bytes) {
    showDialog(context: context, builder: (ctx) {
      final maxH = MediaQuery.of(ctx).size.height * 0.85;
      return Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AppBar(
              title: Text(fileName, style: const TextStyle(fontSize: 14)),
              backgroundColor: _themeColor,
              foregroundColor: Colors.white,
              elevation: 0,
              toolbarHeight: 44,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain)),
            ),
          ]),
        ),
      );
    });
  }

  Widget _sectionCard({required IconData icon, required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _themeColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: _themeColor),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B), letterSpacing: 0.2), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 16),
        child,
      ]),
    );
  }


  Widget _buildParsedDescription(String text) {
    if (text.isEmpty) {
      return Text('Không có nội dung chi tiết.', style: TextStyle(fontSize: 14, color: Colors.grey[400]));
    }
    if (!_isReopenMedical) {
       return Text(text, style: const TextStyle(fontSize: 14.5, height: 1.6, color: Color(0xFF1C1C2E)));
    }
    
    final lines = text.split('\n');
    String mvpValue = '';
    String requesterValue = '';
    String phoneValue = '';
    String financeValue = '';
    String reasonText = '';
    bool parsingReason = false;

    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith('📝') || line.contains('Lý do mở lại:')) {
        parsingReason = true;
        continue;
      }
      if (parsingReason) {
        reasonText += '$line\n';
        continue;
      }
      
      final colonIdx = line.indexOf(':');
      if (colonIdx != -1) {
         final rawLabel = line.substring(0, colonIdx).trim();
         final value = line.substring(colonIdx + 1).trim();
         final label = rawLabel.replaceAll(RegExp(r'[^\w\sÀ-ỹ]'), '').trim().toLowerCase();
         
         if (label.contains('viện phí') || label.contains('mvp') || label.contains('số bệnh án')) {
           mvpValue = value;
         } else if (label.contains('người yêu cầu')) {
           requesterValue = value;
         } else if (label.contains('sđt') || label.contains('điện thoại')) {
           phoneValue = value;
         } else if (label.contains('tài chính')) {
           financeValue = value;
         }
      }
    }

    final patientName = _ticket.patientName?.isNotEmpty == true ? _ticket.patientName! : '';
    final bool isFinanceYes = financeValue.toUpperCase() == 'CÓ';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── Mã viện phí (1 hàng, copy bên cạnh số) ──
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          const Icon(Icons.receipt_long_outlined, size: 18, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Text('Mã viện phí:  ', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          Text(mvpValue, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E40AF))),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: () {
              Clipboard.setData(ClipboardData(text: mvpValue));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('📋 Đã sao chép mã viện phí!', style: TextStyle(color: Colors.white)),
                  backgroundColor: const Color(0xFF2563EB),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.copy_rounded, size: 14, color: Color(0xFF2563EB)),
            ),
          ),
        ]),
      ),

      // ── Tên bệnh nhân ──
      if (patientName.isNotEmpty)
        _infoRow(
          icon: Icons.personal_injury_outlined,
          iconColor: const Color(0xFF5C6BC0),
          label: 'Tên bệnh nhân',
          value: patientName,
        ),

      if (patientName.isEmpty)
        _infoRow(
          icon: Icons.personal_injury_outlined,
          iconColor: Colors.grey,
          label: 'Tên bệnh nhân',
          value: 'Không có',
          valueColor: Colors.grey[400],
          italic: true,
        ),

      // ── Người yêu cầu ──
      _infoRow(
        icon: Icons.person_outline_rounded,
        iconColor: const Color(0xFF7C3AED),
        label: 'Người yêu cầu',
        value: requesterValue,
      ),

      // ── SĐT ──
      _infoRow(
        icon: Icons.phone_outlined,
        iconColor: const Color(0xFF059669),
        label: 'Số điện thoại',
        value: phoneValue,
      ),

      // ── Ảnh hưởng tài chính ──
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isFinanceYes ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isFinanceYes ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0)),
        ),
        child: Row(children: [
          Icon(
            isFinanceYes ? Icons.monetization_on_rounded : Icons.monetization_on_outlined,
            size: 18,
            color: isFinanceYes ? const Color(0xFFD97706) : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 10),
          Text('Ảnh hưởng tài chính:', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isFinanceYes ? const Color(0xFFD97706) : const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFinanceYes ? 'CÓ' : 'KHÔNG',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ]),
      ),

      // ── Lý do mở lại ──
      if (reasonText.trim().isNotEmpty) ...[
        const SizedBox(height: 6),
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF6366F1)),
          ),
          const SizedBox(width: 10),
          const Text('Lý do mở lại', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        ]),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            reasonText.trim(),
            style: const TextStyle(fontSize: 14.5, color: Color(0xFF334155), height: 1.7),
          ),
        ),
      ],
    ]);
  }

  Widget _infoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool italic = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Text('$label:  ', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1E293B),
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _commentBubble(TicketComment c) {
    final isMe = c.userId == widget.currentUser.userId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(radius: 14, backgroundColor: _themeColor.withValues(alpha: 0.1),
              child: Text((c.authorName ?? '?')[0].toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _themeColor))),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              decoration: BoxDecoration(
                color: isMe ? _themeColor.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                border: isMe ? null : Border.all(color: Colors.grey.shade200),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(c.authorName ?? 'N/A',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _themeColor)),
                  ),
                Text(c.commentText, style: const TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFF1C1C2E))),
                const SizedBox(height: 4),
                Text(_relativeTime(c.createdAt),
                  style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ]),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(radius: 14, backgroundColor: _themeColor.withValues(alpha: 0.1),
              child: Text(widget.currentUser.fullName[0].toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _themeColor))),
          ],
        ],
      ),
    );
  }
}
