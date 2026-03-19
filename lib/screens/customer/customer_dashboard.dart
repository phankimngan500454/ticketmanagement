import 'package:flutter/material.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import 'create_ticket_screen.dart';
import 'emergency_call_screen.dart';
import '../shared/ticket_detail_screen.dart';
import '../shared/notifications_screen.dart';
import '../auth/login_screen.dart';

class CustomerDashboard extends StatefulWidget {
  final User currentUser;
  const CustomerDashboard({super.key, required this.currentUser});

  @override
  State<CustomerDashboard> createState() => _CustomerDashboardState();
}

class _CustomerDashboardState extends State<CustomerDashboard> {
  final _repo = TicketRepository.instance;
  List<Ticket> _tickets = [];
  bool _loading = true;
  int _navIndex = 1;       // 0=Tất cả, 1=Đang xử lý, 2=Đã xong
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _blue = Color(0xFF1976D2);
  static const _blueDark = Color(0xFF1A237E);

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    try {
      final tickets = await _repo.getTicketsByRequester(widget.currentUser.userId);
      if (mounted) setState(() { _tickets = List.from(tickets); _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Không tải được danh sách: $e'),
          backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFFE53935);
      case 'Pending': return const Color(0xFFFB8C00);
      case 'WaitingConfirmation': return const Color(0xFFF59E0B);
      case 'Resolved': return const Color(0xFF43A047);
      case 'Cancelled': return const Color(0xFF78909C);
      default: return const Color(0xFF3949AB);
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Open': return 'Đang mở';
      case 'Pending': return 'Chờ xử lý';
      case 'WaitingConfirmation': return 'Chờ xác nhận';
      case 'Resolved': return 'Đã xong';
      case 'Cancelled': return 'Đã hủy';
      default: return s;
    }
  }

  List<Ticket> get _filtered {
    final q = _searchQuery.toLowerCase().trim();
    Iterable<Ticket> base = _tickets;
    switch (_navIndex) {
      case 1: base = base.where((t) => t.status == 'Open' || t.status == 'Pending' || t.status == 'WaitingConfirmation'); break;
      case 2: base = base.where((t) => t.status == 'Resolved'); break;
      case 3: base = base.where((t) => t.status == 'Cancelled'); break;
    }
    if (q.isEmpty) return base.toList();
    return base.where((t) =>
        t.subject.toLowerCase().contains(q) ||
        (t.categoryName ?? '').toLowerCase().contains(q) ||
        t.ticketId.toString().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _tickets.where((t) => t.status == 'Open' || t.status == 'Pending' || t.status == 'WaitingConfirmation').length;
    final resolvedCount = _tickets.where((t) => t.status == 'Resolved').length;
    final cancelledCount = _tickets.where((t) => t.status == 'Cancelled').length;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // ── HEADER ─────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_blueDark, Color(0xFF3949AB)],
            ),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            // Top row: avatar + name + notifications
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Xin chào 👋', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(widget.currentUser.fullName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => NotificationsScreen(currentUser: widget.currentUser))),
                ),
                PopupMenuButton<String>(
                  tooltip: '',
                  offset: const Offset(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) {
                    if (v == 'logout') {
                      Navigator.pushAndRemoveUntil(context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        CircleAvatar(radius: 14, backgroundColor: _blue.withValues(alpha: 0.1),
                          child: Text(widget.currentUser.fullName[0],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _blue))),
                        const SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(widget.currentUser.fullName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Text('Đăng xuất', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                        ]),
                      ]),
                    ),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 8, 12, 8),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(widget.currentUser.fullName[0],
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ),
            // Summary stat taps
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(children: [
                _statCard('Tổng', '${_tickets.where((t) => t.status != 'Cancelled').length}', const Color(0xFF90CAF9)),
                const SizedBox(width: 8),
                _statCard('Đang xử lý', '$openCount', const Color(0xFFFFCC80)),
                const SizedBox(width: 8),
                _statCard('Đã xong', '$resolvedCount', const Color(0xFFA5D6A7)),
              ]),
            ),
          ])),
        ),

        // ── EMERGENCY BANNER ───────────────────────────────────
        GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(
                builder: (_) => EmergencyCallScreen(currentUser: widget.currentUser)));
            _loadData();
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [BoxShadow(color: const Color(0xFFE53935).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Expanded(child: Text('🚨 Gọi Khẩn Cấp IT — Nhấn để xem hotline',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.phone_in_talk_rounded, size: 13, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Gọi', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),
            ]),
          ),
        ),

        // ── SEARCH BAR ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Tìm kiếm yêu cầu...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty ? GestureDetector(
                  onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                  child: Icon(Icons.close, size: 16, color: Colors.grey[400])) : null,
              isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
            ),
          ),
        ),

        // ── Section header ─────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(children: [
            Text(
              _navIndex == 0 ? 'Tất cả yêu cầu' : _navIndex == 1 ? 'Đang xử lý' : _navIndex == 2 ? 'Đã giải quyết' : 'Đã hủy',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _blueDark),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: _blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('${filtered.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _blue)),
            ),
          ]),
        ),

        // ── TICKET LIST ────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _blue))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  color: _blue,
                  child: _tickets.isEmpty
                      ? _emptyState()
                      : filtered.isEmpty
                          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                            ]))
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) => _ticketCard(ctx, filtered[i]),
                            ),
                ),
        ),
      ]),

      // ── BOTTOM NAV: Tickets filter + Create ───────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(top: false, child: Row(children: [
          _bottomNavItem(0, Icons.list_alt_rounded, Icons.list_alt_outlined, 'Tất cả'),
          _bottomNavItem(1, Icons.pending_actions_rounded, Icons.pending_actions_outlined, 'Đang xử lý',
              badge: openCount > 0 ? '$openCount' : null),
          _bottomNavItem(2, Icons.check_circle_rounded, Icons.check_circle_outline, 'Đã xong'),
          _bottomNavItem(3, Icons.cancel_rounded, Icons.cancel_outlined, 'Đã hủy',
              badge: cancelledCount > 0 ? '$cancelledCount' : null),
          // Create ticket button
          Expanded(child: GestureDetector(
            onTap: () async {
              final result = await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CreateTicketScreen(currentUser: widget.currentUser)));
              if (result == true) _loadData();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_blueDark, _blue]),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 3),
                  const Flexible(child: Text('Tạo mới',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    overflow: TextOverflow.ellipsis, maxLines: 1)),
                ]),
              ),
            ),
          )),
        ])),
      ),
    );
  }

  Widget _bottomNavItem(int index, IconData iconOn, IconData iconOff, String label, {String? badge}) {
    final selected = _navIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _navIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: selected ? _blue.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(selected ? iconOn : iconOff, size: 22, color: selected ? _blue : Colors.grey[500]),
              ),
              if (badge != null) Positioned(
                right: -2, top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(8)),
                  child: Text(badge, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 10, fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? _blue : Colors.grey[500],
            )),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _ticketCard(BuildContext ctx, Ticket ticket) {
    final statusColor = _statusColor(ticket.status);
    final priorityColor = ticket.priority == 'High' ? const Color(0xFFE53935)
        : ticket.priority == 'Medium' ? const Color(0xFFFB8C00) : const Color(0xFF29B6F6);
    final diff = DateTime.now().difference(ticket.createdAt);
    final timeStr = diff.inMinutes < 1 ? 'Vừa xong'
        : diff.inMinutes < 60 ? '${diff.inMinutes}m trước'
        : diff.inHours < 24 ? '${diff.inHours}h trước'
        : '${ticket.createdAt.day}/${ticket.createdAt.month}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        elevation: 1, shadowColor: Colors.black.withValues(alpha: 0.07),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticket: ticket, isAdmin: false, currentUser: widget.currentUser)));
            _loadData();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Priority left stripe
              Container(width: 5, color: priorityColor),
              Expanded(child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Row 1: ID + status badge
                  Row(children: [
                    Text('#TKT-${ticket.ticketId.toString().padLeft(4, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: _blue, fontSize: 12)),
                    const Spacer(),
                    _statusBadge(ticket.status, statusColor),
                  ]),
                  const SizedBox(height: 6),
                  // Row 2: Subject
                  Text(ticket.subject,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E), height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  // Deadline warning
                  Builder(builder: (_) {
                    final dl = ticket.finalDeadline ?? ticket.proposedDeadline;
                    if (dl == null || ticket.status == 'Resolved') return const SizedBox.shrink();
                    final diff = dl.difference(DateTime.now());
                    final isOverdue = diff.isNegative;
                    final isSoon = !isOverdue && diff.inHours <= 24;
                    if (!isOverdue && !isSoon) return const SizedBox.shrink();
                    final color = isOverdue ? Colors.red : Colors.orange;
                    final dlStr = '${dl.day.toString().padLeft(2,'0')}/${dl.month.toString().padLeft(2,'0')}';
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isOverdue ? Icons.warning_rounded : Icons.timer_outlined, size: 11, color: color),
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                          child: Text(isOverdue ? 'QUÁ HẠN $dlStr' : 'SẮP HẼT $dlStr',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                        ),
                      ]),
                    );
                  }),
                  const SizedBox(height: 5),
                  // Row 3: Category + assignee + time
                  Row(children: [
                    if (ticket.categoryName != null) ...[
                      Icon(Icons.folder_outlined, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Flexible(child: Text(ticket.categoryName!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 6),
                    ],
                    Icon(Icons.support_agent, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Expanded(child: Text(
                      ticket.assigneeName ?? 'Chưa phân công',
                      style: TextStyle(fontSize: 11,
                          color: ticket.assigneeId == null ? Colors.orange[700] : Colors.grey[600],
                          fontWeight: ticket.assigneeId == null ? FontWeight.w600 : FontWeight.normal),
                      overflow: TextOverflow.ellipsis)),
                    Icon(Icons.access_time, size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 2),
                    Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ]),
                ]),
              )),
              // Chevron
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right, size: 20, color: Colors.grey[300]),
              ),
            ])),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
    child: Text(_statusLabel(status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _blue.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(Icons.inbox_outlined, size: 64, color: Colors.blue[300])),
    const SizedBox(height: 16),
    const Text('Chưa có yêu cầu nào', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    Text('Bấm "Tạo mới" ở dưới để bắt đầu', style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
  ]));
}
