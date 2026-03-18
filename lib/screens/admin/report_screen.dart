import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/ticket_repository.dart';
import '../../models/ticket.dart';
import '../../models/user.dart';

class ReportScreen extends StatefulWidget {
  final User currentUser;
  const ReportScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  final _repo = TicketRepository.instance;
  List<Ticket> _tickets = [];
  bool _loading = true;
  late TabController _tabController;
  // Index: 0=Ngày, 1=Tháng, 2=Quý, 3=Năm
  int _periodIndex = 1;

  static const _periodLabels = ['Theo ngày', 'Theo tháng', 'Theo quý', 'Theo năm'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() { if (!_tabController.indexIsChanging) setState(() => _periodIndex = _tabController.index); });
    _loadData();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _loadData() async {
    final tickets = await _repo.getAllTickets();
    if (mounted) setState(() { _tickets = tickets; _loading = false; });
  }

  // ── AGGREGATION ────────────────────────────────────────────────────────────
  Map<String, _PeriodData> _aggregate() {
    final Map<String, _PeriodData> map = {};
    for (final t in _tickets) {
      final key = _keyFor(t.createdAt);
      map.putIfAbsent(key, () => _PeriodData(key));
      map[key]!.total++;
      if (t.status == 'Open') map[key]!.open++;
      if (t.status == 'Pending') map[key]!.pending++;
      if (t.status == 'Resolved') map[key]!.resolved++;
    }
    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sorted);
  }

  String _keyFor(DateTime dt) {
    switch (_periodIndex) {
      case 0: return '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
      case 1: return '${dt.year}-${dt.month.toString().padLeft(2,'0')}';
      case 2: return '${dt.year}-Q${((dt.month - 1) ~/ 3) + 1}';
      case 3: return '${dt.year}';
      default: return '${dt.year}';
    }
  }

  String _shortLabel(String key) {
    switch (_periodIndex) {
      case 0: // day: 2026-03-12 → 12/3
        final parts = key.split('-'); return '${parts[2]}/${parts[1]}';
      case 1: // month: 2026-03 → Th3/26
        final p = key.split('-'); return 'Th${int.parse(p[1])}\n${p[0].substring(2)}';
      case 2: return key.split('-').last; // Q1, Q2...
      case 3: return key; // 2026
      default: return key;
    }
  }
  // ── CHART COLORS ──────────────────────────────────────────────────────────
  static const _colorOpen    = Color(0xFFE53935);
  static const _colorPending = Color(0xFFFB8C00);
  static const _colorResolved= Color(0xFF43A047);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text('Báo cáo thống kê', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: _periodLabels.map((l) => Tab(text: l)).toList(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF3949AB)))
          : TabBarView(
              controller: _tabController,
              children: List.generate(4, (_) => _buildChartBody()),
            ),
    );
  }

  Widget _buildChartBody() {
    final data = _aggregate();
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu', style: TextStyle(color: Colors.grey)));
    }
    final periods = data.values.toList();
    final maxY = periods.map((p) => p.total.toDouble()).reduce((a, b) => a > b ? a : b);

    final total = _tickets.length;
    final open = _tickets.where((t) => t.status == 'Open').length;
    final pending = _tickets.where((t) => t.status == 'Pending').length;
    final resolved = _tickets.where((t) => t.status == 'Resolved').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // ── Summary cards ──
        Row(children: [
          _kpiCard('Tổng cộng', '$total', Icons.confirmation_number_outlined, const Color(0xFF3949AB)),
          const SizedBox(width: 10),
          _kpiCard('Đang mở', '$open', Icons.error_outline, _colorOpen),
          const SizedBox(width: 10),
          _kpiCard('Chờ xử lý', '$pending', Icons.hourglass_empty, _colorPending),
          const SizedBox(width: 10),
          _kpiCard('Đã xong', '$resolved', Icons.check_circle_outline, _colorResolved),
        ]),
        const SizedBox(height: 16),

        // ── Bar chart card ──
        _chartCard(
          title: 'Số lượng yêu cầu — ${_periodLabels[_periodIndex]}',
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                maxY: (maxY + 1).ceilToDouble(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1,
                      getTitlesWidget: (v, _) => v % 1 == 0 ? Text('${v.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey[500])) : const SizedBox())),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(
                    showTitles: true, reservedSize: 36,
                    getTitlesWidget: (v, meta) {
                      final i = v.toInt();
                      if (i < 0 || i >= periods.length) return const SizedBox();
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(_shortLabel(periods[i].label), style: TextStyle(fontSize: 9, color: Colors.grey[600]), textAlign: TextAlign.center),
                      );
                    },
                  )),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: List.generate(periods.length, (i) {
                  final p = periods[i];
                  return BarChartGroupData(x: i, barRods: [
                    BarChartRodData(toY: p.open.toDouble(), color: _colorOpen, width: 8, borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(toY: p.pending.toDouble(), color: _colorPending, width: 8, borderRadius: BorderRadius.circular(4)),
                    BarChartRodData(toY: p.resolved.toDouble(), color: _colorResolved, width: 8, borderRadius: BorderRadius.circular(4)),
                  ], barsSpace: 2);
                }),
                barTouchData: BarTouchData(enabled: true),
              ),
            ),
          ),
          legend: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _legend('Đang mở', _colorOpen),
            const SizedBox(width: 16),
            _legend('Chờ xử lý', _colorPending),
            const SizedBox(width: 16),
            _legend('Đã xong', _colorResolved),
          ]),
        ),
        const SizedBox(height: 14),

        // ── Line chart (total trend) ──
        _chartCard(
          title: 'Xu hướng tổng yêu cầu',
          child: SizedBox(
            height: 200,
            child: LineChart(LineChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
                drawVerticalLine: false,
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1,
                    getTitlesWidget: (v, _) => v % 1 == 0 ? Text('${v.toInt()}', style: TextStyle(fontSize: 10, color: Colors.grey[500])) : const SizedBox())),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 36,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 || i >= periods.length) return const SizedBox();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(_shortLabel(periods[i].label), style: TextStyle(fontSize: 9, color: Colors.grey[600]), textAlign: TextAlign.center),
                    );
                  },
                )),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(periods.length, (i) => FlSpot(i.toDouble(), periods[i].total.toDouble())),
                  isCurved: true, color: const Color(0xFF3949AB), barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: Color(0x143949AB)),
                ),
              ],
            )),
          ),
        ),
        const SizedBox(height: 14),

        // ── Pie chart ──
        _chartCard(
          title: 'Tỉ lệ trạng thái',
          child: SizedBox(
            height: 200,
            child: Row(children: [
              Expanded(child: PieChart(PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 40,
                sections: [
                  if (open > 0) PieChartSectionData(value: open.toDouble(), color: _colorOpen, title: '$open', radius: 55,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (pending > 0) PieChartSectionData(value: pending.toDouble(), color: _colorPending, title: '$pending', radius: 55,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  if (resolved > 0) PieChartSectionData(value: resolved.toDouble(), color: _colorResolved, title: '$resolved', radius: 55,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ))),
              const SizedBox(width: 16),
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _pieLegend('Đang mở', '$open', _colorOpen),
                const SizedBox(height: 10),
                _pieLegend('Chờ xử lý', '$pending', _colorPending),
                const SizedBox(height: 10),
                _pieLegend('Đã xong', '$resolved', _colorResolved),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 30),
      ]),
    );
  }

  Widget _chartCard({required String title, required Widget child, Widget? legend}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
        const SizedBox(height: 16),
        child,
        if (legend != null) ...[ const SizedBox(height: 12), legend ],
      ]),
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[500]), textAlign: TextAlign.center),
      ]),
    ));
  }

  Widget _legend(String label, Color color) => Row(children: [
    Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
  ]);

  Widget _pieLegend(String label, String count, Color color) => Row(children: [
    Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 8),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
      Text(count, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
    ]),
  ]);
}

class _PeriodData {
  final String label;
  int total = 0, open = 0, pending = 0, resolved = 0;
  _PeriodData(this.label);
}
