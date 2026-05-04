import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';

class ReportScreen extends StatefulWidget {
  final User currentUser;
  const ReportScreen({super.key, required this.currentUser});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  final _repo = TicketRepository.instance;
  List<Ticket> _tickets = [];
  bool _loading = true;
  late TabController _tabController;
  final List<int> _periodPerTab = [1, 1, 1];

  static const _periodLabels = ['Theo ngày', 'Theo tháng', 'Theo quý', 'Theo năm'];
  static const _tabTypes  = ['ticket', 'reopen_medical', 'feedback'];
  static const _tabLabels = ['Yêu cầu IT', 'Mở lại bệnh án', 'Góp ý'];
  static const _tabIcons  = [
    Icons.build_circle_rounded,
    Icons.folder_open_rounded,
    Icons.rate_review_rounded,
  ];
  static const _tabColors = [
    Color(0xFF3949AB),
    Color(0xFF5C6BC0),
    Color(0xFF00897B),
  ];

  // Status colors
  static const _colorOpen      = Color(0xFF3B82F6);
  static const _colorPending   = Color(0xFFF59E0B);
  static const _colorWaiting   = Color(0xFFE67E22);
  static const _colorResolved  = Color(0xFF10B981);
  static const _colorCancelled = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) { setState(() {}); }
    });
    _loadData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final tickets = await _repo.getAllTickets();
    if (mounted) { setState(() { _tickets = tickets; _loading = false; }); }
  }

  List<Ticket> _ticketsForType(String type) =>
      _tickets.where((t) => t.ticketType == type).toList();

  // ── Aggregation ─────────────────────────────────────────────────
  Map<String, _PeriodData> _aggregate(List<Ticket> tickets, int pi) {
    final Map<String, _PeriodData> map = {};
    for (final t in tickets) {
      final key = _keyFor(t.createdAt, pi);
      map.putIfAbsent(key, () => _PeriodData(key));
      final d = map[key]!;
      d.total++;
      if (t.status == 'Open') { d.open++; }
      if (t.status == 'Pending') { d.pending++; }
      if (t.status == 'WaitingConfirmation') { d.waiting++; }
      if (t.status == 'Resolved') { d.resolved++; }
      if (t.status == 'Cancelled') { d.cancelled++; }
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sorted);
  }

  String _keyFor(DateTime dt, int pi) {
    switch (pi) {
      case 0: return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      case 1: return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      case 2: return '${dt.year}-Q${((dt.month - 1) ~/ 3) + 1}';
      case 3: return '${dt.year}';
      default: return '${dt.year}';
    }
  }

  String _shortLabel(String key, int pi) {
    switch (pi) {
      case 0: final p = key.split('-'); return '${p[2]}/${p[1]}';
      case 1: final p = key.split('-'); return 'Th${int.parse(p[1])}/${p[0].substring(2)}';
      case 2: return key.split('-').last;
      case 3: return key;
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _buildMainContent(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──────────────────────────────────────────────
        _buildHeader(),
        // ── Body ────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF3949AB)))
              : TabBarView(
                  controller: _tabController,
                  children: List.generate(3, (i) {
                    final tickets = _ticketsForType(_tabTypes[i]);
                    return _buildTabBody(i, tickets);
                  }),
                ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 28, 0),
          child: Row(
            children: [
              Material(
                borderRadius: BorderRadius.circular(8),
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      context.go('/admin');
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.arrow_back_rounded, size: 22, color: Color(0xFF3949AB)),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.analytics_rounded, size: 24, color: Color(0xFF3949AB)),
              const SizedBox(width: 10),
              const Text(
                'Báo cáo & Thống kê',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF1E293B)),
              ),
              const Spacer(),
              // Total summary
              _headerStat('Tổng', '${_tickets.length}', const Color(0xFF3949AB)),
              const SizedBox(width: 10),
              _headerStat('Đang xử lý', '${_tickets.where((t) => t.status == 'Open' || t.status == 'Pending').length}', _colorPending),
              const SizedBox(width: 10),
              _headerStat('Hoàn thành', '${_tickets.where((t) => t.status == 'Resolved').length}', _colorResolved),
              const SizedBox(width: 16),
              // Refresh
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Tab bar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 28),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.label,
            indicatorWeight: 3,
            indicatorColor: _tabColors[_tabController.index],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            labelColor: _tabColors[_tabController.index],
            unselectedLabelColor: Colors.grey.shade500,
            dividerHeight: 0,
            tabs: List.generate(3, (i) {
              final count = _ticketsForType(_tabTypes[i]).length;
              return Tab(
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(_tabIcons[i], size: 16),
                  const SizedBox(width: 6),
                  Text(_tabLabels[i]),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: (_tabController.index == i ? _tabColors[i] : Colors.grey.shade400).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$count', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold,
                      color: _tabController.index == i ? _tabColors[i] : Colors.grey.shade500,
                    )),
                  ),
                ]),
              );
            }),
          ),
        ),
      ]),
    );
  }

  Widget _headerStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── Tab body ────────────────────────────────────────────────────
  Widget _buildTabBody(int tabIdx, List<Ticket> tickets) {
    final periodIndex = _periodPerTab[tabIdx];
    final tabColor = _tabColors[tabIdx];
    final data = _aggregate(tickets, periodIndex);

    final total     = tickets.length;
    final open      = tickets.where((t) => t.status == 'Open').length;
    final pending   = tickets.where((t) => t.status == 'Pending').length;
    final waiting   = tickets.where((t) => t.status == 'WaitingConfirmation').length;
    final resolved  = tickets.where((t) => t.status == 'Resolved').length;
    final cancelled = tickets.where((t) => t.status == 'Cancelled').length;

    if (total == 0) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(_tabIcons[tabIdx], size: 48, color: Colors.grey.shade300),
          ),
          const SizedBox(height: 16),
          Text('Chưa có dữ liệu ${_tabLabels[tabIdx]}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('Dữ liệu sẽ hiển thị khi có yêu cầu mới',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Period selector ──
        _buildPeriodSelector(tabIdx, tabColor),
        const SizedBox(height: 20),

        // ── KPI cards row ──
        _buildKpiRow(total, open, pending, waiting, resolved, cancelled, tabColor),
        const SizedBox(height: 20),

        // ── Charts row: Bar + Pie side by side on wide screens ──
        LayoutBuilder(builder: (ctx, constraints) {
          if (constraints.maxWidth > 800) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildBarChartCard(data, periodIndex, tabColor)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildPieChartCard(total, open, pending, waiting, resolved, cancelled)),
              ],
            );
          }
          return Column(children: [
            _buildBarChartCard(data, periodIndex, tabColor),
            const SizedBox(height: 16),
            _buildPieChartCard(total, open, pending, waiting, resolved, cancelled),
          ]);
        }),
        const SizedBox(height: 16),

        // ── Line chart full width ──
        if (data.isNotEmpty)
          _buildLineChartCard(data, periodIndex, tabColor),

        const SizedBox(height: 30),
      ]),
    );
  }

  // ── Period selector ─────────────────────────────────────────────
  Widget _buildPeriodSelector(int tabIdx, Color tabColor) {
    return Row(children: List.generate(4, (i) {
      final selected = _periodPerTab[tabIdx] == i;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _periodPerTab[tabIdx] = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? tabColor.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? tabColor.withValues(alpha: 0.4) : Colors.grey.shade200,
                width: selected ? 1.5 : 1,
              ),
              boxShadow: selected
                  ? [BoxShadow(color: tabColor.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))]
                  : null,
            ),
            child: Text(_periodLabels[i], style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? tabColor : Colors.grey.shade600,
            )),
          ),
        ),
      );
    }));
  }

  // ── KPI row ─────────────────────────────────────────────────────
  Widget _buildKpiRow(int total, int open, int pending, int waiting, int resolved, int cancelled, Color tabColor) {
    return Row(children: [
      Expanded(child: _kpiCard('Tổng cộng', total, Icons.confirmation_number_outlined, tabColor)),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard('Đang mở', open, Icons.error_outline, _colorOpen)),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard('Chờ xử lý', pending, Icons.hourglass_empty, _colorPending)),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard('Chờ xác nhận', waiting, Icons.schedule_send_rounded, _colorWaiting)),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard('Hoàn thành', resolved, Icons.check_circle_outline, _colorResolved)),
      const SizedBox(width: 12),
      Expanded(child: _kpiCard('Đã hủy', cancelled, Icons.cancel_outlined, _colorCancelled)),
    ]);
  }

  Widget _kpiCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text('$value', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
        ])),
      ]),
    );
  }

  // ── Bar chart card ──────────────────────────────────────────────
  Widget _buildBarChartCard(Map<String, _PeriodData> data, int pi, Color accent) {
    if (data.isEmpty) { return const SizedBox(); }
    final periods = data.values.toList();
    final maxY = periods.map((p) => p.total.toDouble()).reduce((a, b) => a > b ? a : b);

    return _chartCard(
      title: 'Số lượng theo trạng thái',
      subtitle: _periodLabels[pi],
      accent: accent,
      child: SizedBox(
        height: 260,
        child: BarChart(
          BarChartData(
            maxY: (maxY + 1).ceilToDouble(),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true, horizontalInterval: 1,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
              drawVerticalLine: false,
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1,
                  getTitlesWidget: (v, _) => v % 1 == 0 ? Text('${v.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey[400])) : const SizedBox())),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 32,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= periods.length) { return const SizedBox(); }
                  return SideTitleWidget(meta: meta,
                    child: Text(_shortLabel(periods[i].label, pi), style: TextStyle(fontSize: 9, color: Colors.grey[500]), textAlign: TextAlign.center));
                },
              )),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            barGroups: List.generate(periods.length, (i) {
              final p = periods[i];
              return BarChartGroupData(x: i, barRods: [
                BarChartRodData(toY: p.open.toDouble(), color: _colorOpen, width: 6, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: p.pending.toDouble(), color: _colorPending, width: 6, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: p.waiting.toDouble(), color: _colorWaiting, width: 6, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: p.resolved.toDouble(), color: _colorResolved, width: 6, borderRadius: BorderRadius.circular(3)),
                BarChartRodData(toY: p.cancelled.toDouble(), color: _colorCancelled, width: 6, borderRadius: BorderRadius.circular(3)),
              ], barsSpace: 2);
            }),
            barTouchData: BarTouchData(enabled: true),
          ),
        ),
      ),
      legend: Wrap(spacing: 16, runSpacing: 6, children: [
        _legend('Đang mở', _colorOpen),
        _legend('Chờ xử lý', _colorPending),
        _legend('Chờ xác nhận', _colorWaiting),
        _legend('Hoàn thành', _colorResolved),
        _legend('Đã hủy', _colorCancelled),
      ]),
    );
  }

  // ── Pie chart card ──────────────────────────────────────────────
  Widget _buildPieChartCard(int total, int open, int pending, int waiting, int resolved, int cancelled) {
    return _chartCard(
      title: 'Tỉ lệ trạng thái',
      child: Column(children: [
        SizedBox(
          height: 200,
          child: PieChart(PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 40,
            sections: [
              if (open > 0) PieChartSectionData(value: open.toDouble(), color: _colorOpen, title: '${(open * 100 / total).round()}%', radius: 50,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              if (pending > 0) PieChartSectionData(value: pending.toDouble(), color: _colorPending, title: '${(pending * 100 / total).round()}%', radius: 50,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              if (waiting > 0) PieChartSectionData(value: waiting.toDouble(), color: _colorWaiting, title: '${(waiting * 100 / total).round()}%', radius: 50,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              if (resolved > 0) PieChartSectionData(value: resolved.toDouble(), color: _colorResolved, title: '${(resolved * 100 / total).round()}%', radius: 50,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              if (cancelled > 0) PieChartSectionData(value: cancelled.toDouble(), color: _colorCancelled, title: '${(cancelled * 100 / total).round()}%', radius: 50,
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          )),
        ),
        const SizedBox(height: 16),
        Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 8, children: [
          _pieLegendCompact('Đang mở', open, _colorOpen),
          _pieLegendCompact('Chờ xử lý', pending, _colorPending),
          _pieLegendCompact('Chờ xác nhận', waiting, _colorWaiting),
          _pieLegendCompact('Hoàn thành', resolved, _colorResolved),
          _pieLegendCompact('Đã hủy', cancelled, _colorCancelled),
        ]),
      ]),
    );
  }

  // ── Line chart card ─────────────────────────────────────────────
  Widget _buildLineChartCard(Map<String, _PeriodData> data, int pi, Color accent) {
    final periods = data.values.toList();
    return _chartCard(
      title: 'Xu hướng tổng yêu cầu',
      subtitle: _periodLabels[pi],
      accent: accent,
      child: SizedBox(
        height: 200,
        child: LineChart(LineChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true, horizontalInterval: 1,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1,
                getTitlesWidget: (v, _) => v % 1 == 0 ? Text('${v.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey[400])) : const SizedBox())),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 32,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= periods.length) { return const SizedBox(); }
                return SideTitleWidget(meta: meta,
                  child: Text(_shortLabel(periods[i].label, pi), style: TextStyle(fontSize: 9, color: Colors.grey[500]), textAlign: TextAlign.center));
              },
            )),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(periods.length, (i) => FlSpot(i.toDouble(), periods[i].total.toDouble())),
              isCurved: true, color: accent, barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: accent.withValues(alpha: 0.06)),
            ),
          ],
        )),
      ),
    );
  }

  // ── Shared chart card ───────────────────────────────────────────
  Widget _chartCard({required String title, required Widget child, String? subtitle, Color? accent, Widget? legend}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (accent != null) ...[
            Container(width: 4, height: 18, decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
          ],
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          if (subtitle != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(subtitle, style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            ),
          ],
        ]),
        const SizedBox(height: 20),
        child,
        if (legend != null) ...[const SizedBox(height: 14), legend],
      ]),
    );
  }

  Widget _legend(String label, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
  ]);

  Widget _pieLegendCompact(String label, int count, Color color) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 5),
    Text('$label ($count)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
  ]);
}

class _PeriodData {
  final String label;
  int total = 0, open = 0, pending = 0, waiting = 0, resolved = 0, cancelled = 0;
  _PeriodData(this.label);
}
