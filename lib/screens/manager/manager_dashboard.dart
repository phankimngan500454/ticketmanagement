import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';

class ManagerDashboard extends StatefulWidget {
  final User currentUser;
  const ManagerDashboard({super.key, required this.currentUser});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final _repo = TicketRepository.instance;
  List<Ticket> _feedbacks = [];
  bool _loading = true;
  String _filterStatus = 'Tất cả';
  String? _deptFilter;
  String _searchQuery = '';
  String? _typeFilter; // null=Tất cả, 'feedback', 'reopen_medical'
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _refreshTimer;

  // Notification badge: track known ticket IDs to detect new ones
  final Set<int> _knownTicketIds = {};
  int _newNotifCount = 0;

  static const _purple = Color(0xFF00897B);     // teal
  static const _purpleDark = Color(0xFF00695C);  // teal dark

  // Status maps based on ticket type
  static const _feedbackStatusMap = {
    'Open': 'Đang xử lý',
    'Pending': 'Đang xem xét',
    'Resolved': 'Đã tiếp nhận',
    'Cancelled': 'Từ chối',
    'Closed': 'Đã đóng',
  };

  static const _medicalStatusMap = {
    'Open': 'Chờ duyệt',
    'Pending': 'Đang mở BA',
    'WaitingConfirmation': 'Chờ đóng BA',
    'Resolved': 'Đã duyệt',
    'Cancelled': 'Từ chối',
    'Closed': 'Đã đóng BA',
  };

  Map<String, String> _getMapForTicket(Ticket t) {
    return t.ticketType == 'reopen_medical' ? _medicalStatusMap : _feedbackStatusMap;
  }

  String _getStatusLabel(Ticket t) {
    return _getMapForTicket(t)[t.status] ?? t.status;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFF78909C);
      case 'Pending': return const Color(0xFFFB8C00);
      case 'WaitingConfirmation': return const Color(0xFF0097A7); // Cyan
      case 'Resolved': return const Color(0xFF10B981);
      case 'Cancelled': return const Color(0xFFE53935);
      case 'Closed': return const Color(0xFF64748B);
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final feedbacks = await _repo.getFeedbackTickets();
      if (mounted) {
        setState(() {
          // Detect new tickets not seen before
          if (_knownTicketIds.isNotEmpty) {
            final newOnes = feedbacks.where((t) => !_knownTicketIds.contains(t.ticketId)).length;
            if (newOnes > 0) _newNotifCount += newOnes;
          }
          _knownTicketIds.addAll(feedbacks.map((t) => t.ticketId));
          _feedbacks = feedbacks;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted && context.mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Không tải được danh sách góp ý!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  List<String> get _departments {
    final depts = _feedbacks
        .map((t) => t.requesterDeptName)
        .where((d) => d != null && d.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();
    depts.sort();
    return depts;
  }

  List<Ticket> get _filtered {
    final q = _searchQuery.toLowerCase().trim();
    return _feedbacks.where((t) {
      if (_typeFilter == 'feedback' && t.ticketType != 'feedback') return false;
      if (_typeFilter == 'reopen_medical' && t.ticketType != 'reopen_medical') return false;
      if (_typeFilter == 'reopen_medical_ins' && t.ticketType != 'reopen_medical') return false;
      if (_typeFilter == 'reopen_medical_fin' && (t.ticketType != 'reopen_medical' || !t.description.toLowerCase().contains('ảnh hưởng tài chính: có'))) return false;

      final matchStatus = _filterStatus == 'Tất cả' || t.status == _filterStatus;
      final matchDept = _deptFilter == null || t.requesterDeptName == _deptFilter;
      final matchSearch = q.isEmpty ||
          t.subject.toLowerCase().contains(q) ||
          (t.requesterName ?? '').toLowerCase().contains(q) ||
          (t.requesterDeptName ?? '').toLowerCase().contains(q) ||
          t.ticketId.toString().contains(q);
      return matchStatus && matchDept && matchSearch;
    }).toList();
  }

  Future<void> _updateFeedbackStatus(Ticket ticket, String newStatus) async {
    try {
      await _repo.updateStatus(ticket.ticketId, newStatus);
      await _loadData();
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Đã cập nhật: ${_getStatusLabel(ticket)}'),
          backgroundColor: _statusColor(newStatus),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('❌ Lỗi cập nhật trạng thái!'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  void _showNoteDialog(Ticket ticket) {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.note_add_rounded, color: _purple, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ghi chú', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('#GY-${ticket.ticketId.toString().padLeft(4, '0')} — ${ticket.subject}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            )),
          ]),
          const SizedBox(height: 16),
          TextField(
            controller: noteCtrl,
            maxLines: 4,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
              filled: true,
              fillColor: const Color(0xFFF8F9FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _purple, width: 1.5),
              ),
            ),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Gửi ghi chú', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () async {
                if (noteCtrl.text.trim().isEmpty) return;
                try {
                  await _repo.addComment(
                    ticketId: ticket.ticketId,
                    userId: widget.currentUser.userId,
                    commentText: noteCtrl.text.trim(),
                  );
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('✅ Đã ghi chú!'),
                      backgroundColor: _purple,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ));
                  }
                } catch (e) {
                  if (mounted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: const Text('❌ Lỗi ghi chú!'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                }
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _showDeptPicker() {
    String deptSearch = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final depts = _departments.where((d) =>
            deptSearch.isEmpty || d.toLowerCase().contains(deptSearch.toLowerCase())
          ).toList();
          return DraggableScrollableSheet(
            initialChildSize: 0.55,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (_, scrollCtrl) => Column(children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('Chọn Khoa / Phòng ban',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('${_departments.length} khoa',
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              const SizedBox(height: 12),
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  autofocus: true,
                  onChanged: (v) => setSheetState(() => deptSearch = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm khoa...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[400]),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: const Color(0xFFF4F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _purple, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Divider(height: 1),
              // "Tất cả" option
              ListTile(
                leading: CircleAvatar(radius: 16,
                  backgroundColor: _deptFilter == null ? _purple.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
                  child: Icon(Icons.apps_rounded, size: 16,
                    color: _deptFilter == null ? _purple : Colors.grey[500])),
                title: Text('Tất cả khoa', style: TextStyle(
                  fontWeight: _deptFilter == null ? FontWeight.bold : FontWeight.normal,
                  color: _deptFilter == null ? _purple : Colors.grey[700])),
                trailing: _deptFilter == null
                  ? const Icon(Icons.check_circle, color: _purple, size: 20)
                  : null,
                onTap: () {
                  setState(() => _deptFilter = null);
                  Navigator.pop(ctx);
                },
              ),
              const Divider(height: 1, indent: 16),
              // Dept list
              Expanded(child: ListView.builder(
                controller: scrollCtrl,
                itemCount: depts.length,
                itemBuilder: (_, i) {
                  final d = depts[i];
                  final selected = _deptFilter == d;
                  return ListTile(
                    leading: CircleAvatar(radius: 16,
                      backgroundColor: selected ? _purple.withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.08),
                      child: Icon(Icons.business_rounded, size: 16,
                        color: selected ? _purple : Colors.grey[500])),
                    title: Text(d, style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? _purple : Colors.grey[700], fontSize: 14)),
                    trailing: selected
                      ? const Icon(Icons.check_circle, color: _purple, size: 20)
                      : Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
                    onTap: () {
                      setState(() => _deptFilter = d);
                      Navigator.pop(ctx);
                    },
                  );
                },
              )),
            ]),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays}d trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final openCount = _feedbacks.where((t) => t.status == 'Open').length;
    final pendingCount = _feedbacks.where((t) => t.status == 'Pending').length;
    final waitingCount = _feedbacks.where((t) => t.status == 'WaitingConfirmation').length;
    final resolvedCount = _feedbacks.where((t) => t.status == 'Resolved').length;
    final cancelledCount = _feedbacks.where((t) => t.status == 'Cancelled').length;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _purple))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: _purple,
              child: NestedScrollView(
                headerSliverBuilder: (ctx, innerBoxScrolled) => [
                  SliverToBoxAdapter(child: Column(children: [
                    // ── HEADER ─────────────────────────────────────────
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: [_purpleDark, _purple],
                        ),
                      ),
                      child: SafeArea(bottom: false, child: Column(children: [
                        // Top row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                          child: Row(children: [
                            Expanded(child: Text('Quản lý Góp ý',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                                  context.go('/login');
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
                                        backgroundColor: _purple.withValues(alpha: 0.12),
                                        child: Text(widget.currentUser.fullName[0],
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: _purple)),
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
                                      decoration: BoxDecoration(color: _purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.manage_accounts_rounded, color: _purple, size: 17),
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
                        // Stat row
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                          child: Row(children: [
                            _statCard('Tổng', '${_feedbacks.length}', const Color(0xFFCE93D8)),
                            const SizedBox(width: 8),
                            _statCard('Chưa xử lý', '$openCount', const Color(0xFF90A4AE)),
                            const SizedBox(width: 8),
                            _statCard('Đang làm', '${pendingCount + waitingCount}', const Color(0xFFFFCC80)),
                            const SizedBox(width: 8),
                            _statCard('Xong', '$resolvedCount', const Color(0xFFA5D6A7)),
                          ]),
                        ),
                      ])),
                    ),

                    // ── SEARCH + FILTER ─────────────────────────────────
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Tìm góp ý, tên người gửi...',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                          prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[400]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? GestureDetector(
                                  onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                                  child: Icon(Icons.close, size: 16, color: Colors.grey[400]))
                              : null,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          filled: true, fillColor: const Color(0xFFF4F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _purple, width: 1.5)),
                        ),
                      ),
                    ),
                  ])),
                ],
                body: _buildFeedbackBody(filtered, openCount, pendingCount, resolvedCount, cancelledCount, waitingCount),
              ),
            ),
    );
  }

  Widget _buildFeedbackBody(List<Ticket> filtered, int openCount, int pendingCount, int resolvedCount, int cancelledCount, int waitingCount) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Row 1: Type filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                _typeChip(null, 'Tất cả', _feedbacks.length),
                const SizedBox(width: 6),
                if (widget.currentUser.role == 'Manager') ...[
                  _typeChip('feedback', 'Góp ý', _feedbacks.where((t) => t.ticketType == 'feedback').length),
                  const SizedBox(width: 6),
                ],
                if (widget.currentUser.role == 'Manager' || (widget.currentUser.permissions ?? '').contains('insurance')) ...[
                  _typeChip('reopen_medical_ins', 'Bệnh Án', _feedbacks.where((t) => t.ticketType == 'reopen_medical').length),
                  const SizedBox(width: 6),
                ],
                if ((widget.currentUser.permissions ?? '').contains('finance')) ...[
                  _typeChip('reopen_medical_fin', 'Tài Chính', _feedbacks.where((t) => t.ticketType == 'reopen_medical' && t.description.toLowerCase().contains('ảnh hưởng tài chính: có')).length),
                ],
              ]),
            ),
            const SizedBox(height: 10),
            // Row 2: Status & Dept filters
            Row(children: [
              Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _filterChip('Tất cả', null, _feedbacks.length),
                  const SizedBox(width: 6),
                  _filterChip('Open', 'Chưa bắt đầu', openCount),
                  const SizedBox(width: 6),
                  _filterChip('Pending', 'Đang thực hiện', pendingCount),
                  const SizedBox(width: 6),
                  _filterChip('Resolved', 'Đã hoàn thành', resolvedCount),
                  const SizedBox(width: 6),
                  _filterChip('Cancelled', 'Từ chối', cancelledCount),
                  const SizedBox(width: 6),
                  _filterChip('WaitingConfirmation', 'Chờ đóng BA', waitingCount),
                ]),
              ),
            ),
            if (_departments.isNotEmpty) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showDeptPicker(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: _deptFilter != null ? _purple : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _deptFilter != null ? _purple : Colors.grey.shade200),
                    boxShadow: _deptFilter != null ? [BoxShadow(color: _purple.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.business_rounded, size: 13,
                      color: _deptFilter != null ? Colors.white : Colors.grey[600]),
                    const SizedBox(width: 5),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 80),
                      child: Text(
                        _deptFilter ?? 'Khoa',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: _deptFilter != null ? Colors.white : Colors.grey[600]),
                        overflow: TextOverflow.ellipsis, maxLines: 1,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, size: 16,
                      color: _deptFilter != null ? Colors.white : Colors.grey[500]),
                  ]),
                ),
              ),
            ],
          ]),
          ]),
        )),

        // Section header
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
          child: Row(children: [
            const Icon(Icons.feedback_rounded, size: 15, color: _purple),
            const SizedBox(width: 6),
            Text(
              _filterStatus == 'Tất cả' ? 'Tất cả' : _filterStatus,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _purpleDark),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: _purple.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('${filtered.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _purple)),
            ),
          ]),
        )),

        // ── FEEDBACK LIST ──────────────────────────────
        if (filtered.isEmpty)
          SliverFillRemaining(child: _emptyState())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _feedbackCard(filtered[i]),
                childCount: filtered.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _typeChip(String? type, String label, int count) {
    final selected = _typeFilter == type;
    return GestureDetector(
      onTap: () => setState(() => _typeFilter = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _purpleDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? _purpleDark : Colors.grey.shade300),
          boxShadow: selected ? [BoxShadow(color: _purpleDark.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700],
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withValues(alpha: 0.25) : _purple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text('$count', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.bold,
              color: selected ? Colors.white : _purple,
            )),
          ),
        ]),
      ),
    );
  }

  Widget _filterChip(String statusKey, String? label, int count) {
    final isAll = statusKey == 'Tất cả';
    final selected = _filterStatus == statusKey;
    final color = isAll ? _purple : _statusColor(statusKey);
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = statusKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade200),
          boxShadow: selected ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            isAll ? 'Tất cả' : (label ?? statusKey),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[600]),
          ),
          if (count > 0) ...[
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.3) : color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : color)),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _feedbackCard(Ticket ticket) {
    final statusColor = _statusColor(ticket.status);
    final isReopen = ticket.ticketType == 'reopen_medical';
    final cardColor = isReopen ? const Color.fromARGB(255, 148, 182, 234) : _purple;
    final cardPrefix = isReopen ? 'BA' : 'GY';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.07),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            _refreshTimer?.cancel();
            await context.push('/ticket/${ticket.ticketId}', extra: ticket);
            _loadData();
            _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left stripe — dynamic color
                Container(width: 5, color: cardColor.withValues(alpha: 0.6)),
                Expanded(child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Row 1: ID + type badge + time
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cardColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(isReopen ? Icons.folder_open_rounded : Icons.tag, size: 11, color: cardColor),
                            const SizedBox(width: 3),
                            Text('$cardPrefix-${ticket.ticketId.toString().padLeft(4, '0')}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: cardColor, fontSize: 12)),
                          ]),
                        ),
                        if (isReopen) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 148, 182, 234),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Mở lại BA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ],
                        const Spacer(),
                        Icon(Icons.access_time_rounded, size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 3),
                        Text(_formatTime(ticket.createdAt),
                          style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                      ]),
                      const SizedBox(height: 8),

                      // Row 2: Subject
                      Text(ticket.subject,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E), height: 1.3),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),

                      // Row 3: Description preview
                      if (ticket.description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(ticket.description,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600], height: 1.3),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),

                      // Row 4: Requester + dept
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.person_outline, size: 13, color: Color(0xFF1976D2)),
                            const SizedBox(width: 4),
                            Text(ticket.requesterName ?? 'Người dùng đã xóa',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1976D2))),
                          ]),
                        ),
                        if (ticket.requesterDeptName != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.business_outlined, size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 3),
                          Flexible(child: Text(ticket.requesterDeptName!,
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            overflow: TextOverflow.ellipsis)),
                        ],
                      ]),
                      const SizedBox(height: 10),

                      // Row 5: Status dropdown + Note button
                      Row(children: [
                        // Status dropdown
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: ticket.status,
                                isDense: true,
                                isExpanded: true,
                                icon: Icon(Icons.arrow_drop_down, color: statusColor, size: 20),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: statusColor),
                                items: _getMapForTicket(ticket).entries.map((e) {
                                  final sc = _statusColor(e.key);
                                  return DropdownMenuItem(
                                    value: e.key,
                                    child: Row(children: [
                                      Container(width: 8, height: 8,
                                        decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Text(e.value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc)),
                                    ]),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null && val != ticket.status) {
                                    _updateFeedbackStatus(ticket, val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Note button
                        Material(
                          color: _purple.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _showNoteDialog(ticket),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.note_add_outlined, size: 16, color: _purple),
                                SizedBox(width: 4),
                                Text('Ghi chú',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _purple)),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ],
                  ),
                )),
              ],
            )),
          ),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
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

  Widget _emptyState() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: _purple.withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(Icons.feedback_outlined, size: 64, color: _purple.withValues(alpha: 0.4)),
      ),
      const SizedBox(height: 16),
      const Text('Chưa có góp ý nào', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Góp ý từ nhân viên sẽ hiện tại đây',
        style: TextStyle(fontSize: 13, color: Colors.grey[500]), textAlign: TextAlign.center),
    ],
  ));
}
