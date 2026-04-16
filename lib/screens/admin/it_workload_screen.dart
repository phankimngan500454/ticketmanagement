import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';

class ITWorkloadScreen extends StatefulWidget {
  final User currentUser;
  const ITWorkloadScreen({super.key, required this.currentUser});

  @override
  State<ITWorkloadScreen> createState() => _ITWorkloadScreenState();
}

class _ITWorkloadScreenState extends State<ITWorkloadScreen> {
  final _repo = TicketRepository.instance;
  List<User> _itStaff = [];
  List<Ticket> _tickets = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  String _filterTab = 'all'; // all | busy | free
  int? _expandedUserId;

  static const _accent = Color(0xFF2563EB);
  static const _green = Color(0xFF10B981);
  static const _amber = Color(0xFFF59E0B);

  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final staff = await _repo.getITStaff();
    final tickets = await _repo.getAllTickets();
    if (mounted) setState(() { _itStaff = staff; _tickets = tickets; _loading = false; });
  }

  List<Ticket> _activeTicketsFor(int userId) =>
      _tickets.where((t) => t.assigneeId == userId && t.status != 'Resolved' && t.status != 'Cancelled').toList();

  bool _isFree(User s) => _activeTicketsFor(s.userId).isEmpty;

  List<User> get _filteredStaff {
    final q = _searchQuery.toLowerCase().trim();
    Iterable<User> base = _itStaff;
    if (_filterTab == 'busy') base = base.where((s) => !_isFree(s));
    if (_filterTab == 'free') base = base.where((s) => _isFree(s));
    if (q.isNotEmpty) base = base.where((s) =>
        s.fullName.toLowerCase().contains(q) || s.username.toLowerCase().contains(q));
    // Sort: busy first, then by ticket count desc
    final result = base.toList();
    result.sort((a, b) {
      final aCount = _activeTicketsFor(a.userId).length;
      final bCount = _activeTicketsFor(b.userId).length;
      return bCount.compareTo(aCount);
    });
    return result;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFF3B82F6);
      case 'Pending': return _amber;
      case 'WaitingConfirmation': return const Color(0xFF8B5CF6);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Open': return 'Mở';
      case 'Pending': return 'Đang xử lý';
      case 'WaitingConfirmation': return 'Chờ xác nhận';
      default: return s;
    }
  }

  Color _priorityColor(String? p) {
    switch (p) {
      case 'High': return const Color(0xFFEF4444);
      case 'Medium': return _amber;
      default: return _accent;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    return '${diff.inDays}d trước';
  }

  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final freeCount = _itStaff.where(_isFree).length;
    final busyCount = _itStaff.length - freeCount;
    final shown = _filteredStaff;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _iconBtn(Icons.arrow_back_rounded, () => context.go('/admin')),
              const SizedBox(width: 16),
              const Expanded(child: Text('Theo dõi IT',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF1E293B)))),
              _iconBtn(Icons.refresh_rounded, () { setState(() => _loading = true); _loadData(); }),
            ]),
            const SizedBox(height: 20),

            // Filter + Search row
            Row(children: [
              _filterBtn('Tất cả (${_itStaff.length})', 'all'),
              const SizedBox(width: 6),
              _filterBtn('Đang bận ($busyCount)', 'busy', color: _amber),
              const SizedBox(width: 6),
              _filterBtn('Rảnh ($freeCount)', 'free', color: _green),
              const Spacer(),
              SizedBox(
                width: 220,
                height: 34,
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true, fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: _accent, width: 1.5)),
                  ),
                ),
              ),
            ]),
          ]),
        ),

        // ── Table header ──
        Container(
          margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            const SizedBox(width: 48),
            Expanded(flex: 3, child: Text('NHÂN VIÊN', style: _colHeader)),
            Expanded(flex: 2, child: Text('TRẠNG THÁI', style: _colHeader)),
            SizedBox(width: 80, child: Text('SỐ TICKET', style: _colHeader, textAlign: TextAlign.center)),
            const SizedBox(width: 40),
          ]),
        ),

        // ── List ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : shown.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.engineering_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('Không tìm thấy', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                    ]))
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                      itemCount: shown.length,
                      itemBuilder: (_, i) => _buildRow(shown[i]),
                    ),
        ),
      ]),
    );
  }

  Widget _filterBtn(String label, String key, {Color? color}) {
    final selected = _filterTab == key;
    final c = color ?? const Color(0xFF64748B);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() => _filterTab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? c.withValues(alpha: 0.4) : Colors.grey.shade200),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          color: selected ? c : Colors.grey.shade600,
        )),
      ),
    );
  }

  // ── Single staff row (expandable) ──
  Widget _buildRow(User staff) {
    final tickets = _activeTicketsFor(staff.userId);
    final isFree = tickets.isEmpty;
    final isExpanded = _expandedUserId == staff.userId;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isExpanded ? _accent.withValues(alpha: 0.25) : Colors.grey.shade100),
      ),
      child: Column(children: [
        // Main row
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: const Color(0xFFFAFBFC),
            onTap: isFree ? null : () => setState(() => _expandedUserId = isExpanded ? null : staff.userId),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                // Avatar
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: (isFree ? _green : _amber).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(child: Text(
                    staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isFree ? _green : _amber),
                  )),
                ),
                const SizedBox(width: 12),

                // Name
                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text(staff.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis),
                  if (staff.username.isNotEmpty)
                    Text('@${staff.username}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                ])),

                // Status
                Expanded(flex: 2, child: Row(children: [
                  Container(width: 7, height: 7, decoration: BoxDecoration(
                    color: isFree ? _green : _amber, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(isFree ? 'Rảnh' : 'Đang bận',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isFree ? _green : _amber)),
                ])),

                // Ticket count
                SizedBox(width: 80, child: Center(
                  child: isFree
                    ? Text('0', style: TextStyle(fontSize: 13, color: Colors.grey.shade300))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${tickets.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _accent)),
                      ),
                )),

                // Expand icon
                SizedBox(width: 40, child: Center(
                  child: isFree
                    ? const SizedBox.shrink()
                    : AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.grey.shade400),
                      ),
                )),
              ]),
            ),
          ),
        ),

        // Expanded ticket list
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildTicketList(tickets),
          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ]),
    );
  }

  Widget _buildTicketList(List<Ticket> tickets) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFC),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: tickets.map((t) {
          final sc = _statusColor(t.status);
          final pc = _priorityColor(t.priority);
          return InkWell(
            onTap: () async {
              await context.push('/ticket/${t.ticketId}', extra: t);
              _loadData();
            },
            hoverColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              child: Row(children: [
                // Priority dot
                Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(color: pc, shape: BoxShape.circle)),
                // ID
                SizedBox(width: 70, child: Text('#TK-${t.ticketId.toString().padLeft(4, '0')}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade500))),
                // Subject
                Expanded(child: Text(t.subject,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(_statusLabel(t.status), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sc)),
                ),
                const SizedBox(width: 10),
                // Time
                Text(_relativeTime(t.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded, size: 14, color: Colors.grey.shade300),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: const Color(0xFFF1F5F9),
      child: InkWell(borderRadius: BorderRadius.circular(8), onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(8), child: Icon(icon, size: 20, color: Colors.grey.shade600))),
    );
  }

  TextStyle get _colHeader => TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade400, letterSpacing: 0.5,
  );
}
