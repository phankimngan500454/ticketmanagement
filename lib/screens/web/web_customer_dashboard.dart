import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';
import 'web_customer_sidebar.dart';
import '../../app_router.dart' show TicketDetailWrapper;

class WebCustomerDashboard extends StatefulWidget {
  final User currentUser;
  const WebCustomerDashboard({super.key, required this.currentUser});

  @override
  State<WebCustomerDashboard> createState() => _WebCustomerDashboardState();
}

class _WebCustomerDashboardState extends State<WebCustomerDashboard> {
  String?
  _selectedType; // null = Tất cả, 'ticket', 'reopen_medical', 'feedback'
  final _repo = TicketRepository.instance;
  List<Ticket> _tickets = [];
  bool _loading = true;
  String _filterStatus = 'Tất cả';
  String _searchQuery = '';
  Ticket? _selectedTicket;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadData(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final tickets = await _repo.getTicketsByRequester(
        widget.currentUser.userId,
      );
      if (mounted) {
        setState(() {
          _tickets = List<Ticket>.from(tickets)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          // Thêm logic cập nhật _selectedTicket nếu nó vừa bị thay đổi trạng thái
          if (_selectedTicket != null) {
            try {
              _selectedTicket = _tickets.firstWhere(
                (t) => t.ticketId == _selectedTicket!.ticketId,
              );
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

  static const _blue = Color(0xFF1976D2);
  static const _typeColors = {
    'ticket': Color(0xFF1976D2),
    'feedback': Color(0xFF00897B),
    'reopen_medical': Color.fromARGB(255, 148, 182, 234),
  };
  static const _typeLabels = {
    'ticket': 'Yêu cầu IT',
    'feedback': 'Góp ý',
    'reopen_medical': 'Mở lại BA',
  };
  static const _typeIcons = {
    'ticket': Icons.computer_rounded,
    'feedback': Icons.feedback_rounded,
    'reopen_medical': Icons.folder_open_rounded,
  };
  static const _typePrefixes = {
    'ticket': 'TKT',
    'feedback': 'GY',
    'reopen_medical': 'BA',
  };

  Color _statusColor(String s) {
    switch (s) {
      case 'Open':
        return const Color(0xFF3B82F6);
      case 'Pending':
        return const Color(0xFFF59E0B);
      case 'WaitingConfirmation':
        return const Color(0xFF8B5CF6);
      case 'Resolved':
        return const Color(0xFF10B981);
      case 'Cancelled':
        return const Color(0xFF64748B);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String s, String? type) {
    if (type == 'reopen_medical') {
      switch (s) {
        case 'Open':
          return 'Chờ duyệt';
        case 'Resolved':
          return 'Đã duyệt';
        case 'Pending':
          return 'Đang mở BA';
        case 'WaitingConfirmation':
          return 'Chờ đóng BA';
        case 'Cancelled':
          return 'Đã đóng BA';
        default:
          return s;
      }
    }
    switch (s) {
      case 'Open':
        return 'Đang mở';
      case 'Pending':
        return 'Đang xử lý';
      case 'WaitingConfirmation':
        return 'Chờ xác nhận';
      case 'Resolved':
        return 'Hoàn thành';
      case 'Cancelled':
        return 'Đã hủy';
      default:
        return s;
    }
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'High':
        return const Color(0xFFE53935);
      case 'Medium':
        return const Color(0xFFFB8C00);
      case 'Low':
        return const Color(0xFF43A047);
      default:
        return Colors.grey;
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
    if (_selectedType != null) {
      list = list.where((t) => t.ticketType == _selectedType).toList();
    }
    if (_filterStatus != 'Tất cả') {
      if (_filterStatus == 'Open') {
        list = list
            .where(
              (t) =>
                  t.status == 'Open' ||
                  t.status == 'Pending' ||
                  t.status == 'WaitingConfirmation' ||
                  (t.ticketType == 'reopen_medical' && t.status == 'Resolved'),
            )
            .toList();
      } else if (_filterStatus == 'Resolved') {
        list = list
            .where(
              (t) =>
                  (t.ticketType != 'reopen_medical' &&
                      t.status == 'Resolved') ||
                  (t.ticketType == 'reopen_medical' && t.status == 'Cancelled'),
            )
            .toList();
      } else if (_filterStatus == 'Cancelled') {
        list = list
            .where(
              (t) =>
                  t.status == 'Cancelled' && t.ticketType != 'reopen_medical',
            )
            .toList();
      }
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (t) =>
                t.subject.toLowerCase().contains(q) ||
                t.ticketId.toString().contains(q),
          )
          .toList();
    }
    return list;
  }

  int _countByStatusCategory(String category) {
    var list = _selectedType == null
        ? _tickets
        : _tickets.where((t) => t.ticketType == _selectedType);
    if (category == 'Open') {
      return list
          .where(
            (t) =>
                t.status == 'Open' ||
                t.status == 'Pending' ||
                t.status == 'WaitingConfirmation' ||
                (t.ticketType == 'reopen_medical' && t.status == 'Resolved'),
          )
          .length;
    } else if (category == 'Resolved') {
      return list
          .where(
            (t) =>
                (t.ticketType != 'reopen_medical' && t.status == 'Resolved') ||
                (t.ticketType == 'reopen_medical' && t.status == 'Cancelled'),
          )
          .length;
    } else if (category == 'Cancelled') {
      return list
          .where(
            (t) => t.status == 'Cancelled' && t.ticketType != 'reopen_medical',
          )
          .length;
    }
    return list.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          WebCustomerSidebar(
            currentUser: widget.currentUser,
            selectedType: _selectedType,
            onTypeSelected: (type) {
              setState(() {
                _selectedType = type;
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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _selectedType == null
                          ? 'Khám phá Dịch vụ'
                          : _typeLabels[_selectedType]!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildRefreshButton(),
                      const SizedBox(width: 12),
                      _buildCreateButton(),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  SizedBox(
                    width: 220,
                    height: 36,
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm yêu cầu...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 18,
                          color: Colors.grey.shade400,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 12,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF2563EB),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _statusChip('Tất cả', null, 'Tất cả'),
                          _statusChip(
                            'Open',
                            const Color(0xFF3B82F6),
                            'Đang xử lý',
                          ),
                          _statusChip(
                            'Resolved',
                            const Color(0xFF10B981),
                            'Đã xong',
                          ),
                          if (_selectedType != 'reopen_medical')
                            _statusChip(
                              'Cancelled',
                              const Color(0xFF64748B),
                              'Đã hủy',
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 8),
          child: Text(
            '${filtered.length} kết quả',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _blue))
              : filtered.isEmpty
              ? _buildEmptyState()
              : _buildList(filtered),
        ),
      ],
    );
  }

  Widget _statusChip(String value, Color? color, String displayLabel) {
    final isSelected = _filterStatus == value;
    final count = _countByStatusCategory(value);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _filterStatus = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? const Color(0xFF2563EB)).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? (color ?? const Color(0xFF2563EB)).withValues(alpha: 0.4)
                  : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (color != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                displayLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? (color ?? const Color(0xFF2563EB))
                      : Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ),
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
        final prefix = _typePrefixes[t.ticketType] ?? 'TKT';
        final typeLabel = _typeLabels[t.ticketType] ?? 'Yêu cầu';
        final typeIcon = _typeIcons[t.ticketType] ?? Icons.confirmation_number;
        final statusColor = _statusColor(t.status);

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _selectedTicket = t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? typeColor.withValues(alpha: 0.04)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? typeColor.withValues(alpha: 0.5)
                    : Colors.grey.shade100,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: typeColor.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(typeIcon, size: 11, color: typeColor),
                          const SizedBox(width: 3),
                          Text(
                            typeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: typeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#$prefix-${t.ticketId.toString().padLeft(4, '0')}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _statusLabel(t.status, t.ticketType),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  t.subject,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                if (t.ticketType == 'reopen_medical' &&
                    t.description.isNotEmpty) ...[
                  Builder(
                    builder: (context) {
                      final desc = t.description;
                      final idx = desc.indexOf('Lý do mở lại:');
                      final reason = idx != -1
                          ? desc
                                .substring(idx + 13)
                                .trim()
                                .replaceAll('\n', ' ')
                          : desc.trim().replaceAll('\n', ' ');
                      return reason.isNotEmpty
                          ? Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Lý do: $reason',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          : const SizedBox();
                    },
                  ),
                ],

                Row(
                  children: [
                    if (t.requesterId != widget.currentUser.userId) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_pin_rounded,
                              size: 10,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              t.requesterName ?? 'Viết bởi người khác',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.amber.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (t.ticketType == 'ticket') ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _priorityColor(t.priority),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        t.priority,
                        style: TextStyle(
                          fontSize: 10,
                          color: _priorityColor(t.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _relativeTime(t.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                ),
              ],
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (_typeColors[_selectedTicket!.ticketType] ??
                                Colors.grey)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _typeIcons[_selectedTicket!.ticketType] ??
                            Icons.confirmation_number,
                        size: 13,
                        color:
                            _typeColors[_selectedTicket!.ticketType] ??
                            Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '#${_typePrefixes[_selectedTicket!.ticketType] ?? 'TKT'}-${_selectedTicket!.ticketId.toString().padLeft(4, '0')}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color:
                              _typeColors[_selectedTicket!.ticketType] ??
                              Colors.grey,
                        ),
                      ),
                    ],
                  ),
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
              key: ValueKey(
                'detail_${_selectedTicket!.ticketId}_${_selectedTicket!.ticketType}',
              ),
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
          child: Icon(
            Icons.refresh_rounded,
            size: 20,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    final bgColor = _selectedType == 'reopen_medical'
        ? const Color(0xFF1E3A8A) // Dark Royal Blue
        : const Color(0xFF2563EB);

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text(
        'Tạo mới',
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      onPressed: () => context.push('/create-ticket'),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Không có yêu cầu nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Nhấn nút "Tạo mới" để gửi yêu cầu đầu tiên của bạn',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
