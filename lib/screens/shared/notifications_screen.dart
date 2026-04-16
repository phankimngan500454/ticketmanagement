import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';

class NotificationsScreen extends StatefulWidget {
  final User currentUser;
  final bool isAdmin;

  const NotificationsScreen({super.key, required this.currentUser, this.isAdmin = false});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = TicketRepository.instance;
  List<Ticket> _notifications = [];
  bool _loading = true;
  Timer? _refreshTimer;

  bool get _isIT => widget.currentUser.role == 'IT';
  bool get _isCustomer => !widget.isAdmin && !_isIT;

  // Permission helpers
  bool get _hasInsurance => (widget.currentUser.permissions ?? '').contains('insurance');
  bool get _hasFinance => (widget.currentUser.permissions ?? '').contains('finance');
  bool get _hasSpecialAccess => _hasInsurance || _hasFinance;

  // Theme colors
  static const _indigo = Color(0xFF3949AB);
  static const _navy = Color(0xFF1A237E);

  Color get _accentColor {
    if (widget.isAdmin) return _navy;
    if (_isIT) return const Color(0xFF00695C);
    return _indigo;
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadNotifications());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final all = await _repo.getAllTickets();
      final sorted = List<Ticket>.from(all)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      List<Ticket> result;
      if (widget.isAdmin) {
        result = sorted;
      } else if (_isIT) {
        result = sorted.where((t) => t.assigneeId == widget.currentUser.userId || t.assigneeId == null).toList();
      } else if (_hasSpecialAccess) {
        // Bảo hiểm / Tài chính: hiện ticket của mình + bệnh án cần xử lý
        result = sorted.where((t) {
          // Ticket do chính mình tạo → luôn hiện
          if (t.requesterId == widget.currentUser.userId) return true;

          // Chỉ hiện bệnh án mở lại (reopen_medical) đã qua duyệt (không phải Open)
          if (t.ticketType != 'reopen_medical') return false;
          if (t.status == 'Open') return false;

          // Tài chính (không có Bảo hiểm): chỉ thấy bệnh án có ảnh hưởng tài chính
          if (_hasFinance && !_hasInsurance) {
            return (t.description).toLowerCase().contains('ảnh hưởng tài chính: có');
          }
          // Bảo hiểm: thấy tất cả bệnh án đã duyệt
          return true;
        }).toList();
      } else {
        result = sorted.where((t) => t.requesterId == widget.currentUser.userId).toList();
      }
      if (mounted) setState(() { _notifications = result; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(Ticket t) {
    if (t.ticketType == 'reopen_medical') {
      switch (t.status) {
        case 'Open': return const Color(0xFF78909C);
        case 'Pending': return const Color(0xFFFB8C00);
        case 'WaitingConfirmation': return const Color(0xFF0097A7);
        case 'Resolved': return const Color(0xFF43A047);
        case 'Cancelled': return const Color(0xFF78909C);
        default: return Colors.grey;
      }
    }
    switch (t.status) {
      case 'Open': return const Color(0xFF78909C);
      case 'Pending': return const Color(0xFFFB8C00);
      case 'Resolved': return const Color(0xFF43A047);
      case 'Cancelled': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  String _statusLabel(Ticket t) {
    if (t.ticketType == 'reopen_medical') {
      switch (t.status) {
        case 'Open': return 'Chờ duyệt';
        case 'Resolved': return 'Đã duyệt';
        case 'Pending': return 'Đang mở BA';
        case 'WaitingConfirmation': return 'Chờ đóng BA';
        case 'Cancelled': return 'Đã đóng BA';
        default: return t.status;
      }
    }
    switch (t.status) {
      case 'Open': return 'Đang xử lý';
      case 'Pending': return 'Đang xem xét';
      case 'Resolved': return 'Đã tiếp nhận';
      case 'Cancelled': return 'Đã huỷ';
      default: return t.status;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    return '${diff.inDays}d trước';
  }

  _NotifInfo _getInfo(Ticket t) {
    final bool isMedical = t.ticketType == 'reopen_medical';
    
    if (isMedical) {
      if (t.status == 'Resolved') {
        return _NotifInfo(icon: Icons.fact_check_rounded, color: const Color(0xFF43A047), message: 'Yêu cầu mở bệnh án đã được duyệt');
      }
      if (t.status == 'Pending') {
        return _NotifInfo(icon: Icons.folder_open_rounded, color: const Color(0xFFFB8C00), message: 'Bệnh án đang được mở để Bác sĩ/KH chỉnh sửa');
      }
      if (t.status == 'WaitingConfirmation') {
        return _NotifInfo(icon: Icons.hourglass_top_rounded, color: const Color(0xFF0097A7), message: 'Đã xác nhận sửa xong – Chờ đóng bệnh án');
      }
      if (t.status == 'Cancelled') {
        return _NotifInfo(icon: Icons.lock_rounded, color: const Color(0xFF78909C), message: 'Bệnh án đã được đóng và khóa lại thành công');
      }
      return _NotifInfo(icon: Icons.folder_shared_outlined, color: Colors.grey, message: 'Yêu cầu mở bệnh án đang xem xét');
    }

    if (t.status == 'WaitingConfirmation') {
      return _NotifInfo(icon: Icons.task_alt_rounded, color: const Color(0xFFF59E0B), message: 'IT đã xử lý xong – Cần xác nhận');
    }
    if (t.assigneeId == null && !_isCustomer) {
      return _NotifInfo(icon: Icons.notification_important_rounded, color: const Color(0xFFE53935), message: 'Chưa phân công – Cần xử lý ngay');
    }
    if (t.status == 'Resolved') {
      return _NotifInfo(icon: Icons.check_circle_outline_rounded, color: const Color(0xFF43A047), message: 'Yêu cầu đã được giải quyết');
    }
    if (t.status == 'Cancelled') {
      return _NotifInfo(icon: Icons.cancel_rounded, color: const Color(0xFFE53935), message: 'Yêu cầu đã bị từ chối/hủy');
    }
    if (t.assigneeId != null && _isCustomer) {
      return _NotifInfo(icon: Icons.build_circle_outlined, color: _indigo, message: '${t.assigneeName ?? "IT"} đang xử lý yêu cầu');
    }
    return _NotifInfo(icon: Icons.confirmation_number_outlined, color: Colors.grey, message: 'Yêu cầu đang được theo dõi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 110,
            backgroundColor: _accentColor,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(Icons.notifications_rounded, size: 20, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Thông báo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const Spacer(),
                  if (!_loading)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${_notifications.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                ],
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_accentColor, _accentColor.withValues(alpha: 0.8)],
                  ),
                ),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: _indigo)),
            )
          else if (_notifications.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.notifications_off_outlined, size: 52, color: Colors.grey[300]),
                  ),
                  const SizedBox(height: 16),
                  Text('Không có thông báo nào', style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('Mọi cập nhật sẽ hiển thị ở đây', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final ticket = _notifications[i];
                    final info = _getInfo(ticket);
                    final statusColor = _statusColor(ticket);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        elevation: 0.8,
                        shadowColor: Colors.black.withValues(alpha: 0.06),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            _refreshTimer?.cancel();
                            await context.push('/ticket/${ticket.ticketId}', extra: ticket);
                            _loadNotifications();
                            _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadNotifications());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              // Icon
                              Container(
                                width: 42, height: 42,
                                decoration: BoxDecoration(
                                  color: info.color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(info.icon, size: 20, color: info.color),
                              ),
                              const SizedBox(width: 12),

                              // Content
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Text(
                                    '${ticket.ticketType == 'reopen_medical' ? '#BA' : ticket.ticketType == 'feedback' ? '#GY' : '#TKT'}-${ticket.ticketId.toString().padLeft(4, '0')}',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: _accentColor),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(_statusLabel(ticket), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor)),
                                  ),
                                  const Spacer(),
                                  Text(_timeAgo(ticket.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey[400])),
                                ]),
                                const SizedBox(height: 4),
                                Text(
                                  ticket.subject,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  info.message,
                                  style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
                                  maxLines: 2, overflow: TextOverflow.ellipsis,
                                ),
                              ])),

                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey[300]),
                            ]),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _notifications.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NotifInfo {
  final IconData icon;
  final Color color;
  final String message;
  const _NotifInfo({required this.icon, required this.color, required this.message});
}
