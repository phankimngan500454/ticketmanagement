import 'package:flutter/material.dart';
import '../shared/ticket_detail_screen.dart';
import '../shared/notifications_screen.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../auth/login_screen.dart';

class ITAgentDashboard extends StatefulWidget {
  final User currentUser;
  const ITAgentDashboard({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ITAgentDashboard> createState() => _ITAgentDashboardState();
}

class _ITAgentDashboardState extends State<ITAgentDashboard> with TickerProviderStateMixin {
  final _repo = TicketRepository.instance;
  List<Ticket> _unassigned = [];
  List<Ticket> _myTickets = [];
  bool _loading = true;
  int _navIndex = 0; // 0=Chờ, 1=Việc của tôi, 2=Hôm nay
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _green = Color(0xFF00897B);
  static const _greenDark = Color(0xFF004D40);

  List<Ticket> get _todayWork {
    final now = DateTime.now();
    return _myTickets.where((t) {
      final createdToday = t.createdAt.year == now.year &&
          t.createdAt.month == now.month &&
          t.createdAt.day == now.day;
      final isDone = t.status == 'Resolved' || t.status == 'WaitingConfirmation';
      return createdToday || isDone;
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  void initState() { super.initState(); _loadData(); }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repo.getUnassignedTickets(),
      _repo.getTicketsByAssignee(widget.currentUser.userId),
    ]);
    if (mounted) setState(() {
      _unassigned = List.from(results[0]);
      _myTickets = List.from(results[1]);
      _loading = false;
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  List<Ticket> _applySearch(List<Ticket> list) {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return list;
    return list.where((t) =>
      t.subject.toLowerCase().contains(q) ||
      (t.requesterName ?? '').toLowerCase().contains(q) ||
      (t.categoryName ?? '').toLowerCase().contains(q) ||
      t.ticketId.toString().contains(q)).toList();
  }

  Future<void> _acceptTicket(Ticket ticket) async {
    await _repo.assignTicket(ticket.ticketId, widget.currentUser.userId);
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✅ Đã nhận Ticket #${ticket.ticketId}!'),
        backgroundColor: _green, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      setState(() => _navIndex = 1); // switch to "Việc của tôi"
    }
  }

  Future<void> _completeTicket(Ticket ticket) async {
    await _repo.updateStatus(ticket.ticketId, 'WaitingConfirmation');
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📬 Đã gửi xác nhận (Ticket #${ticket.ticketId})'),
        backgroundColor: const Color(0xFFF59E0B), behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  Color _priorityColor(String? p) {
    switch (p) {
      case 'High': return const Color(0xFFE53935);
      case 'Medium': return const Color(0xFFFB8C00);
      default: return const Color(0xFF29B6F6);
    }
  }

  String _priorityLabel(String? p) {
    switch (p) {
      case 'High': return 'Cao';
      case 'Medium': return 'Trung bình';
      default: return 'Thấp';
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final myPending = _myTickets.where((t) => t.status == 'Pending').length;
    final myWaiting = _myTickets.where((t) => t.status == 'WaitingConfirmation').length;
    final myResolved = _myTickets.where((t) => t.status == 'Resolved').length;
    final todayWork = _todayWork;

    Widget body;
    if (_loading) {
      body = const Center(child: CircularProgressIndicator(color: _green));
    } else if (_navIndex == 0) {
      body = _buildUnassignedTab();
    } else if (_navIndex == 1) {
      body = _buildMyTicketsTab();
    } else {
      body = _buildTodayTab(todayWork);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // ── COMPACT HEADER (mobile-optimized) ─────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_greenDark, _green],
            ),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            // Top row: greeting + notifications
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('IT Helpdesk', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(widget.currentUser.fullName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                // Notification bell
                Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => NotificationsScreen(currentUser: widget.currentUser))),
                  ),
                  if (_unassigned.isNotEmpty) Positioned(
                    right: 8, top: 8,
                    child: Container(
                      width: 16, height: 16,
                      decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                      child: Center(child: Text('${_unassigned.length}',
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                  ),
                ]),
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
                        CircleAvatar(radius: 14, backgroundColor: _green.withOpacity(0.1),
                          child: Text(widget.currentUser.fullName[0],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _green))),
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
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(widget.currentUser.fullName[0],
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ),
            // Stat row (compact, 4 cards)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(children: [
                _statCard('Chờ nhận', '${_unassigned.length}', const Color(0xFFFFCC80)),
                const SizedBox(width: 8),
                _statCard('Đang xử lý', '$myPending', const Color(0xFF80DEEA)),
                const SizedBox(width: 8),
                _statCard('Chờ xác nhận', '$myWaiting', const Color(0xFFCE93D8)),
                const SizedBox(width: 8),
                _statCard('Đã xong', '$myResolved', const Color(0xFFA5D6A7)),
              ]),
            ),
          ])),
        ),

        // ── SEARCH BAR ─────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Tìm ticket, tên người dùng...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[400]),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                      child: Icon(Icons.close, size: 16, color: Colors.grey[400]))
                  : null,
              isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
              filled: true, fillColor: const Color(0xFFF4F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _green, width: 1.5)),
            ),
          ),
        ),

        // ── CONTENT AREA ───────────────────────────────────────
        Expanded(child: RefreshIndicator(
          onRefresh: _loadData,
          color: _green,
          child: body,
        )),
      ]),

      // ── BOTTOM NAVIGATION BAR ──────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(top: false, child: Row(children: [
          _bottomNavItem(0, Icons.inbox_rounded, Icons.inbox_rounded, 'Chờ nhận',
              badge: _unassigned.isNotEmpty ? '${_unassigned.length}' : null),
          _bottomNavItem(1, Icons.assignment_rounded, Icons.assignment_outlined, 'Việc của tôi',
              badge: myPending > 0 ? '$myPending' : null),
          _bottomNavItem(2, Icons.today_rounded, Icons.today_outlined, 'Hôm nay',
              badge: todayWork.isNotEmpty ? '${todayWork.length}' : null),
        ])),
      ),
    );
  }

  Widget _bottomNavItem(int index, IconData iconActive, IconData iconInactive, String label, {String? badge}) {
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: selected ? _green.withOpacity(0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(selected ? iconActive : iconInactive,
                    size: 22, color: selected ? _green : Colors.grey[500]),
              ),
              if (badge != null) Positioned(
                right: -2, top: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(badge, style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 10, fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? _green : Colors.grey[500],
            )),
          ]),
        ),
      ),
    );
  }

  // ── TAB: Chờ tiếp nhận ────────────────────────────────────────
  Widget _buildUnassignedTab() {
    final list = _applySearch(_unassigned);
    if (list.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: _green.withOpacity(0.07), shape: BoxShape.circle),
          child: Icon(Icons.check_circle_outline, size: 56, color: _green.withOpacity(0.5))),
        const SizedBox(height: 16),
        const Text('Không có yêu cầu tồn đọng!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 6),
        Text('🎉 Tất cả đã được xử lý', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _ticketCard(
        ctx, list[i],
        actionBuilder: (t) => SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.pan_tool_alt_outlined, size: 16),
            label: const Text('Nhận xử lý ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _green, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 11),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), elevation: 0,
            ),
            onPressed: () => _acceptTicket(t),
          ),
        ),
      ),
    );
  }

  // ── TAB: Việc của tôi ─────────────────────────────────────────
  Widget _buildMyTicketsTab() {
    final list = _applySearch(_myTickets);
    if (list.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: _green.withOpacity(0.07), shape: BoxShape.circle),
          child: Icon(Icons.inbox_outlined, size: 56, color: _green.withOpacity(0.5))),
        const SizedBox(height: 16),
        const Text('Bạn chưa nhận việc nào.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 6),
        Text('Nhận ticket từ tab "Chờ nhận"', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final t = list[i];
        return _ticketCard(ctx, t, actionBuilder: (t) {
          if (t.status == 'WaitingConfirmation') {
            return _waitingChip();
          }
          return Row(children: [
            Expanded(child: OutlinedButton.icon(
              icon: const Icon(Icons.chat_bubble_outline, size: 14),
              label: const Text('Phản hồi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _green, side: const BorderSide(color: _green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              onPressed: () async {
                await Navigator.push(ctx, MaterialPageRoute(
                    builder: (_) => TicketDetailScreen(ticket: t, isAdmin: false, currentUser: widget.currentUser)));
                _loadData();
              },
            )),
            const SizedBox(width: 8),
            Expanded(child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline, size: 14),
              label: const Text('Hoàn thành'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), elevation: 0,
              ),
              onPressed: () => _completeTicket(t),
            )),
          ]);
        });
      },
    );
  }

  // ── TAB: Hôm nay ─────────────────────────────────────────────
  Widget _buildTodayTab(List<Ticket> tickets) {
    final now = DateTime.now();
    final dateStr = '${now.day.toString().padLeft(2,'0')}/${now.month.toString().padLeft(2,'0')}/${now.year}';

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 15, color: _green),
          const SizedBox(width: 6),
          Text('Công việc ngày $dateStr',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _greenDark)),
          const Spacer(),
          Text('${tickets.length} ticket', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ]),
      )),
      if (tickets.isEmpty)
        SliverFillRemaining(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _green.withOpacity(0.07), shape: BoxShape.circle),
            child: Icon(Icons.today_rounded, size: 56, color: _green.withOpacity(0.4))),
          const SizedBox(height: 16),
          const Text('Chưa có việc nào hôm nay', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.grey)),
          const SizedBox(height: 6),
          Text('Nhận ticket từ tab "Chờ nhận"', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
        ])))
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
          sliver: SliverList(delegate: SliverChildBuilderDelegate(
            (ctx, i) => _ticketCard(ctx, tickets[i], compact: true),
            childCount: tickets.length,
          )),
        ),
    ]);
  }

  // ── Shared ticket card ────────────────────────────────────────
  Widget _ticketCard(BuildContext ctx, Ticket t, {Widget Function(Ticket)? actionBuilder, bool compact = false}) {
    final priorityColor = _priorityColor(t.priority);
    final isHigh = t.priority == 'High';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: isHigh ? 2 : 1,
        shadowColor: isHigh ? const Color(0xFFE53935).withOpacity(0.2) : Colors.black.withOpacity(0.06),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(ctx, MaterialPageRoute(
                builder: (_) => TicketDetailScreen(ticket: t, isAdmin: false, currentUser: widget.currentUser)));
            _loadData();
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // Priority stripe
                Container(width: 5, color: priorityColor),
                Expanded(child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Row 1: ID + priority badge + time
                    Row(children: [
                      Text('#TKT-${t.ticketId.toString().padLeft(4, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: _green, fontSize: 12)),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: priorityColor.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(t.priority == 'High' ? Icons.keyboard_double_arrow_up
                              : t.priority == 'Medium' ? Icons.drag_handle : Icons.keyboard_double_arrow_down,
                              size: 10, color: priorityColor),
                          const SizedBox(width: 2),
                          Text(_priorityLabel(t.priority),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor)),
                        ]),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 2),
                      Text(_formatTime(t.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                    ]),
                    const SizedBox(height: 6),
                    // Row 2: Subject
                    Text(t.subject,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E), height: 1.3),
                        maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis),
                    // Deadline warning
                    Builder(builder: (_) {
                      final dl = t.finalDeadline ?? t.proposedDeadline;
                      if (dl == null || t.status == 'Resolved') return const SizedBox.shrink();
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
                            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                            child: Text(isOverdue ? 'QUÁ HẠN $dlStr' : 'SẮP HẼT $dlStr',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                          ),
                        ]),
                      );
                    }),
                    const SizedBox(height: 5),
                    // Row 3: Requester + category
                    Row(children: [
                      Icon(Icons.person_outline, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Text(t.requesterName ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      if (t.categoryName != null) ...[
                        Text(' · ', style: TextStyle(color: Colors.grey[400])),
                        Expanded(child: Text(t.categoryName!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]), overflow: TextOverflow.ellipsis)),
                      ],
                    ]),
                    if (!compact && actionBuilder != null) ...[
                      const SizedBox(height: 10),
                      actionBuilder(t),
                    ],
                    if (compact) ...[
                      const SizedBox(height: 4),
                      _statusBadge(t.status),
                    ],
                  ]),
                )),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color c;
    String label;
    switch (status) {
      case 'Resolved': c = const Color(0xFF43A047); label = 'Đã xong'; break;
      case 'WaitingConfirmation': c = const Color(0xFFF59E0B); label = 'Chờ xác nhận'; break;
      case 'Pending': c = const Color(0xFF1976D2); label = 'Đang xử lý'; break;
      default: c = Colors.grey; label = 'Đang mở';
    }
    return Align(alignment: Alignment.centerRight, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: c.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: c.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    ));
  }

  Widget _waitingChip() => Align(alignment: Alignment.centerRight, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
    ),
    child: const Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.hourglass_top_rounded, size: 13, color: Color(0xFFF59E0B)),
      SizedBox(width: 5),
      Text('Chờ xác nhận từ khách', style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w600)),
    ]),
  ));

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    ));
  }
}
