import 'package:flutter/material.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import '../shared/ticket_detail_screen.dart';

class ITWorkloadScreen extends StatefulWidget {
  final User currentUser;
  const ITWorkloadScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ITWorkloadScreen> createState() => _ITWorkloadScreenState();
}

class _ITWorkloadScreenState extends State<ITWorkloadScreen> {
  final _repo = TicketRepository.instance;
  List<User> _itStaff = [];
  List<Ticket> _tickets = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();
  String _filterTab = 'all';

  static const _indigo = Color(0xFF3949AB);
  static const _darkIndigo = Color(0xFF1A237E);
  static const _green = Color(0xFF43A047);

  @override
  void initState() { super.initState(); _loadData(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final staff = await _repo.getITStaff();
    final tickets = await _repo.getAllTickets();
    if (mounted) setState(() { _itStaff = staff; _tickets = tickets; _loading = false; });
  }

  List<Ticket> _ticketsFor(int userId) => _tickets.where((t) => t.assigneeId == userId && t.status != 'Resolved').toList();
  bool _isFree(User s) => _ticketsFor(s.userId).isEmpty;

  List<User> get _filteredStaff {
    final q = _searchQuery.toLowerCase().trim();
    Iterable<User> base = _itStaff;
    if (_filterTab == 'busy') base = base.where((s) => !_isFree(s));
    if (_filterTab == 'free') base = base.where((s) => _isFree(s));
    if (q.isNotEmpty) base = base.where((s) => s.fullName.toLowerCase().contains(q));
    return base.toList();
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

  Color _priorityColor(String? p) {
    switch (p) {
      case 'High': return const Color(0xFFE53935);
      case 'Medium': return const Color(0xFFFB8C00);
      default: return const Color(0xFF29B6F6);
    }
  }

  @override
  Widget build(BuildContext context) {
    final freeCount = _itStaff.where(_isFree).length;
    final busyCount = _itStaff.length - freeCount;
    final totalActive = _tickets.where((t) => t.status != 'Resolved').length;
    final shown = _filteredStaff;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [_darkIndigo, _indigo], begin: Alignment.topLeft, end: Alignment.bottomRight)),
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
                const Expanded(child: Text('Theo dõi IT', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                IconButton(icon: const Icon(Icons.refresh_rounded, color: Colors.white), onPressed: () { setState(() => _loading = true); _loadData(); }),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: Row(children: [
                _statCard('Tất cả', '${_itStaff.length}', Icons.people_rounded, Colors.white, 'all'),
                const SizedBox(width: 8),
                _statCard('Đang bận', '$busyCount', Icons.work_rounded, const Color(0xFFFFCC80), 'busy'),
                const SizedBox(width: 8),
                _statCard('Trống', '$freeCount', Icons.check_circle_outline_rounded, const Color(0xFFA5D6A7), 'free'),
                const SizedBox(width: 8),
                _statCard('Đang xử lý', '$totalActive', Icons.confirmation_number_outlined, const Color(0xFF90CAF9), null),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C2E)),
                decoration: InputDecoration(
                  hintText: 'Tìm nhân viên IT...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.white54),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.white54),
                  suffixIcon: _searchQuery.isNotEmpty ? GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }, child: const Icon(Icons.close, size: 16, color: Colors.white54)) : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.5))),
                ),
              ),
            ),
          ])),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _indigo))
              : shown.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
                      const SizedBox(height: 12),
                      Text(_searchQuery.isNotEmpty ? 'Không tìm thấy kết quả' : 'Không có nhân viên', style: TextStyle(fontSize: 15, color: Colors.grey[500])),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: _indigo,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: shown.length,
                        itemBuilder: (_, i) => _buildStaffCard(shown[i]),
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _buildStaffCard(User staff) {
    final activeTickets = _ticketsFor(staff.userId);
    final isFree = activeTickets.isEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isFree ? _green.withOpacity(0.35) : _indigo.withOpacity(0.15), width: isFree ? 1.5 : 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(children: [
            CircleAvatar(radius: 20, backgroundColor: isFree ? _green.withOpacity(0.12) : _indigo.withOpacity(0.12),
                child: Text(staff.fullName[0], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isFree ? _green : _indigo))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(staff.fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: isFree ? _green.withOpacity(0.12) : _indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(isFree ? '✓ Trống' : '${activeTickets.length} việc', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isFree ? _green : _indigo)),
                ),
              ]),
              const SizedBox(height: 2),
              Text(staff.deptName ?? 'IT', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ])),
          ]),
        ),
        if (isFree)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: _green.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.sentiment_satisfied_alt_rounded, size: 16, color: _green),
                SizedBox(width: 6),
                Text('Sẵn sàng nhận ticket mới', style: TextStyle(fontSize: 12, color: _green, fontWeight: FontWeight.w500)),
              ]),
            ),
          )
        else ...[
          const Divider(height: 1),
          ...activeTickets.map((t) => _buildTicketRow(t)),
          const SizedBox(height: 4),
        ],
      ]),
    );
  }

  Widget _buildTicketRow(Ticket t) {
    final sc = _statusColor(t.status);
    final pc = _priorityColor(t.priority);
    return InkWell(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => TicketDetailScreen(ticket: t, isAdmin: true, currentUser: widget.currentUser)));
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(border: Border(left: BorderSide(color: pc, width: 3))),
        child: Row(children: [
          Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 10), decoration: BoxDecoration(color: pc, shape: BoxShape.circle)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('#TKT-${t.ticketId.toString().padLeft(4, '0')}  ${t.subject}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (t.categoryName != null) Text(t.categoryName!, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ])),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: sc.withOpacity(0.4))),
            child: Text(_statusLabel(t.status), style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: sc)),
          ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, String? filterKey) {
    final selected = filterKey != null && _filterTab == filterKey;
    return Expanded(child: GestureDetector(
      onTap: filterKey == null ? null : () => setState(() => _filterTab = selected ? 'all' : filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.30) : Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? Colors.white.withOpacity(0.9) : Colors.white.withOpacity(0.2), width: selected ? 2 : 1),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 1),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.white70), textAlign: TextAlign.center),
          if (selected) ...[const SizedBox(height: 3), Container(width: 16, height: 2, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(1)))],
        ]),
      ),
    ));
  }
}
