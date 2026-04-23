import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../../app_router.dart' show appRouter, TicketDetailWrapper;
import '../../services/windows_notification_service.dart';
import '../web/web_customer_sidebar.dart';

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
  int _navIndex = 1;        // 0=Tất cả, 1=Đang xử lý, 2=Đã xong, 3=Đã hủy
  int _medicalNavIndex = 0; // 0=Tất cả, 1=Yêu cầu mở, 2=Khoa xử lý, 3=Đã sửa xong, 4=Đóng BA
  int _ownershipFilter = 0; // 0=Tất cả, 1=Của tôi, 2=Khác
  String _searchQuery = '';
  String? _typeFilter;      // null=Tất cả, 'ticket'=Yêu cầu IT, 'reopen_medical', 'feedback'
  Ticket? _selectedTicket;  // split-view: ticket đang xem ở panel phải (Windows)
  String _filterStatus = 'Tất cả';  // chip filter web-style
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _refreshTimer;

  // Notification state: track IDs and statuses to detect new/updated tickets
  final Map<int, String> _knownTicketStates = {};
  int _newNotifCount = 0;

  static const _blue = Color(0xFF2563EB);      // brand — khớp web
  static const _blueDark = Color(0xFF1E3A8A);   // brandDark — khớp web

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final tickets = await _repo.getTicketsByRequester(widget.currentUser.userId);
      if (mounted) {
        setState(() {
          final nextTickets = List<Ticket>.from(tickets)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          if (_knownTicketStates.isNotEmpty) {
            final newTickets = nextTickets.where(
              (t) => !_knownTicketStates.containsKey(t.ticketId),
            ).toList();
            final changedTickets = nextTickets.where((t) {
              final previousStatus = _knownTicketStates[t.ticketId];
              return previousStatus != null && previousStatus != t.status;
            }).toList();
            _newNotifCount += newTickets.length + changedTickets.length;
            final latest = changedTickets.isNotEmpty
                ? changedTickets.first
                : (newTickets.isNotEmpty ? newTickets.first : null);
            if (latest != null) {
              WindowsNotificationService.showTicketUpdate(
                ticketId: latest.ticketId,
                message: changedTickets.contains(latest)
                    ? '${latest.subject}\nTrạng thái: ${_statusLabel(latest)}'
                    : 'Yêu cầu của bạn có cập nhật mới',
                onTap: () => appRouter.push('/ticket/${latest.ticketId}'),
              );
            }
          }
          _knownTicketStates
            ..clear()
            ..addEntries(nextTickets.map((t) => MapEntry(t.ticketId, t.status)));
          _tickets = nextTickets;
          // Sync selectedTicket với dữ liệu mới nhất
          if (_selectedTicket != null) {
            final match = nextTickets.cast<Ticket?>().firstWhere(
              (t) => t!.ticketId == _selectedTicket!.ticketId,
              orElse: () => null,
            );
            _selectedTicket = match;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Không tải được danh sách!'),
          backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  void dispose() { _refreshTimer?.cancel(); _searchCtrl.dispose(); super.dispose(); }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open':               return const Color(0xFF3B82F6);  // xanh — khớp web
      case 'Pending':            return const Color(0xFFF59E0B);  // vàng — khớp web
      case 'WaitingConfirmation':return const Color(0xFFE67E22);  // cam — khớp web
      case 'Resolved':           return const Color(0xFF10B981);  // xanh lá — khớp web
      case 'Cancelled':          return const Color(0xFF64748B);  // xám — khớp web
      default:                   return Colors.grey;
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

  List<Ticket> get _filtered {
    final q = _searchQuery.toLowerCase().trim();
    Iterable<Ticket> base = _tickets;
    // Lọc theo loại ticket
    if (_typeFilter != null) {
      base = base.where((t) => t.ticketType == _typeFilter);
    }

    // ── 4 tab trạng thái bệnh án ──
    if (_typeFilter == 'reopen_medical') {
      switch (_medicalNavIndex) {
        case 1: base = base.where((t) => t.status == 'Open'); break;
        case 2: base = base.where((t) => t.status == 'Resolved' || t.status == 'Pending'); break;
        case 3: base = base.where((t) => t.status == 'WaitingConfirmation'); break;
        case 4: base = base.where((t) => t.status == 'Cancelled'); break;
      }
    } else {
      // Lọc Chủa tôi / Khác
      if (_ownershipFilter == 1) {
        base = base.where((t) => t.requesterId == widget.currentUser.userId);
      } else if (_ownershipFilter == 2) {
        base = base.where((t) => t.requesterId != widget.currentUser.userId);
      }
      switch (_navIndex) {
        case 1: base = base.where((t) => t.status == 'Open' || t.status == 'Pending' || t.status == 'WaitingConfirmation'); break;
        case 2: base = base.where((t) => t.status == 'Resolved'); break;
        case 3: base = base.where((t) => t.status == 'Cancelled'); break;
      }
    }

    if (q.isEmpty) return base.toList();
    return base.where((t) =>
        t.subject.toLowerCase().contains(q) ||
        (t.categoryName ?? '').toLowerCase().contains(q) ||
        t.ticketId.toString().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Đếm cho bottom nav
    final medBase = _typeFilter == 'reopen_medical'
        ? _tickets.where((t) => t.ticketType == 'reopen_medical').toList()
        : <Ticket>[];
    final openCount    = _tickets.where((t) => t.status == 'Open' || t.status == 'Pending' || t.status == 'WaitingConfirmation').length;
    final cancelledCount = _tickets.where((t) => t.status == 'Cancelled' && t.ticketType != 'reopen_medical').length;
    // Đếm 4 trạng thái bệnh án
    final baOpen       = medBase.where((t) => t.status == 'Open').length;
    final baProcessing = medBase.where((t) => t.status == 'Resolved' || t.status == 'Pending').length;
    final baDone       = medBase.where((t) => t.status == 'WaitingConfirmation').length;
    final baClosed     = medBase.where((t) => t.status == 'Cancelled').length;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),  // khớp web
      drawer: _buildDrawer(),
      body: LayoutBuilder(builder: (ctx, constraints) {
        // ── Wide screen (Windows ≥ 800px) → split-view ──
        if (constraints.maxWidth >= 800) {
          return _buildWideLayout(filtered, openCount, cancelledCount,
              baOpen, baProcessing, baDone, baClosed, medBase);
        }
        // ── Narrow (mobile / compact Windows) → một cột như cũ ──
        return _buildNarrowLayout(filtered, openCount, cancelledCount,
            baOpen, baProcessing, baDone, baClosed, medBase);
      }),
    );
  }

  Widget _buildNarrowLayout(List<Ticket> filtered, int openCount, int cancelledCount, int baOpen, int baProcessing, int baDone, int baClosed, List<Ticket> medBase) {
    final body = _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _blue,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(children: [
        // ── HEADER ─────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_blueDark, _blue], // khớp web: #1E3A8A → #2563EB
            ),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            // Top row: hamburger + avatar + name + notifications
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(children: [
                Builder(
                  builder: (ctx) => IconButton(
                    icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 26),
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                  ),
                ),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.waving_hand_rounded, color: Colors.white70, size: 13),
                    const SizedBox(width: 4),
                    const Text('Xin chào', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ]),
                  Text(widget.currentUser.fullName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ])),
                Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                    onPressed: () {
                      setState(() => _newNotifCount = 0);
                      context.push('/notifications');
                    },
                  ),
                  if (_newNotifCount > 0)
                    Positioned(
                      right: 8, top: 8,
                      child: Container(
                        width: 16, height: 16,
                        decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                        child: Center(child: Text(
                          _newNotifCount > 9 ? '9+' : '$_newNotifCount',
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                        )),
                      ),
                    ),
                ]),

                PopupMenuButton<String>(
                  tooltip: '',
                  offset: const Offset(0, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  onSelected: (v) async {
                    if (v == 'logout') {
                      await _repo.logout();
                      if (mounted) context.go('/login');
                    } else if (v == 'profile') {
                      await context.push('/profile');
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      enabled: false,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: _blue.withValues(alpha: 0.12),
                            child: Text(widget.currentUser.fullName[0],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _blue)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(widget.currentUser.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1C1C2E)), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('Quản lý tài khoản', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ])),
                        ]),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey.shade200),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'profile',
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.manage_accounts_rounded, color: _blue, size: 17),
                        ),
                        const SizedBox(width: 12),
                        const Text('Hồ sơ & Đổi mật khẩu', style: TextStyle(color: Color(0xFF1C1C2E), fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'logout',
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 17),
                        ),
                        const SizedBox(width: 12),
                        const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w600)),
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
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(children: [
                _statCard('Tổng', '${_tickets.where((t) => t.status != 'Cancelled').length}', const Color(0xFF90CAF9)),
                const SizedBox(width: 6),
                _statCard('Đang xử lý', '$openCount', const Color(0xFFFFCC80)),
                const SizedBox(width: 6),
                _statCard('Đã xong', '${_tickets.where((t) => t.status == 'Resolved').length}', const Color(0xFFA5D6A7)),
              ]),
            ),
          ])),
        ),

        // ── EMERGENCY BANNER ───────────────────────────────────
        GestureDetector(
          onTap: () async {
            await context.push('/emergency');
            _loadData();
          },
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              const Expanded(child: Text('Gọi Khẩn Cấp IT — Nhấn để xem hotline',
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
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
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

        // ── Section header + Ticket Count ────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Row(children: [
            Text(
              _typeFilter == 'reopen_medical' ? 'Mở Lại Bệnh Án' 
                : _typeFilter == 'feedback' ? 'Góp ý'
                : _typeFilter == 'ticket' ? 'Yêu cầu IT'
                : 'Tất cả yêu cầu',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _blueDark),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: _blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('${filtered.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _blue)),
            ),
          ]),
        ),

        // ── Ownership Filter (chỉ hiện khi không phải bệnh án) ──
        if (_typeFilter != 'reopen_medical')
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(children: [
              _ownerChip(0, 'Tất cả'),
              const SizedBox(width: 8),
              _ownerChip(1, 'Của tôi'),
            ]),
          ),
        ]),
      ),


      // ── TICKET LIST ────────────────────────────────────────
      if (_tickets.isEmpty)
        SliverFillRemaining(child: _emptyState())
      else if (filtered.isEmpty)
        SliverFillRemaining(
          child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Không tìm thấy kết quả', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ]))
        )
      else
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _ticketCard(ctx, filtered[i]),
              childCount: filtered.length,
            ),
          ),
        ),
        ],
        ),   // ← end CustomScrollView
      );     // ← end RefreshIndicator
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: body,
      // ── BOTTOM NAV ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: _typeFilter == 'reopen_medical'
              // ── 4 tab bệnh án ──
              ? Row(children: [
                  _medNavItem(0, Icons.list_alt_rounded,          Icons.list_alt_outlined,          'Tất cả',       medBase.length),
                  _medNavItem(1, Icons.hourglass_empty_rounded,   Icons.hourglass_empty_rounded,    'Yêu cầu mở', baOpen,       const Color(0xFF3B82F6)),
                  _medNavItem(2, Icons.folder_open_rounded,       Icons.folder_open_outlined,       'Khoa xử lý', baProcessing, const Color(0xFFF59E0B)),
                  _medNavItem(3, Icons.edit_note_rounded,         Icons.edit_note_rounded,          'Đã sửa xong', baDone,       const Color(0xFFE67E22)),
                  _medNavItem(4, Icons.lock_rounded,              Icons.lock_outline_rounded,       'Đóng BA',      baClosed,     const Color(0xFF64748B)),
                  // Nút tạo yêu cầu
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final result = await context.push('/create-ticket');
                        if (result == true) _loadData();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_blueDark, _blue]),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ])
              // ── Tab thông thường ──
              : Row(children: [
                  _bottomNavItem(0, Icons.list_alt_rounded, Icons.list_alt_outlined, 'Tất cả'),
                  _bottomNavItem(1, Icons.pending_actions_rounded, Icons.pending_actions_outlined, 'Đang xử lý',
                      badge: openCount > 0 ? '$openCount' : null),
                  _bottomNavItem(2, Icons.check_circle_rounded, Icons.check_circle_outline, 'Đã xong'),
                  _bottomNavItem(3, Icons.cancel_rounded, Icons.cancel_outlined, 'Đã hủy',
                      badge: cancelledCount > 0 ? '$cancelledCount' : null),
                  // Nút tạo ticket
                  Expanded(child: GestureDetector(
                    onTap: () async {
                      final result = await context.push('/create-ticket');
                      if (result == true) _loadData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [_blueDark, _blue]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: _blue.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: LayoutBuilder(
                          builder: (ctx, constraints) {
                            final showText = constraints.maxWidth > 60;
                            return Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                              const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                              if (showText) ...[
                                const SizedBox(width: 4),
                                const Text('Tạo mới',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                                  overflow: TextOverflow.ellipsis, maxLines: 1),
                              ],
                            ]);
                          },
                        ),
                      ),
                    ),
                  )),
                ]),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // WIDE LAYOUT (Windows ≥ 800px) — split-view giống hệt web
  // ════════════════════════════════════════════════════════════
  Widget _buildWideLayout(List<Ticket> filtered, int openCount, int cancelledCount,
      int baOpen, int baProcessing, int baDone, int baClosed, List<Ticket> medBase) {
    
    // Main Panel widget
    Widget mainPanelContent = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header: title + refresh + create
      Container(
        padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(
              _typeFilter == 'reopen_medical' ? 'Mở Lại Bệnh Án'
                  : _typeFilter == 'feedback' ? 'Góp ý'
                  : _typeFilter == 'ticket' ? 'Yêu cầu IT'
                  : 'Khám phá Dịch vụ',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF1E293B)),
              overflow: TextOverflow.ellipsis,
            )),
            const SizedBox(width: 8),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Material(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFFF1F5F9),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () { setState(() => _loading = true); _loadData(); },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.refresh_rounded, size: 20, color: Colors.grey.shade600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _typeFilter == 'reopen_medical' ? const Color(0xFF1E3A8A) : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Tạo mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onPressed: () async {
                  final result = await context.push('/create-ticket');
                  if (result == true) _loadData();
                },
              ),
            ]),
          ]),
          const SizedBox(height: 18),
          // Search & Filters on same line
          Row(children: [
            SizedBox(
              width: 220,
              height: 36,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm yêu cầu...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey[400]),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                          child: Icon(Icons.close, size: 16, color: Colors.grey[400]))
                      : null,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  filled: true, fillColor: const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _blue, width: 1.5)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  if (_typeFilter == 'reopen_medical') ...[ 
                    _wideFilterChip('Tất cả', null, 'Tất cả', medBase.length, icon: Icons.list_rounded),
                    _wideFilterChip('BA_Open', const Color(0xFF3B82F6), 'Yêu cầu mở', baOpen, icon: Icons.hourglass_empty_rounded),
                    _wideFilterChip('BA_Processing', const Color(0xFFF59E0B), 'Khoa xử lý', baProcessing, icon: Icons.folder_open_rounded),
                    _wideFilterChip('BA_Done', const Color(0xFFE67E22), 'Đã sửa xong', baDone, icon: Icons.edit_note_rounded),
                    _wideFilterChip('BA_Closed', const Color(0xFF64748B), 'Đóng BA', baClosed, icon: Icons.lock_rounded),
                  ] else ...[
                    _wideFilterChip('Tất cả', null, 'Tất cả', _tickets.length),
                    _wideFilterChip('Open', const Color(0xFF3B82F6), 'Đang xử lý', openCount),
                    _wideFilterChip('Resolved', const Color(0xFF10B981), 'Đã xong',
                        _tickets.where((t) => t.status == 'Resolved').length),
                    _wideFilterChip('Cancelled', const Color(0xFF64748B), 'Đã hủy', cancelledCount),
                  ],
                ]),
              ),
            ),
          ]),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 14, 28, 8),
        child: Text('${filtered.length} kết quả',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
      ),
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text('Không có yêu cầu nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
              ]))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _wideTicketRow(filtered[i]),
              ),
      ),
    ]);

    return Row(children: [
      WebCustomerSidebar(
        currentUser: widget.currentUser,
        selectedType: _typeFilter,
        onTypeSelected: (type) => setState(() {
            _typeFilter = type;
            _selectedTicket = null;
            _filterByStatus('Tất cả');
        }),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : _selectedTicket != null
                ? Row(children: [
                    Expanded(flex: 4, child: mainPanelContent),
                    Container(width: 1, color: Colors.grey.shade200),
                    Expanded(
                      flex: 5,
                      child: Container(
                        color: Colors.white,
                        child: Column(children: [
                          // Panel header
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                          ),
                          child: Row(children: [
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              tooltip: 'Đóng',
                              onPressed: () => setState(() => _selectedTicket = null),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _blue.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${_selectedTicket!.ticketType == 'reopen_medical' ? 'BA' : _selectedTicket!.ticketType == 'feedback' ? 'GY' : 'TKT'}'
                                '-${_selectedTicket!.ticketId.toString().padLeft(4, '0')}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _blue),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.open_in_new_rounded, size: 17),
                              tooltip: 'Mở trang riêng',
                              onPressed: () {
                                final t = _selectedTicket!;
                                context.push('/ticket/${t.ticketId}', extra: t);
                              },
                            ),
                          ]),
                        ),
                        // Detail content
                          Expanded(
                            child: TicketDetailWrapper(
                              key: ValueKey('win_detail_${_selectedTicket!.ticketId}'),
                              ticketId: _selectedTicket!.ticketId,
                              ticket: _selectedTicket,
                              currentUser: widget.currentUser,
                              isAdmin: false,
                              isEmbedded: true,
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ])
                : mainPanelContent,
      ),
    ]);
  }

  void _filterByStatus(String status) {
    _filterStatus = status;
    if (status == 'Tất cả') {
      _navIndex = 0;
      _medicalNavIndex = 0;
    }
  }

  // Filter chip (wide layout)
  Widget _wideFilterChip(String value, Color? color, String label, int count, {IconData? icon}) {
    final isSelected = _filterStatus == value;
    final c = color ?? _blue;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() {
          _filterStatus = value;
          if (_typeFilter != 'reopen_medical') {
            switch (value) {
              case 'Tất cả': _navIndex = 0; break;
              case 'Open': _navIndex = 1; break;
              case 'Resolved': _navIndex = 2; break;
              case 'Cancelled': _navIndex = 3; break;
            }
          } else {
            switch (value) {
              case 'Tất cả': _medicalNavIndex = 0; break;
              case 'BA_Open': _medicalNavIndex = 1; break;
              case 'BA_Processing': _medicalNavIndex = 2; break;
              case 'BA_Done': _medicalNavIndex = 3; break;
              case 'BA_Closed': _medicalNavIndex = 4; break;
            }
          }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? c.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? c.withValues(alpha: 0.5) : Colors.grey.shade200, width: isSelected ? 1.5 : 1),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: isSelected ? c : Colors.grey.shade500),
              const SizedBox(width: 4),
            ] else if (color != null) ...[
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? c : Colors.grey.shade600)),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? c.withValues(alpha: 0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('$count', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isSelected ? c : Colors.grey.shade500)),
            ),
          ]),
        ),
      ),
    );
  }

  // Ticket row card (wide layout — compact, giống web)
  Widget _wideTicketRow(Ticket t) {
    final isSelected = _selectedTicket?.ticketId == t.ticketId;
    final isFeedback = t.ticketType == 'feedback';
    final isReopen = t.ticketType == 'reopen_medical';
    final typeColor = isReopen ? const Color(0xFF7C94B6) : isFeedback ? const Color(0xFF00897B) : _blue;
    final typeLabel = isReopen ? 'Mở lại BA' : isFeedback ? 'Góp ý' : 'Yêu cầu IT';
    final typeIcon = isReopen ? Icons.folder_open_rounded : isFeedback ? Icons.feedback_rounded : Icons.computer_rounded;
    final prefix = isReopen ? 'BA' : isFeedback ? 'GY' : 'TKT';
    final statusColor = _statusColor(t.status);
    final statusTxt = _statusLabel(t);
    final dt = t.createdAt.toLocal();
    final dateStr = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _selectedTicket = t),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? typeColor.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? typeColor.withValues(alpha: 0.5) : Colors.grey.shade100,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: typeColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(typeIcon, size: 11, color: typeColor),
                const SizedBox(width: 3),
                Text(typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor)),
              ]),
            ),
            const SizedBox(width: 6),
            Text('#$prefix-${t.ticketId.toString().padLeft(4,'0')}',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(statusTxt, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(t.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          Row(children: [
            Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 3),
            Text(dateStr, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ]),
        ]),
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

  // Tab bệnh án với màu riêng
  Widget _medNavItem(int index, IconData iconOn, IconData iconOff, String label, int count, [Color? activeColor]) {
    final selected = _medicalNavIndex == index;
    final color = activeColor ?? _blue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _medicalNavIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: selected ? color.withValues(alpha: 0.13) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Icon(selected ? iconOn : iconOff, size: 20,
                    color: selected ? color : Colors.grey[400]),
                if (count > 0) Positioned(
                  right: -5, top: -5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected ? color : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text('$count',
                        style: const TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              fontSize: 9,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? color : Colors.grey[400],
            ),
            overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 1),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _ownerChip(int val, String label) {
    final selected = _ownershipFilter == val;
    return GestureDetector(
      onTap: () => setState(() => _ownershipFilter = val),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _blue.withValues(alpha: 0.08) : Colors.transparent,
          border: Border.all(color: selected ? _blue : Colors.grey.shade300, width: selected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          color: selected ? _blue : Colors.grey[500],
        )),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header drawer — gradient xanh khớp web
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      widget.currentUser.fullName[0],
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.currentUser.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.currentUser.deptName ?? widget.currentUser.role,
                          style: TextStyle(
                            fontSize: 12, color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Menu items
            const SizedBox(height: 8),
            _drawerItem(
              icon: Icons.apps_rounded,
              label: 'Tất cả',
              type: null,
              color: const Color(0xFF2563EB),
              count: _tickets.length,
            ),
            _drawerItem(
              icon: Icons.folder_open_rounded,
              label: 'Mở lại bệnh án',
              type: 'reopen_medical',
              color: const Color(0xFF7C94B6),
              count: _tickets.where((t) => t.ticketType == 'reopen_medical').length,
            ),
            const Spacer(),
            const Divider(height: 1),
            // Đăng xuất
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                await _repo.logout();
                if (mounted) context.go('/login');
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                  ),
                  const SizedBox(width: 14),
                  const Text('Đăng xuất', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600, color: Colors.redAccent,
                  )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _drawerItem({required IconData icon, required String label, required String? type, required Color color, int count = 0}) {
    final selected = _typeFilter == type;
    return InkWell(
      onTap: () {
        setState(() {
          _typeFilter = type;
          _medicalNavIndex = 0; // reset về Tất cả khi đổi loại
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? _blue.withValues(alpha: 0.06) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: selected ? _blue : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected ? _blue : const Color(0xFF334155),
                ),
              ),
            ),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.bold, color: color,
                )),
              ),
          ],
        ),
      ),
    );
  }

  Widget _ticketCard(BuildContext ctx, Ticket ticket) {
    final isFeedback = ticket.ticketType == 'feedback';
    final isReopenMedical = ticket.ticketType == 'reopen_medical';
    final isSpecialType = isFeedback || isReopenMedical;
    final statusColor = _statusColor(ticket.status);
    final priorityColor = isSpecialType
        ? (isReopenMedical ? const Color.fromARGB(255, 148, 182, 234) : const Color(0xFF00897B))
        : ticket.priority == 'High' ? const Color(0xFFE53935)
        : ticket.priority == 'Medium' ? const Color(0xFFFB8C00) : const Color(0xFF29B6F6);
    final t = ticket.createdAt.toLocal();
    final timeStr = '${t.day.toString().padLeft(2,'0')}/${t.month.toString().padLeft(2,'0')}/${t.year}  '
        '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';

    final ticketPrefix = isFeedback ? '#GY' : isReopenMedical ? '#BA' : '#TKT';
    final ticketColor = isFeedback ? const Color(0xFF00897B) : isReopenMedical ? const Color.fromARGB(255, 148, 182, 234) : _blue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        elevation: 1, shadowColor: Colors.black.withValues(alpha: 0.07),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            // Tạm dừng auto-refresh để tránh setState khi navigator đang chuyển trang
            _refreshTimer?.cancel();
            await context.push('/ticket/${ticket.ticketId}', extra: ticket);
            _loadData();
            // Khởi động lại timer sau khi quay về
            _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              // Priority left stripe (tím cho feedback)
              Container(width: 5, color: priorityColor),
              Expanded(child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Row 1: ID + loại + status badge — cùng 1 hàng gọn
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ticketColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (isFeedback)
                          const Icon(Icons.feedback_rounded, size: 11, color: Color(0xFF00897B))
                        else
                          Icon(Icons.confirmation_number_outlined, size: 11, color: ticketColor),
                        const SizedBox(width: 3),
                        Text('$ticketPrefix-${ticket.ticketId.toString().padLeft(4, '0')}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: ticketColor, fontSize: 12)),
                      ]),
                    ),
                    if (isFeedback) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00897B),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('Góp ý', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                    if (isReopenMedical) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 148, 182, 234),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('Mở lại BA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                    const Spacer(),
                    _statusBadge(ticket, statusColor),
                  ]),
                  const SizedBox(height: 5),
                  // Row 2: Subject + ngày giờ
                  Text(ticket.subject,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E), height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time_rounded, size: 11, color: Colors.grey[400]),
                    const SizedBox(width: 3),
                    Text(timeStr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.grey[500])),
                  ]),
                  const SizedBox(height: 7),
                  // Row X: Sender Badge (If sent by someone else)
                  if (ticket.requesterId != widget.currentUser.userId) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.person_pin_rounded, size: 14, color: Colors.amber.shade700),
                        const SizedBox(width: 5),
                        Text('Gửi bởi: ${ticket.requesterName ?? 'Ẩn danh'}', 
                             style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                      ]),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Row 3: IT assignee (chỉ cho ticket thường) hoặc "Đang chờ duyệt" cho feedback
                  if (isSpecialType)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isReopenMedical ? const Color.fromARGB(255, 148, 182, 234) : const Color(0xFF00897B)).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          isReopenMedical ? Icons.folder_open_rounded : Icons.rate_review_outlined,
                          size: 14,
                          color: isReopenMedical ? const Color.fromARGB(255, 148, 182, 234) : const Color(0xFF00897B),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isReopenMedical
                            ? (ticket.status == 'Open' ? 'Chờ duyệt'
                              : ticket.status == 'Resolved' ? 'Đã duyệt'
                              : ticket.status == 'Pending' ? 'Đang mở BA'
                              : ticket.status == 'WaitingConfirmation' ? 'Chờ đóng BA'
                              : ticket.status == 'Cancelled' ? 'Đã đóng BA'
                              : ticket.status)
                            : (ticket.status == 'Resolved' ? 'Đã tiếp nhận'
                              : ticket.status == 'Pending' ? 'Đang xem xét'
                              : ticket.status == 'Cancelled' ? 'Đã huỷ'
                              : 'Chờ xem xét'),
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold,
                            color: isReopenMedical ? const Color.fromARGB(255, 148, 182, 234) : const Color(0xFF00897B)),
                        ),
                      ]),
                    )
                  else
                    Row(children: [
                      // Tên IT — chip nổi bật
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ticket.assigneeId == null
                              ? Colors.orange.withValues(alpha: 0.1)
                              : const Color(0xFF1976D2).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.support_agent, size: 14,
                            color: ticket.assigneeId == null ? Colors.orange[700] : const Color(0xFF1976D2)),
                          const SizedBox(width: 5),
                          Text(
                            ticket.assigneeName ?? 'Chưa phân công',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold,
                              color: ticket.assigneeId == null ? Colors.orange[700] : const Color(0xFF1976D2)),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 8),
                      // Deadline warning (cùng hàng với tên IT)
                      Builder(builder: (_) {
                        final dl = ticket.finalDeadline ?? ticket.proposedDeadline;
                        if (dl == null || ticket.status == 'Resolved') return const SizedBox.shrink();
                        final diff = dl.difference(DateTime.now());
                        final isOverdue = diff.isNegative;
                        final isSoon = !isOverdue && diff.inHours <= 24;
                        if (!isOverdue && !isSoon) return const SizedBox.shrink();
                        final color = isOverdue ? Colors.red : Colors.orange;
                        final dlStr = '${dl.day.toString().padLeft(2,'0')}/${dl.month.toString().padLeft(2,'0')}';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(isOverdue ? Icons.warning_rounded : Icons.timer_outlined, size: 11, color: color),
                            const SizedBox(width: 3),
                            Text(isOverdue ? 'QUÁ HẠN $dlStr' : 'SẮP HẾT $dlStr',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                          ]),
                        );
                      }),
                    ]),
                  if (!isSpecialType && ticket.categoryName != null) ...[
                    const SizedBox(height: 6),
                    // Row 4: Category (chỉ ticket thường)
                    Row(children: [
                      Icon(Icons.folder_outlined, size: 11, color: Colors.grey[400]),
                      const SizedBox(width: 3),
                      Flexible(child: Text(ticket.categoryName!,
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]), overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
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

  Widget _statusBadge(Ticket ticket, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(20)),
    child: Text(_statusLabel(ticket), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
