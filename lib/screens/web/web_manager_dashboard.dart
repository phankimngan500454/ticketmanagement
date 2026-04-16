import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import 'web_manager_sidebar.dart';
import '../../app_router.dart' show TicketDetailWrapper;

class WebManagerDashboard extends StatefulWidget {
  final User currentUser;
  const WebManagerDashboard({super.key, required this.currentUser});

  @override
  State<WebManagerDashboard> createState() => _WebManagerDashboardState();
}

class _WebManagerDashboardState extends State<WebManagerDashboard> {
  final _repo = TicketRepository.instance;
  List<Ticket> _feedbacks = [];
  bool _loading = true;
  String _filterStatus = 'Tất cả';
  String? _deptFilter;
  String _searchQuery = '';
  String? _typeFilter; // null=Tất cả, 'feedback', 'reopen_medical'
  Ticket? _selectedTicket;
  Timer? _refreshTimer;
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  static const _purple = Color(0xFF00897B);

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
    try {
      final feedbacks = await _repo.getFeedbackTickets();
      if (mounted) {
        setState(() {
          _feedbacks = List.from(feedbacks)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          if (_selectedTicket != null) {
            try {
               _selectedTicket = _feedbacks.firstWhere((t) => t.ticketId == _selectedTicket!.ticketId);
            } catch (e) {
               _selectedTicket = null;
            }
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
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

  Color _statusColor(String s) {
    switch (s) {
      case 'Open': return const Color(0xFF3B82F6);
      case 'Pending': return const Color(0xFFF59E0B);
      case 'WaitingConfirmation': return const Color(0xFF8B5CF6);
      case 'Resolved': return const Color(0xFF10B981);
      case 'Cancelled': return const Color(0xFFE53935);
      case 'Closed': return const Color(0xFF64748B);
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
        case 'Cancelled': return 'Từ chối';
        case 'Closed': return 'Đã đóng BA';
        default: return t.status;
      }
    } else {
      switch (t.status) {
        case 'Open': return 'Chưa xử lý';
        case 'Pending': return 'Đang xem xét';
        case 'Resolved': return 'Đã tiếp nhận';
        case 'Cancelled': return 'Từ chối';
        default: return t.status;
      }
    }
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m trước';
    if (diff.inHours < 24) return '${diff.inHours}h trước';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          WebManagerSidebar(
            currentUser: widget.currentUser,
            selectedType: _typeFilter,
            onTypeSelected: (type) {
              setState(() {
                _typeFilter = type;
                _selectedTicket = null;
              });
            },
          ),
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
                    'Quản lý Xét duyệt',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRefreshButton(),
              ],
            ),
            const SizedBox(height: 18),
            Row(children: [
              SizedBox(
                width: 200,
                child: TextField(
                  onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 1; }),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm ID, tiêu đề...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _purple, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (_departments.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: _deptFilter != null ? _purple : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String?>(
                      value: _deptFilter,
                      icon: Icon(Icons.arrow_drop_down, color: _deptFilter != null ? Colors.white : Colors.grey.shade600),
                      dropdownColor: Colors.white,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tất cả Khoa', style: TextStyle(fontSize: 12))),
                        ..._departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 12, color: _deptFilter == d ? _purple : Colors.black)))),
                      ],
                      onChanged: (v) => setState(() { _deptFilter = v; _currentPage = 1; }),
                      selectedItemBuilder: (_) => [
                        const DropdownMenuItem(value: null, child: Text('Khoa', style: TextStyle(fontSize: 12, color: Colors.grey))),
                        ..._departments.map((d) => DropdownMenuItem(value: d, child: Text(d, style: TextStyle(fontSize: 12, color: Colors.white)))),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _statusChip('Tất cả', null, 'Tất cả'),
                    _statusChip('Open', const Color(0xFF3B82F6), 'Chưa xử lý'),
                    _statusChip('Pending', const Color(0xFFF59E0B), 'Đang thực hiện'),
                    _statusChip('Resolved', const Color(0xFF10B981), 'Hoàn thành'),
                    _statusChip('Cancelled', const Color(0xFF64748B), 'Từ chối'),
                  ]),
                ),
              ),
            ]),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 8),
          child: Text(
            '${filtered.length} kết quả',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _purple))
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildListWithPagination(filtered),
        ),
      ],
    );
  }

  Widget _statusChip(String value, Color? color, String displayLabel) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() { _filterStatus = value; _currentPage = 1; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? (color ?? _purple).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? (color ?? _purple).withValues(alpha: 0.4) : Colors.grey.shade200),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (color != null) ...[
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
            ],
            Text(displayLabel, style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? (color ?? _purple) : Colors.grey.shade600,
            )),
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
        final isReopen = t.ticketType == 'reopen_medical';
        final cardColor = isReopen ? const Color.fromARGB(255, 148, 182, 234) : _purple;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedTicket = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? cardColor.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? cardColor.withValues(alpha: 0.5) : Colors.grey.shade100, width: isSelected ? 1.5 : 1),
              boxShadow: [
                if (isSelected) BoxShadow(color: cardColor.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))
                else BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1)),
              ],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 4, height: 40, decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: cardColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text(isReopen ? '#BA-${t.ticketId.toString().padLeft(4, '0')}' : '#GY-${t.ticketId.toString().padLeft(4, '0')}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: cardColor, fontSize: 11)),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time_rounded, size: 11, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Text(_formatTime(t.createdAt), style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
                ]),
                const SizedBox(height: 6),
                Text(t.subject, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1E293B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),

                if (isReopen && t.description.isNotEmpty) ...[
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

                if (isReopen) ...[
                  Builder(builder: (context) {
                    final desc = t.description;
                    final isFinance = desc.toLowerCase().contains('ảnh hưởng tài chính: có');
                    if (!isFinance) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(children: [
                        const Icon(Icons.monetization_on_rounded, size: 12, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 4),
                        Text('Có ảnh hưởng tài chính', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                      ]),
                    );
                  }),
                ],

                Row(children: [
                  Icon(Icons.person_outline, size: 13, color: Colors.grey.shade400),
                  const SizedBox(width: 3),
                  Expanded(child: Text('${t.requesterName ?? ''} - ${t.requesterDeptName ?? ""}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), overflow: TextOverflow.ellipsis)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: _statusColor(t.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(_statusLabel(t), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _statusColor(t.status))),
                  ),
                ]),
              ])),
            ]),
          ),
        );
      },
    );
  }

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
                  tooltip: 'Đóng',
                  onPressed: () => setState(() => _selectedTicket = null),
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
              key: ValueKey('detail_mgr_${_selectedTicket!.ticketId}_${_selectedTicket!.status}'),
              ticketId: _selectedTicket!.ticketId,
              ticket: _selectedTicket,
              currentUser: widget.currentUser,
              isAdmin: false,
              isEmbedded: true,
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Không có yêu cầu nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
      ]),
    );
  }
}
