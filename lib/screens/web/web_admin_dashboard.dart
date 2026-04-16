import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import 'web_sidebar.dart';
import '../../app_router.dart' show TicketDetailWrapper;

class WebAdminDashboard extends StatefulWidget {
  final User currentUser;
  const WebAdminDashboard({super.key, required this.currentUser});

  @override
  State<WebAdminDashboard> createState() => _WebAdminDashboardState();
}

class _WebAdminDashboardState extends State<WebAdminDashboard> {
  int _sidebarIndex = 0;
  final _repo = TicketRepository.instance;
  List<Ticket> _tickets = [];
  bool _loading = true;
  String _filterStatus = 'Tất cả';
  String _filterType = 'Tất cả';
  String _searchQuery = '';
  Ticket? _selectedTicket;
  Timer? _refreshTimer;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final tickets = await _repo.getAllTickets();
    if (mounted) {
      setState(() {
        _tickets = List<Ticket>.from(tickets)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _loading = false;
      });
    }
  }

  // ── Ticket type helpers ────────────────────────────────────
  static const _typeColors = {
    'ticket': Color(0xFF3949AB),
    'feedback': Color(0xFF00897B),
    'reopen_medical': Color(0xFF5C6BC0),
  };
  static const _typeLabels = {
    'ticket': 'IT Ticket',
    'feedback': 'Góp ý',
    'reopen_medical': 'Mở lại BA',
  };
  static const _typeIcons = {
    'ticket': Icons.build_circle_rounded,
    'feedback': Icons.feedback_rounded,
    'reopen_medical': Icons.folder_open_rounded,
  };
  static const _typePrefixes = {
    'ticket': 'TK',
    'feedback': 'GY',
    'reopen_medical': 'BA',
  };

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFF3B82F6);
      case 'Pending': return const Color(0xFFF59E0B);
      case 'Resolved': return const Color(0xFF10B981);
      case 'Cancelled': return const Color(0xFFE53935);
      case 'Closed': return const Color(0xFF64748B);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'Open': return 'Mở';
      case 'Pending': return 'Đang xử lý';
      case 'WaitingConfirmation': return 'Chờ xác nhận';
      case 'Resolved': return 'Hoàn thành';
      case 'Cancelled': return 'Từ chối';
      case 'Closed': return 'Đã đóng';
      default: return s;
    }
  }

  String _getTicketStatusLabel(Ticket t) {
    if (t.ticketType == 'reopen_medical') {
      switch (t.status) {
        case 'Open': return 'Chờ duyệt';
        case 'Pending': return 'Đang mở BA';
        case 'WaitingConfirmation': return 'Chờ đóng BA';
        case 'Resolved': return 'Đã duyệt';
        case 'Cancelled': return 'Từ chối';
        case 'Closed': return 'Đã đóng';
      }
    } else if (t.ticketType == 'feedback') {
      switch (t.status) {
        case 'Open': return 'Chờ tiếp nhận';
        case 'Pending': return 'Đang xem xét';
        case 'Resolved': return 'Đã tiếp nhận';
        case 'Cancelled': return 'Từ chối';
      }
    }
    return _statusLabel(t.status);
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High': return const Color(0xFFE53935);
      case 'Medium': return const Color(0xFFFB8C00);
      case 'Low': return const Color(0xFF43A047);
      default: return Colors.grey;
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  List<Ticket> get _filtered {
    var list = _tickets.toList();
    // Type filter
    if (_filterType != 'Tất cả') {
      list = list.where((t) => t.ticketType == _filterType).toList();
    }
    // Status filter
    if (_filterStatus != 'Tất cả') {
      list = list.where((t) => t.status == _filterStatus).toList();
    }
    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) =>
        t.subject.toLowerCase().contains(q) ||
        (t.requesterName ?? '').toLowerCase().contains(q) ||
        t.ticketId.toString().contains(q)
      ).toList();
    }
    return list;
  }

  // ── Count helpers ──────────────────────────────────────────
  int _countByType(String type) => _tickets.where((t) => t.ticketType == type).length;
  int _countByStatus(String status) {
    var list = _filterType == 'Tất cả'
        ? _tickets
        : _tickets.where((t) => t.ticketType == _filterType);
    return list.where((t) => t.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Sidebar
          WebSidebar(
            currentUser: widget.currentUser,
            selectedIndex: _sidebarIndex,
            onItemSelected: (index) {
              setState(() => _sidebarIndex = index);
              if (index == 1) context.push('/admin/reports');
              if (index == 2) context.push('/admin/it-workload');
              if (index == 3) context.push('/admin/emergency-contacts');
            },
          ),

          // 2. Main content
          Expanded(
            child: _selectedTicket != null
                ? Row(
                    children: [
                      Expanded(flex: 4, child: _buildMainContent()),
                      Container(width: 1, color: Colors.grey.shade200),
                      Expanded(flex: 5, child: _buildDetailPane()),
                    ],
                  )
                : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final filtered = _filtered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: const Text(
                    'Quản lý yêu cầu',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  _buildRefreshButton(),
                  const SizedBox(width: 12),
                  _buildCreateButton(),
                ]),
              ],
            ),
            const SizedBox(height: 18),

            // ── Type tabs ─────────────────────────────────────
            _buildTypeTabs(),
            const SizedBox(height: 14),

            // ── Search + Status filters ─────────────────────
            Row(children: [
              // Search
              SizedBox(
                width: 220,
                height: 36,
                child: TextField(
                  onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Status chips
              Expanded(child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _statusChip('Tất cả', null),
                  _statusChip('Open', _statusColor('Open')),
                  _statusChip('Pending', _statusColor('Pending')),
                  _statusChip('WaitingConfirmation', _statusColor('WaitingConfirmation')),
                  _statusChip('Resolved', _statusColor('Resolved')),
                  _statusChip('Cancelled', _statusColor('Cancelled')),
                ]),
              )),
            ]),
          ]),
        ),

        // ── Result count ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 8),
          child: Text(
            '${filtered.length} kết quả',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
        ),

        // ── Ticket list ─────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3949AB)))
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildListWithPagination(filtered),
        ),
      ],
    );
  }

  // ── Type tabs ────────────────────────────────────────────
  Widget _buildTypeTabs() {
    return Row(children: [
      _typeTab('Tất cả', 'Tất cả', Icons.dashboard_rounded, _tickets.length, const Color(0xFF64748B)),
      const SizedBox(width: 8),
      _typeTab('ticket', 'IT Ticket', Icons.build_circle_rounded, _countByType('ticket'), _typeColors['ticket']!),
      const SizedBox(width: 8),
      _typeTab('feedback', 'Góp ý', Icons.feedback_rounded, _countByType('feedback'), _typeColors['feedback']!),
      const SizedBox(width: 8),
      _typeTab('reopen_medical', 'Mở lại BA', Icons.folder_open_rounded, _countByType('reopen_medical'), _typeColors['reopen_medical']!),
    ]);
  }

  Widget _typeTab(String value, String label, IconData icon, int count, Color color) {
    final isSelected = _filterType == value;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() {
        _filterType = value;
        _filterStatus = 'Tất cả';
        _currentPage = 1;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color.withValues(alpha: 0.4) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16, color: isSelected ? color : Colors.grey.shade400),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? color : Colors.grey.shade600,
          )),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('$count', style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? color : Colors.grey.shade500,
            )),
          ),
        ]),
      ),
    );
  }

  // ── Status chip ──────────────────────────────────────────
  Widget _statusChip(String value, Color? color) {
    final isSelected = _filterStatus == value;
    final count = value == 'Tất cả' ? _filtered.length : _countByStatus(value);
    final displayLabel = value == 'Tất cả' ? 'Tất cả' : _statusLabel(value);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() { _filterStatus = value; _currentPage = 1; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? (color ?? const Color(0xFF64748B)).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? (color ?? const Color(0xFF64748B)).withValues(alpha: 0.4) : Colors.grey.shade200,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (color != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Text(displayLabel, style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? (color ?? const Color(0xFF64748B)) : Colors.grey.shade600,
            )),
            const SizedBox(width: 4),
            Text('$count', style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
          ]),
        ),
      ),
    );
  }

  Widget _buildListWithPagination(List<Ticket> filtered) {
    final totalPages = (filtered.length / _itemsPerPage).ceil();
    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;
    final paginated = filtered.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();
    
    return Column(
      children: [
        Expanded(child: _buildList(paginated)),
        if (totalPages > 1) 
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                ),
                Text('Trang $_currentPage / $totalPages', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildList(List<Ticket> tickets) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final t = tickets[i];
        final isSelected = _selectedTicket?.ticketId == t.ticketId;
        final typeColor = _typeColors[t.ticketType] ?? Colors.grey;
        final prefix = _typePrefixes[t.ticketType] ?? 'TK';
        final typeLabel = _typeLabels[t.ticketType] ?? 'Ticket';
        final typeIcon = _typeIcons[t.ticketType] ?? Icons.confirmation_number;
        final statusColor = _statusColor(t.status);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedTicket = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? typeColor.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? typeColor.withValues(alpha: 0.5) : Colors.grey.shade100,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(color: typeColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))
                else
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Row 1: Type badge + ID + Status + Time
              Row(children: [
                // Type badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(typeIcon, size: 11, color: typeColor),
                    const SizedBox(width: 3),
                    Text(typeLabel, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: typeColor)),
                  ]),
                ),
                const SizedBox(width: 6),
                // Ticket ID
                Text(
                  '#$prefix-${t.ticketId.toString().padLeft(4, '0')}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
                ),
                const Spacer(),
                // Status
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getTicketStatusLabel(t),
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              // Row 2: Subject
              Text(
                t.subject,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (t.ticketType == 'reopen_medical' && t.description.isNotEmpty) ...[
                Builder(builder: (context) {
                  final desc = t.description;
                  final idx = desc.indexOf('Lý do mở lại:');
                  final reason = idx != -1 ? desc.substring(idx + 13).trim().replaceAll('\n', ' ') : desc.trim().replaceAll('\n', ' ');
                  return reason.isNotEmpty ? Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Lý do: $reason',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ) : const SizedBox();
                }),
              ],
              if (t.ticketType == 'reopen_medical' && t.description.toLowerCase().contains('ảnh hưởng tài chính: có'))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.monetization_on_rounded, size: 12, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text('Có ảnh hưởng tài chính', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                  ]),
                ),
              // Row 3: Requester + Department + Priority + Time
              Row(children: [
                Icon(Icons.person_outline, size: 13, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(
                  t.requesterName ?? 'Người dùng đã xóa',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                if (t.requesterDeptName != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.apartment_rounded, size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Flexible(child: Text(
                    t.requesterDeptName!,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
                const Spacer(),
                // Priority dot
                if (t.ticketType == 'ticket') ...[
                  Container(
                    width: 7, height: 7,
                    decoration: BoxDecoration(color: _priorityColor(t.priority), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 3),
                  Text(t.priority, style: TextStyle(fontSize: 10, color: _priorityColor(t.priority), fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                ],
                // Time
                Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 3),
                Text(_relativeTime(t.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
              ]),
              if (t.ticketType == 'reopen_medical' && t.status == 'Open') ...[
                const SizedBox(height: 12),
                Container(height: 1, color: Colors.grey.shade100, margin: const EdgeInsets.only(bottom: 12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Duyệt Mở Lại', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        try {
                          await _repo.updateStatus(t.ticketId, 'Resolved');
                          _loadData();
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('✅ Đã duyệt yêu cầu mở lại bệnh án'),
                              backgroundColor: Color(0xFF43A047),
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        } catch (e) {
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                              content: Text('❌ Lỗi cập nhật trạng thái!'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ],
            ]),
          ),
        );
      },
    );
  }

  // ── Detail pane ──────────────────────────────────────────
  Widget _buildDetailPane() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4)],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Đóng chi tiết',
                  onPressed: () => setState(() => _selectedTicket = null),
                ),
                const SizedBox(width: 4),
                // Type + ID badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (_typeColors[_selectedTicket!.ticketType] ?? Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_typeIcons[_selectedTicket!.ticketType] ?? Icons.confirmation_number, size: 13,
                      color: _typeColors[_selectedTicket!.ticketType] ?? Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '#${_typePrefixes[_selectedTicket!.ticketType] ?? 'TK'}-${_selectedTicket!.ticketId.toString().padLeft(4, '0')}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: _typeColors[_selectedTicket!.ticketType] ?? Colors.grey),
                    ),
                  ]),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  tooltip: 'Mở trang riêng',
                  onPressed: () {
                    final t = _selectedTicket;
                    context.push('/ticket/${t!.ticketId}', extra: t);
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: TicketDetailWrapper(
              key: ValueKey('detail_${_selectedTicket!.ticketId}_${_selectedTicket!.ticketType}'),
              ticketId: _selectedTicket!.ticketId,
              ticket: _selectedTicket,
              currentUser: widget.currentUser,
              isAdmin: true,
              isEmbedded: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────
  Widget _buildRefreshButton() {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: const Color(0xFFF1F5F9),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          setState(() => _loading = true);
          _loadData();
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.refresh_rounded, size: 20, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Tạo mới', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      onPressed: () => context.push('/create-ticket'),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Không có yêu cầu nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        Text('Thử đổi bộ lọc hoặc tìm kiếm khác', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ]),
    );
  }
}
