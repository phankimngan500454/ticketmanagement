import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/admin_sidebar.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';

class AdminDashboard extends StatefulWidget {
  final User currentUser;
  const AdminDashboard({super.key, required this.currentUser});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  final _repo = TicketRepository.instance;
  List<Ticket> _tickets = [];
  List<User> _itStaff = [];
  bool _loading = true;
  String _filterStatus = 'Tất cả';
  String _priorityFilter = 'Tất cả';
  String? _categoryFilter;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  late TabController _tabController;
  int _sidebarIndex = 0;
  int _currentPage = 0;
  static const int _pageSize = 15;

  // Real-time: track new tickets since last bell-tap
  final Set<int> _knownTicketIds = {};
  int _newNotifCount = 0;
  Timer? _refreshTimer;

  static const _softwareCats = {
    'Lỗi phần mềm',
    'Yêu cầu cấp quyền',
    'Cài đặt / Nâng cấp',
    'Khác',
  };
  static const _hardwareCats = {'Lỗi phần cứng', 'Lỗi mạng'};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      setState(() { _searchQuery = _searchCtrl.text; _currentPage = 0; });
    });
    _loadData();
    // Auto-refresh every 15 seconds to detect new tickets
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repo.getAllTickets(),
      _repo.getITStaff(),
    ]);
    if (mounted) {
      setState(() {
        final rawTickets = List<Ticket>.from(results[0]);
        rawTickets.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        // Detect genuinely new tickets (unknown IDs)
        if (_knownTicketIds.isNotEmpty) {
          final newOnes = rawTickets.where((t) => !_knownTicketIds.contains(t.ticketId)).length;
          if (newOnes > 0) _newNotifCount += newOnes;
        }
        _knownTicketIds.addAll(rawTickets.map((t) => t.ticketId));
        _tickets = rawTickets;
        _itStaff = List<User>.from(results[1]);
        _loading = false;
      });
    }
  }

  List<Ticket> get _filtered {
    final statusFilter = _filterStatus;
    final priorityFilter = _priorityFilter;
    final catFilter = _categoryFilter;
    final q = _searchQuery.toLowerCase().trim();
    return _tickets.where((t) {
      final matchStatus = statusFilter == 'Tất cả' || t.status == statusFilter;
      final matchPriority =
          priorityFilter == 'Tất cả' || t.priority == priorityFilter;
      final cat = t.categoryName ?? '';
      final matchCategory = catFilter == null || catFilter == 'Tất cả'
          ? true
          : catFilter == 'Phần mềm'
          ? _softwareCats.contains(cat)
          : _hardwareCats.contains(cat);
      final matchSearch =
          q.isEmpty ||
          t.subject.toLowerCase().contains(q) ||
          (t.requesterName ?? '').toLowerCase().contains(q) ||
          (t.categoryName ?? '').toLowerCase().contains(q) ||
          '#tkt-${t.ticketId.toString().padLeft(4, '0')}'.contains(q) ||
          t.ticketId.toString().contains(q);
      return matchStatus && matchPriority && matchCategory && matchSearch;
    }).toList();
  }

  List<Ticket> get _paginatedTickets {
    final all = _filtered;
    final start = _currentPage * _pageSize;
    if (start >= all.length) return [];
    return all.sublist(start, (start + _pageSize).clamp(0, all.length));
  }

  // ── SLA rules: High=4h, Medium=24h, Low=72h ────────────────────
  DateTime _slaDeadline(Ticket t) {
    final hours = t.priority == 'High' ? 4
        : t.priority == 'Medium' ? 24
        : 72;
    return t.createdAt.add(Duration(hours: hours));
  }

  // effective deadline: manual first, then SLA
  DateTime? _effectiveDeadline(Ticket t) {
    if (t.status == 'Resolved' || t.status == 'Cancelled') return null;
    if (t.finalDeadline != null) return t.finalDeadline;
    return _slaDeadline(t);
  }

  // deadline warning: null | 'overdue' | 'soon'
  String? _dlWarning(Ticket t) {
    final dl = _effectiveDeadline(t);
    if (dl == null) return null;
    final diff = dl.difference(DateTime.now());
    if (diff.isNegative) return 'overdue';
    if (diff.inHours <= 4) return 'soon';
    return null;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFFE53935);
      case 'Pending': return const Color(0xFFFB8C00);
      case 'WaitingConfirmation': return const Color(0xFFF59E0B);
      case 'Resolved': return const Color(0xFF43A047);
      case 'Cancelled': return const Color(0xFF78909C);
      default: return Colors.grey;
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High': return const Color(0xFFE53935);
      case 'Medium': return const Color(0xFFFB8C00);
      default: return const Color(0xFF29B6F6);
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



  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays}d trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _assignTicket(Ticket ticket, User? staff) async {
    await _repo.assignTicket(ticket.ticketId, staff?.userId);
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = _tickets.length;
    final openCount = _tickets.where((t) => t.status == 'Open').length;
    final pendingCount = _tickets.where((t) => t.status == 'Pending').length;
    final resolvedCount = _tickets.where((t) => t.status == 'Resolved').length;
    final unassigned = _tickets.where((t) => t.assigneeId == null).length;
    final slaOverdue = _tickets.where((t) => _dlWarning(t) == 'overdue').length;
    final slaSoon = _tickets.where((t) => _dlWarning(t) == 'soon').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      drawer: AdminSidebar(
        currentUser: widget.currentUser,
        selectedIndex: _sidebarIndex,
        onItemSelected: (index) {
          setState(() => _sidebarIndex = index);
          if (index == 1) {
            context.push('/admin/reports');
          } else if (index == 2) {
            context.push('/notifications');
          } else if (index == 3) {
            context.push('/admin/it-workload');
          } else if (index == 4) {
            context.push('/admin/emergency-contacts');
          }
        },
      ),
      body: Builder(
        builder: (scaffoldCtx) => Column(
          children: [
            // ── HEADER ──────────────────────────────────────────
            DashboardHeader(
              title: 'Admin Dashboard',
              userName: widget.currentUser.fullName,
              greeting: '',
              gradientColors: const [Color(0xFF1A237E), Color(0xFF3949AB)],
              showGreeting: false,
              notificationCount: _newNotifCount,
              onNotificationTap: () {
                setState(() => _newNotifCount = 0); // clear badge
                context.push('/notifications');
              },
              leadingAction: IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 24),
                onPressed: () => Scaffold.of(scaffoldCtx).openDrawer(),
              ),
              bottomContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat row
                  Row(children: [
                    _statCard('Tổng', '$total', const Color(0xFF90CAF9)),
                    const SizedBox(width: 8),
                    _statCard('Đang mở', '$openCount', const Color(0xFFEF9A9A)),
                    const SizedBox(width: 8),
                    _statCard('Chờ xử lý', '$pendingCount', const Color(0xFFFFCC80)),
                    const SizedBox(width: 8),
                    _statCard('Đã xong', '$resolvedCount', const Color(0xFFA5D6A7)),
                  ]),
                  const SizedBox(height: 12),
                  // Tab bar
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: const Color(0xFF1A237E),
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                      tabs: [
                        Tab(text: 'TẤT CẢ ($total)'),
                        Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          const Text('CHƯA PHÂN CÔNG'),
                          if (unassigned > 0) ...[
                            const SizedBox(width: 5),
                            CircleAvatar(radius: 9, backgroundColor: const Color(0xFFE53935),
                              child: Text('$unassigned', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))),
                          ],
                        ])),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── FILTER BAR ──────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(children: [
                // Status summary chips row
                Row(children: [
                  _summaryChip('$openCount Đang mở', const Color(0xFFE53935)),
                  const SizedBox(width: 8),
                  _summaryChip('$pendingCount Chờ xử lý', const Color(0xFFFB8C00)),
                  const SizedBox(width: 8),
                  _summaryChip('$resolvedCount Đã xong', const Color(0xFF43A047)),
                  if (slaOverdue > 0) ...[
                    const SizedBox(width: 8),
                    _summaryChip('$slaOverdue SLA QH', const Color(0xFFB71C1C), icon: Icons.warning_rounded),
                  ],
                  if (slaSoon > 0 && slaOverdue == 0) ...[
                    const SizedBox(width: 8),
                    _summaryChip('$slaSoon SLA Sắp hết', Colors.orange, icon: Icons.timer_outlined),
                  ],
                  const Spacer(),
                  // Priority filter
                  PopupMenuButton<String>(
                    initialValue: _priorityFilter,
                    offset: const Offset(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (v) => setState(() { _priorityFilter = v; _currentPage = 0; }),
                    itemBuilder: (_) => ['Tất cả', 'High', 'Medium', 'Low']
                        .map((p) => PopupMenuItem(value: p, child: Text(p == 'High' ? '🔴 Cao' : p == 'Medium' ? '🟠 Trung bình' : p == 'Low' ? '🔵 Thấp' : '⚪ Tất cả')))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: _priorityFilter != 'Tất cả' ? const Color(0xFF3949AB) : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(20),
                        color: _priorityFilter != 'Tất cả' ? const Color(0xFF3949AB).withValues(alpha: 0.08) : Colors.transparent,
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.filter_list, size: 13, color: _priorityFilter != 'Tất cả' ? const Color(0xFF3949AB) : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _priorityFilter == 'Tất cả' ? 'Ưu tiên' : _priorityFilter,
                          style: TextStyle(fontSize: 11, color: _priorityFilter != 'Tất cả' ? const Color(0xFF3949AB) : Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                        const Icon(Icons.arrow_drop_down, size: 15, color: Colors.grey),
                      ]),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                // Category + Status filter chips row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _catChip('Tất cả', Icons.apps_rounded, const Color(0xFF3949AB)),
                    const SizedBox(width: 6),
                    _catChip('Phần mềm', Icons.computer_rounded, const Color(0xFF1565C0)),
                    const SizedBox(width: 6),
                    _catChip('Phần cứng', Icons.memory_rounded, const Color(0xFF0277BD)),
                    Container(margin: const EdgeInsets.symmetric(horizontal: 10), width: 1, height: 22, color: Colors.grey.shade300),
                     ...['Tất cả', 'Open', 'Pending', 'Resolved', 'Cancelled'].map((s) {
                      final selected = _filterStatus == s;
                      final color = s == 'Open' ? const Color(0xFFE53935)
                          : s == 'Pending' ? const Color(0xFFFB8C00)
                          : s == 'Resolved' ? const Color(0xFF43A047)
                          : s == 'Cancelled' ? const Color(0xFF78909C)
                          : const Color(0xFF3949AB);
                      return GestureDetector(
                        onTap: () => setState(() { _filterStatus = s; _currentPage = 0; }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? color : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? color : Colors.grey.shade300),
                          ),
                          child: Text(
                            s == 'Tất cả' ? 'Tất cả' : _statusLabel(s),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.grey[600]),
                          ),
                        ),
                      );
                    }),
                  ]),
                ),
                const SizedBox(height: 10),
              ]),
            ),

            // ── TABLE HEADER ────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: const Divider(height: 1, color: Color(0xFFE8EAED)),
            ),
            Container(
              color: const Color(0xFFF8F9FB),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(children: [
                const SizedBox(width: 6),
                const SizedBox(width: 28), // priority icon
                Expanded(flex: 1, child: Text('KEY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5))),
                Expanded(flex: 3, child: Text('TIÊU ĐỀ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('NGƯỜI GỬI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('NGƯỜI XỬ LÝ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5))),
                Expanded(flex: 2, child: Text('TRẠNG THÁI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5))),
                Expanded(flex: 1, child: Text('THỜI GIAN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.5))),
                const SizedBox(width: 8),
              ]),
            ),
            const Divider(height: 1, color: Color(0xFFE8EAED)),

            // ── TICKET TABLE ─────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF3949AB)))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: const Color(0xFF3949AB),
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildTableList(_paginatedTickets),
                          _buildTableList(_paginatedTickets.where((t) => t.assigneeId == null).toList()),
                        ],
                      ),
                    ),
            ),

            // ── PAGINATION BAR ───────────────────────────────────
            if (!_loading) _buildPaginationBar(filtered.length),
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationBar(int totalCount) {
    final totalPages = (totalCount / _pageSize).ceil().clamp(1, 9999);
    final start = totalCount == 0 ? 0 : _currentPage * _pageSize + 1;
    final end = ((_currentPage + 1) * _pageSize).clamp(0, totalCount);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(children: [
        Text('$start–$end / $totalCount kết quả',
            style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const Spacer(),
        // First
        _pageBtn(Icons.first_page, _currentPage > 0, () => setState(() => _currentPage = 0)),
        const SizedBox(width: 4),
        // Prev
        _pageBtn(Icons.chevron_left, _currentPage > 0, () => setState(() => _currentPage--)),
        const SizedBox(width: 8),
        // Page indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF3949AB),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('${_currentPage + 1} / $totalPages',
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        // Next
        _pageBtn(Icons.chevron_right, _currentPage < totalPages - 1, () => setState(() => _currentPage++)),
        const SizedBox(width: 4),
        // Last
        _pageBtn(Icons.last_page, _currentPage < totalPages - 1, () => setState(() => _currentPage = totalPages - 1)),
      ]),
    );
  }

  Widget _pageBtn(IconData icon, bool enabled, VoidCallback onTap) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFF3949AB).withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: enabled ? const Color(0xFF3949AB) : Colors.grey[300]),
    ),
  );




  Widget _summaryChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(icon, size: 11, color: color),
          )
        else
          Container(width: 7, height: 7, margin: const EdgeInsets.only(right: 5), decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  // ── TABLE LIST ────────────────────────────────────────────────
  Widget _buildTableList(List<Ticket> tickets) {
    if (tickets.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFF3949AB).withValues(alpha: 0.07), shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline, size: 56, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text('Không có yêu cầu nào', style: TextStyle(color: Colors.grey[500], fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Thử thay đổi bộ lọc', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        ]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: tickets.length,
      itemBuilder: (ctx, i) => _buildTableRow(ctx, tickets[i]),
    );
  }

  Widget _buildTableRow(BuildContext ctx, Ticket ticket) {
    final statusColor = _statusColor(ticket.status);
    final priorityColor = _priorityColor(ticket.priority);
    final isAssigned = ticket.assigneeId != null;
    final requesterInitial = (ticket.requesterName?.isNotEmpty == true)
        ? ticket.requesterName![0].toUpperCase() : '?';
    final slaWarn = _dlWarning(ticket);
    final rowBg = slaWarn == 'overdue'
        ? const Color(0xFFFFEBEE)
        : slaWarn == 'soon'
            ? const Color(0xFFFFF8E1)
            : Colors.white;

    return InkWell(
      onTap: () async {
        _refreshTimer?.cancel();
        await context.push('/ticket/${ticket.ticketId}', extra: ticket);
        _loadData();
        _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
      },
      child: Container(
        decoration: BoxDecoration(
          color: rowBg,
          border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        ),
        child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Priority left border stripe
            Container(width: 4, color: priorityColor),
            const SizedBox(width: 8),

            // Priority icon box
            SizedBox(
              width: 28,
              child: Center(
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    ticket.priority == 'High' ? Icons.keyboard_double_arrow_up
                        : ticket.priority == 'Medium' ? Icons.drag_handle
                        : Icons.keyboard_double_arrow_down,
                    size: 12, color: priorityColor,
                  ),
                ),
              ),
            ),

            // KEY
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  '#${ticket.ticketId.toString().padLeft(4, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3949AB), fontSize: 12),
                ),
              ),
            ),

            // TIÊU ĐỀ
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(ticket.subject,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (ticket.categoryName != null)
                    Text(ticket.categoryName!,
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  // deadline warning badge
                  Builder(builder: (ctx) {
                    final warn = _dlWarning(ticket);
                    if (warn == null) return const SizedBox.shrink();
                    final isOverdue = warn == 'overdue';
                    final warnColor = isOverdue ? Colors.red : Colors.orange;
                    final dl = ticket.finalDeadline ?? ticket.proposedDeadline;
                    final dlStr = dl != null ? '${dl.day.toString().padLeft(2,'0')}/${dl.month.toString().padLeft(2,'0')}' : '';
                    return Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(isOverdue ? Icons.warning_rounded : Icons.timer_outlined, size: 10, color: warnColor),
                        const SizedBox(width: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: warnColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                          child: Text(
                            isOverdue ? 'QUÁ HẠN $dlStr' : 'SẮP HẼT $dlStr',
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: warnColor),
                          ),
                        ),
                      ]),
                    );
                  }),
                ]),
              ),
            ),

            // NGƯỜI GỬI
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 8, 14),
                child: Row(children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: const Color(0xFF3949AB).withValues(alpha: 0.1),
                    child: Text(requesterInitial,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3949AB))),
                  ),
                  const SizedBox(width: 6),
                  Expanded(child: Text(ticket.requesterName ?? 'N/A',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),

            // NGƯỜI XỬ LÝ
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 14, 10, 14),
                child: GestureDetector(
                  onTap: () => _showAssignSheet(ticket),
                  child: isAssigned
                      ? Row(children: [
                          CircleAvatar(
                            radius: 13,
                            backgroundColor: const Color(0xFF00897B).withValues(alpha: 0.1),
                            child: Text(ticket.assigneeName![0].toUpperCase(),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: Text(ticket.assigneeName!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ])
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.person_add_outlined, size: 12, color: Colors.orange),
                            const SizedBox(width: 4),
                            const Flexible(child: Text('Giao việc',
                              overflow: TextOverflow.ellipsis, maxLines: 1,
                              style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold))),
                          ]),
                        ),
                ),
              ),
            ),

            // TRẠNG THÁI
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(_statusLabel(ticket.status).toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ),
              ),
            ),

            // THỜI GIAN
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                child: Row(children: [
                  Icon(Icons.access_time_rounded, size: 11, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Expanded(child: Text(_timeAgo(ticket.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ]),
        ),
      ),
    );
  }

  // ── ASSIGN SHEET ──────────────────────────────────────────────
  void _showAssignSheet(Ticket ticket) async {
    final selected = await showModalBottomSheet<User?>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5, minChildSize: 0.3, maxChildSize: 0.85, expand: false,
        builder: (_, scrollCtrl) => Column(children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Phân công cho', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Chọn nhân viên IT xử lý yêu cầu này', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const Divider(height: 24),
          Expanded(child: ListView(controller: scrollCtrl, children: [
            ListTile(
              leading: CircleAvatar(radius: 20, backgroundColor: Colors.red.withValues(alpha: 0.1),
                child: const Icon(Icons.person_off_outlined, size: 18, color: Colors.red)),
              title: const Text('Bỏ phân công'),
              subtitle: const Text('Chuyển về trạng thái chờ', style: TextStyle(fontSize: 11)),
              trailing: ticket.assigneeId == null ? const Icon(Icons.check_circle, color: Color(0xFF43A047)) : null,
              onTap: () => Navigator.pop(context, null),
            ),
            const Divider(height: 1, indent: 16),
            ..._itStaff.map((staff) => ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF3949AB).withValues(alpha: 0.1),
                child: Text(staff.fullName[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3949AB))),
              ),
              title: Text(staff.fullName, style: TextStyle(fontWeight: ticket.assigneeId == staff.userId ? FontWeight.bold : FontWeight.normal)),
              subtitle: Text(staff.deptName ?? '', style: const TextStyle(fontSize: 11)),
              trailing: ticket.assigneeId == staff.userId ? const Icon(Icons.check_circle, color: Color(0xFF43A047)) : const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () => Navigator.pop(context, staff),
            )),
            const SizedBox(height: 16),
          ])),
        ]),
      ),
    );
    if (selected != null || ticket.assigneeId != null) {
      await _assignTicket(ticket, selected);
    }
  }


  // ── HELPERS ───────────────────────────────────────────────────
  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.85), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _catChip(String label, IconData icon, Color color) {
    final selected = (_categoryFilter ?? 'Tất cả') == label;
    int count;
    if (label == 'Tất cả') {
      count = _tickets.length;
    } else if (label == 'Phần mềm') {
      count = _tickets.where((t) => _softwareCats.contains(t.categoryName ?? '')).length;
    } else {
      count = _tickets.where((t) => _hardwareCats.contains(t.categoryName ?? '')).length;
    }
    return GestureDetector(
      onTap: () => setState(() { _categoryFilter = label; _currentPage = 0; }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: selected ? Colors.white : color),
          const SizedBox(width: 4),
          Text('$label ($count)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? Colors.white : Colors.grey[700])),
        ]),
      ),
    );
  }
}
