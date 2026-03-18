import 'package:flutter/material.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import 'ticket_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  final User currentUser;
  final bool isAdmin;

  const NotificationsScreen({Key? key, required this.currentUser, this.isAdmin = false}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repo = TicketRepository.instance;
  List<Ticket> _notifications = [];
  bool _loading = true;

  bool get _isIT => widget.currentUser.role == 'IT';
  bool get _isCustomer => !widget.isAdmin && !_isIT;

  @override
  void initState() { super.initState(); _loadNotifications(); }

  Future<void> _loadNotifications() async {
    final all = await _repo.getAllTickets();
    final sorted = List<Ticket>.from(all)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    List<Ticket> result;
    if (widget.isAdmin) {
      result = sorted;
    } else if (_isIT) {
      result = sorted.where((t) => t.assigneeId == widget.currentUser.userId || t.assigneeId == null).toList();
    } else {
      result = sorted.where((t) => t.requesterId == widget.currentUser.userId).toList();
    }
    if (mounted) setState(() { _notifications = result; _loading = false; });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFFE53935);
      case 'Pending': return const Color(0xFFFB8C00);
      case 'WaitingConfirmation': return const Color(0xFFF59E0B);
      case 'Resolved': return const Color(0xFF43A047);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Open': return 'Đang mở';
      case 'Pending': return 'Chờ xử lý';
      case 'WaitingConfirmation': return 'Chờ xác nhận';
      case 'Resolved': return 'Đã xong';
      default: return s;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }

  String _notifMessage(Ticket t) {
    if (_isCustomer) {
      if (t.status == 'WaitingConfirmation') return '✅ IT đã xử lý xong – Bấm để xác nhận hoàn thành';
      if (t.status == 'Resolved') return '🎉 Yêu cầu đã được giải quyết';
      if (t.assigneeId != null) return '🛠 ${t.assigneeName} đang xử lý yêu cầu của bạn';
      return '⏳ Yêu cầu đang chờ phân công';
    }
    if (_isIT) {
      if (t.assigneeId == null) return '🔔 Ticket mới chưa có người nhận – bấm để nhận xử lý';
      if (t.status == 'WaitingConfirmation') return '⏳ Chờ xác nhận hoàn thành';
      return '📋 Ticket đang được giao cho bạn';
    }
    if (t.assigneeId == null) return '⚠️ Chưa phân công – cần xử lý ngay';
    return '📋 Ticket đang được theo dõi';
  }

  Color _notifBg(Ticket t) {
    if (t.status == 'WaitingConfirmation') return const Color(0xFFFFFBEB);
    if (t.assigneeId == null && !_isCustomer) return const Color(0xFFFFF3E0);
    return Colors.white;
  }

  Color get _headerColor {
    if (_isIT) return const Color(0xFF004D40);
    return const Color(0xFF1A237E);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _headerColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: Text('${_notifications.length} thông báo', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13))),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3949AB)))
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.notifications_none, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Không có thông báo nào', style: TextStyle(color: Colors.grey[500], fontSize: 15)),
                ]))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 72, endIndent: 16),
                  itemBuilder: (ctx, i) {
                    final ticket = _notifications[i];
                    final statusColor = _statusColor(ticket.status);
                    final isUnassigned = ticket.assigneeId == null;
                    final isWaiting = ticket.status == 'WaitingConfirmation';

                    IconData notifIcon = Icons.confirmation_number_outlined;
                    Color notifIconColor = const Color(0xFF3949AB);
                    if (isWaiting) { notifIcon = Icons.task_alt_rounded; notifIconColor = const Color(0xFFF59E0B); }
                    else if (isUnassigned) { notifIcon = Icons.notification_important_rounded; notifIconColor = const Color(0xFFFF6F00); }

                    return Material(
                      color: _notifBg(ticket),
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(ctx, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: ticket, isAdmin: widget.isAdmin, currentUser: widget.currentUser)));
                          _loadNotifications();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(width: 44, height: 44, decoration: BoxDecoration(color: notifIconColor.withOpacity(0.12), shape: BoxShape.circle), child: Icon(notifIcon, size: 20, color: notifIconColor)),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text('#TKT-${ticket.ticketId.toString().padLeft(4, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3949AB))),
                                const SizedBox(width: 8),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                                    child: Text(_statusLabel(ticket.status), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor))),
                              ]),
                              const SizedBox(height: 3),
                              Text(ticket.subject, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(_notifMessage(ticket), style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ])),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text(_timeAgo(ticket.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                              const SizedBox(height: 6),
                              Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                            ]),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
