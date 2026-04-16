import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import 'web_it_sidebar.dart';
import '../../app_router.dart' show TicketDetailWrapper;

class WebITDashboard extends StatefulWidget {
  final User currentUser;
  const WebITDashboard({super.key, required this.currentUser});

  @override
  State<WebITDashboard> createState() => _WebITDashboardState();
}

class _WebITDashboardState extends State<WebITDashboard> {
  int _navIndex = 0; // 0 = Chờ nhận, 1 = Việc của tôi, 2 = Tất cả
  final _repo = TicketRepository.instance;
  List<Ticket> _unassigned = [];
  List<Ticket> _myTickets = [];
  bool _loading = true;
  String _searchQuery = '';
  Ticket? _selectedTicket;
  Timer? _refreshTimer;
  int? _processingId;
  
  static const _green = Color(0xFF00897B);

  List<Ticket> get _activeTasks => _myTickets.where((t) => t.status != 'Resolved' && t.status != 'Cancelled').toList();
  List<Ticket> get _allMyTickets => _myTickets;

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
      final results = await Future.wait([
        _repo.getUnassignedTickets(),
        _repo.getTicketsByAssignee(widget.currentUser.userId),
      ]);
      if (mounted) {
        setState(() {
          _unassigned = List<Ticket>.from(results[0])..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _myTickets = List<Ticket>.from(results[1])..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (_selectedTicket != null) {
            try {
               final allVisible = [..._unassigned, ..._myTickets];
               _selectedTicket = allVisible.firstWhere((t) => t.ticketId == _selectedTicket!.ticketId);
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

  Future<void> _acceptTicket(Ticket ticket) async {
    if (_processingId != null) return;
    setState(() => _processingId = ticket.ticketId);

    try {
      await _repo.assignTicket(ticket.ticketId, widget.currentUser.userId);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('✅ Đã nhận Ticket #${ticket.ticketId}!'),
          backgroundColor: _green, behavior: SnackBarBehavior.floating,
        ));
        setState(() {
            _navIndex = 1;
            _selectedTicket = _myTickets.firstWhere((t) => t.ticketId == ticket.ticketId, orElse: () => ticket);
        });
      }
    } catch (e) {
      // ignore
    } finally {
      if (mounted) setState(() => _processingId = null);
    }
  }

  Future<void> _completeTicket(Ticket ticket) async {
    await _repo.updateStatus(ticket.ticketId, 'WaitingConfirmation');
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('📬 Đã gửi xác nhận (Ticket #${ticket.ticketId})'),
        backgroundColor: const Color(0xFFF59E0B), behavior: SnackBarBehavior.floating,
      ));
    }
  }

  List<Ticket> get _filtered {
    List<Ticket> base = _navIndex == 0 ? _unassigned : _navIndex == 1 ? _activeTasks : _allMyTickets;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      base = base.where((t) =>
        t.subject.toLowerCase().contains(q) ||
        (t.requesterName ?? '').toLowerCase().contains(q) ||
        t.ticketId.toString().contains(q)
      ).toList();
    }
    return base;
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
      case 'Medium': return 'TB';
      default: return 'Thấp';
    }
  }

  DateTime _slaDeadline(Ticket t) {
    final hours = t.priority == 'High' ? 4 : t.priority == 'Medium' ? 24 : 72;
    return t.createdAt.add(Duration(hours: hours));
  }

  DateTime? _effectiveDl(Ticket t) {
    if (t.status == 'Resolved' || t.status == 'Cancelled') return null;
    if (t.finalDeadline != null) return t.finalDeadline;
    return _slaDeadline(t);
  }

  String? _slaCountdown(Ticket t) {
    final dl = _effectiveDl(t);
    if (dl == null) return null;
    final diff = dl.difference(DateTime.now());
    if (diff.isNegative) {
      final abs = diff.abs();
      final h = abs.inHours;
      final m = abs.inMinutes % 60;
      return h > 0 ? 'QUÁ HẠN ${h}h${m > 0 ? ' ${m}p' : ''}' : 'QUÁ HẠN ${m}p';
    }
    if (diff.inHours <= 4) {
      final h = diff.inHours;
      final m = diff.inMinutes % 60;
      return 'SLA: ${h > 0 ? '${h}h ' : ''}${m}p';
    }
    return null;
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${dt.day}/${dt.month}';
  }

  Widget _statusBadge(String status) {
    Color c;
    String label;
    switch (status) {
      case 'Resolved': c = const Color(0xFF10B981); label = 'Đã xong'; break;
      case 'WaitingConfirmation': c = const Color(0xFF8B5CF6); label = 'Chờ xác nhận'; break;
      case 'Pending': c = const Color(0xFFF59E0B); label = 'Đang xử lý'; break;
      case 'Cancelled': c = const Color(0xFF64748B); label = 'Đã hủy'; break;
      default: c = const Color(0xFF3B82F6); label = 'Đang mở'; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          WebITSidebar(
            currentUser: widget.currentUser,
            selectedIndex: _navIndex,
            onIndexSelected: (idx) {
              setState(() {
                _navIndex = idx;
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
    final titles = ['Yêu cầu đang chờ nhận', 'Công việc của bạn', 'Tất cả công việc'];

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
                Text(
                  titles[_navIndex],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF1E293B)),
                ),
                _buildRefreshButton(),
              ],
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm người dùng, chủ đề...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _green, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('SL: ${filtered.length}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _green)),
              ),
            ]),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _green))
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : _buildList(filtered),
        ),
      ],
    );
  }

  Widget _buildList(List<Ticket> tickets) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final t = tickets[i];
        final isSelected = _selectedTicket?.ticketId == t.ticketId;
        final priorityColor = _priorityColor(t.priority);
        final isHigh = t.priority == 'High';

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedTicket = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? _green.withValues(alpha: 0.04) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? _green.withValues(alpha: 0.5) : Colors.grey.shade200,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                if (isSelected) BoxShadow(color: _green.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))
                else if (isHigh) BoxShadow(color: Colors.red.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 1))
              ],
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 4, height: 40, decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(2))),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('#TKT-${t.ticketId.toString().padLeft(4, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: _green, fontSize: 12)),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(5)),
                    child: Text(_priorityLabel(t.priority),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: priorityColor)),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 11, color: Colors.grey[400]),
                  const SizedBox(width: 2),
                  Text(_formatTime(t.createdAt), style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ]),
                const SizedBox(height: 6),
                Text(t.subject, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E)), maxLines: 1, overflow: TextOverflow.ellipsis),
                
                Builder(builder: (_) {
                  final slaText = _slaCountdown(t);
                  if (slaText == null) return const SizedBox.shrink();
                  final isOverdue = slaText.startsWith('QUÁ');
                  final color = isOverdue ? Colors.red : Colors.orange;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(isOverdue ? Icons.warning_rounded : Icons.timer_outlined, size: 11, color: color),
                      const SizedBox(width: 3),
                      Text(slaText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                    ]),
                  );
                }),
                
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.person_outline, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 3),
                  Expanded(child: Text(t.requesterName ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[600]), overflow: TextOverflow.ellipsis)),
                  _statusBadge(t.status),
                ]),
                
                if (_navIndex == 0) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _processingId == t.ticketId ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.pan_tool_alt_outlined, size: 14),
                      label: Text(_processingId == t.ticketId ? 'Đang xử lý...' : 'Nhận xử lý', style: const TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, elevation: 0),
                      onPressed: _processingId != null ? null : () => _acceptTicket(t),
                    ),
                  )
                ] else if (_navIndex == 1 && t.status == 'Pending') ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: const Text('Gửi xác nhận hoàn thành', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF43A047), foregroundColor: Colors.white, elevation: 0),
                      onPressed: () => _completeTicket(t),
                    ),
                  )
                ]
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
                  tooltip: 'Đóng chi tiết',
                  onPressed: () => setState(() => _selectedTicket = null),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.computer_rounded, size: 13, color: _green),
                    const SizedBox(width: 4),
                    Text(
                      '#TKT-${_selectedTicket!.ticketId.toString().padLeft(4, '0')}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _green),
                    ),
                  ]),
                ),
                const Spacer(),
                if (_selectedTicket!.status == 'Open') // Support receiving from detail view
                  ElevatedButton(
                    onPressed: _processingId != null ? null : () => _acceptTicket(_selectedTicket!),
                    style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
                    child: const Text('Nhận xử lý', style: TextStyle(fontSize: 12)),
                  ),
                const SizedBox(width: 8),
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
              key: ValueKey('detail_${_selectedTicket!.ticketId}'),
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
        Icon(Icons.check_circle_outline, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Không có yêu cầu nào', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        Text('Tất cả công việc đã được xử lý', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ]),
    );
  }
}
