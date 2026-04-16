import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/ticket_repository.dart';
import '../../models/asset.dart';
import '../../models/category.dart';
import '../../models/user.dart';

class AdminAssetsScreen extends StatefulWidget {
  final User currentUser;
  const AdminAssetsScreen({super.key, required this.currentUser});
  @override
  State<AdminAssetsScreen> createState() => _AdminAssetsScreenState();
}

class _AdminAssetsScreenState extends State<AdminAssetsScreen> {
  final _repo = TicketRepository.instance;
  List<Asset>    _assets     = [];
  List<Category> _categories = [];
  bool   _loading     = true;
  String _searchQuery = '';
  int?   _catFilter;
  final  _searchCtrl  = TextEditingController();

  static const _blue     = Color(0xFF3949AB);
  static const _blueDark = Color(0xFF1A237E);

  static const List<Map<String, dynamic>> _allTypes = [
    {'label': 'Laptop',               'icon': Icons.laptop_rounded},
    {'label': 'Máy tính để bàn',     'icon': Icons.desktop_windows_rounded},
    {'label': 'Màn hình',            'icon': Icons.monitor_rounded},
    {'label': 'Máy in',              'icon': Icons.print_rounded},
    {'label': 'Bàn phím & Chuột',    'icon': Icons.keyboard_rounded},
    {'label': 'Điện thoại / Tablet', 'icon': Icons.smartphone_rounded},
    {'label': 'Router',              'icon': Icons.router_rounded},
    {'label': 'Switch',              'icon': Icons.device_hub_rounded},
    {'label': 'Wifi AP',             'icon': Icons.wifi_rounded},
    {'label': 'Cáp mạng',           'icon': Icons.cable_rounded},
    {'label': 'Firewall',            'icon': Icons.shield_rounded},
    {'label': 'Bản quyền phần mềm', 'icon': Icons.verified_rounded},
    {'label': 'Hệ điều hành',       'icon': Icons.computer_rounded},
    {'label': 'Phần mềm quản lý',   'icon': Icons.manage_accounts_rounded},
    {'label': 'Phần mềm diệt virus','icon': Icons.security_rounded},
    {'label': 'Khác',               'icon': Icons.devices_other_rounded},
  ];

  /// Trả về danh sách loại thiết bị phù hợp với tên danh mục
  static List<Map<String, dynamic>> _typesForCategory(String? catName) {
    if (catName == null) return _allTypes;
    final n = catName.toLowerCase();
    if (n.contains('phần cứng') || n.contains('phan cung') || n.contains('hardware')) {
      return _allTypes.where((t) => [
        'Laptop','Máy tính để bàn','Màn hình','Máy in',
        'Bàn phím & Chuột','Điện thoại / Tablet','Khác',
      ].contains(t['label'])).toList();
    }
    if (n.contains('mạng') || n.contains('network') || n.contains('mang')) {
      return _allTypes.where((t) => [
        'Router','Switch','Wifi AP','Cáp mạng','Firewall','Khác',
      ].contains(t['label'])).toList();
    }
    if (n.contains('phần mềm') || n.contains('software') || n.contains('phan mem')) {
      return _allTypes.where((t) => [
        'Bản quyền phần mềm','Hệ điều hành','Phần mềm quản lý','Phần mềm diệt virus','Khác',
      ].contains(t['label'])).toList();
    }
    return _allTypes; // Khác / không xác định → hiện tất cả
  }

  static const _accentColors = [
    Color(0xFF3949AB), Color(0xFF00897B), Color(0xFF1976D2),
    Color(0xFFF57C00), Color(0xFF7B1FA2), Color(0xFFE53935),
  ];
  Color _accentFor(int i) => _accentColors[i % _accentColors.length];

  // ── Lifecycle ─────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final r = await Future.wait([_repo.getAssets(), _repo.getCategories()]);
    if (mounted) {
      final seenA = <int>{};
      final seenC = <int>{};
      setState(() {
        _assets     = (r[0] as List<Asset>).where((a) => seenA.add(a.assetId)).toList();
        _categories = (r[1] as List<Category>).where((c) => seenC.add(c.categoryId)).toList();
        _loading    = false;
      });
    }
  }

  // ── Helpers ───────────────────────────────────────────────
  List<Asset> get _filtered {
    var list = _assets;
    if (_catFilter != null) list = list.where((a) => a.categoryId == _catFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) =>
        a.assetName.toLowerCase().contains(q) ||
        a.assetCode.toLowerCase().contains(q) ||
        a.assetModel.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  String _categoryName(int? id) {
    if (id == null) return '';
    return _categories.firstWhere((c) => c.categoryId == id,
        orElse: () => Category(categoryId: 0, categoryName: '')).categoryName;
  }

  IconData _typeIcon(String type) => (_allTypes
      .firstWhere((t) => t['label'] == type,
          orElse: () => {'icon': Icons.devices_other_rounded})['icon'] as IconData);

  // ── Delete ────────────────────────────────────────────────
  Future<void> _deleteAsset(Asset asset) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa thiết bị?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa\n"${asset.assetName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa')),
        ],
      ),
    );
    if (ok == true) {
      await _repo.deleteAsset(asset.assetId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🗑️ Đã xóa "${asset.assetName}"'),
          backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
      }
    }
  }

  // ── Add / Edit Sheet ──────────────────────────────────────
  void _showAssetSheet({Asset? existing}) {
    final nameCtrl  = TextEditingController(text: existing?.assetName ?? '');
    final codeCtrl  = TextEditingController(text: existing?.assetCode ?? '');
    final modelCtrl = TextEditingController(text: existing?.assetModel ?? '');
    String selectedType       = existing?.assetType.isNotEmpty == true ? existing!.assetType : 'Laptop';
    int?   selectedCategoryId = existing?.categoryId;
    // Lấy tên danh mục hiện tại để filter loại thiết bị
    String? selectedCatName = selectedCategoryId == null
        ? null
        : _categories.firstWhere((c) => c.categoryId == selectedCategoryId,
            orElse: () => Category(categoryId: 0, categoryName: '')).categoryName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Shortcuts(
        // Chặn Ctrl+Z/Y gây AssertionError trên Flutter Windows
        shortcuts: {
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
              const DoNothingAndStopPropagationIntent(),
          LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
              const DoNothingAndStopPropagationIntent(),
        },
        child: StatefulBuilder(
        builder: (ctx, setS) => Container(
          height: MediaQuery.of(ctx).size.height * 0.90,
          decoration: const BoxDecoration(
            color: Color(0xFFF7F8FC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // ── Title bar ──────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 6)],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)))),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(color: _blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(existing == null ? Icons.add_rounded : Icons.edit_rounded, size: 20, color: _blue),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(existing == null ? 'Thêm thiết bị mới' : 'Chỉnh sửa thiết bị',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
                    Text('Điền đầy đủ thông tin bên dưới',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ]),
                ]),
              ]),
            ),

            // ── Scrollable form ────────────────────────────
            Expanded(child: ListView(
              padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(ctx).viewInsets.bottom + 24),
              children: [
                // 1. Danh mục
                _label('1. Danh mục', Icons.category_rounded),
                const SizedBox(height: 8),
                _card(child: DropdownButtonFormField<int?>(
                  initialValue: selectedCategoryId,
                  decoration: InputDecoration(
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _blue, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    prefixIcon: const Icon(Icons.category_outlined, size: 18, color: _blue),
                    isDense: true,
                  ),
                  hint: Text('— Chọn danh mục —', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Không liên kết —')),
                    ..._categories.map((c) => DropdownMenuItem(
                      value: c.categoryId,
                      child: Row(children: [
                        Container(width: 8, height: 8,
                          decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(c.categoryName, style: const TextStyle(fontSize: 13)),
                      ]),
                    )),
                  ],
                  onChanged: (v) => setS(() {
                    selectedCategoryId = v;
                    selectedCatName = v == null ? null
                        : _categories.firstWhere((c) => c.categoryId == v,
                            orElse: () => Category(categoryId: 0, categoryName: '')).categoryName;
                    // Reset loại thiết bị nếu không còn trong danh sách mới
                    final newTypes = _typesForCategory(selectedCatName);
                    if (!newTypes.any((t) => t['label'] == selectedType)) {
                      selectedType = newTypes.first['label'] as String;
                    }
                  }),
                )),

                const SizedBox(height: 16),

                // 2. Loại thiết bị
                _label('2. Loại thiết bị', Icons.devices_rounded),
                if (selectedCatName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text('Hiển thị theo danh mục: "$selectedCatName"',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic)),
                  ),
                const SizedBox(height: 8),
                _card(padding: const EdgeInsets.all(12), child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _typesForCategory(selectedCatName).map((t) {
                    final sel = selectedType == t['label'];
                    return GestureDetector(
                      onTap: () => setS(() => selectedType = t['label'] as String),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _blue : const Color(0xFFF0F2FB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? _blue : Colors.transparent, width: 1.5),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(t['icon'] as IconData, size: 14,
                            color: sel ? Colors.white : const Color(0xFF666680)),
                          const SizedBox(width: 6),
                          Text(t['label'] as String,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : const Color(0xFF444466))),
                        ]),
                      ),
                    );
                  }).toList(),
                )),

                // ─────────────────────────────────────────────────────────────────
                // TODO: Model & Serial tạm ẩn (2026-04-08) — người dùng thường không biết
                // Để bật lại model/serial: bỏ comment khối bên dưới
                // ─────────────────────────────────────────────────────────────────
                const SizedBox(height: 16),
                _label('3. Tên thiết bị hoặc tên phần mềm (tùy chọn)', Icons.label_rounded),
                const SizedBox(height: 8),
                _card(padding: const EdgeInsets.all(14), child: _field(
                  nameCtrl,
                  'VD: Laptop phòng Kế toán, Máy in tầng 2...',
                  Icons.label_rounded,
                )),
                // ── Model & Serial (tạm ẩn) ──
                // const SizedBox(height: 10),
                // _field(modelCtrl, 'Model (VD: Dell XPS 15, HP LaserJet Pro...)', Icons.info_outline_rounded),
                // const SizedBox(height: 10),
                // _field(codeCtrl, 'Mã / Số serial', Icons.qr_code_2_rounded),
                // ─────────────────────────────────────────────────────────────────

                const SizedBox(height: 20),

                // Submit
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton.icon(
                    icon: Icon(existing == null ? Icons.add_rounded : Icons.save_rounded, size: 18),
                    label: Text(existing == null ? 'Thêm thiết bị' : 'Lưu thay đổi',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _blue, foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      // Nếu không nhập tên → dùng tên loại thiết bị làm mặc định
                      final name = nameCtrl.text.trim().isEmpty
                          ? selectedType
                          : nameCtrl.text.trim();
                      Navigator.pop(ctx);
                      try {
                        await _repo.upsertAsset(Asset(
                          assetId:    existing?.assetId ?? 0,
                          assetName:  name,
                          assetCode:  codeCtrl.text.trim(),
                          assetGroup: '',
                          assetType:  selectedType,
                          assetModel: modelCtrl.text.trim(),
                          status:     'Active',
                          categoryId: selectedCategoryId,
                        ));
                        _load();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(existing == null ? '✅ Đã thêm "$name"' : '✅ Đã cập nhật'),
                            backgroundColor: const Color(0xFF43A047), behavior: SnackBarBehavior.floating));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('❌ Đã xảy ra lỗi, vui lòng thử lại!'), backgroundColor: Colors.red));
                        }
                      }
                    },
                  ),
                ),
              ],
            )),
          ]),
        ),
      ),       // closes StatefulBuilder child: of Shortcuts
    ),         // closes Shortcuts
  );
}

  // ── Small helpers ─────────────────────────────────────────
  Widget _label(String text, IconData icon) => Row(children: [
    Icon(icon, size: 15, color: _blue),
    const SizedBox(width: 6),
    Text(text, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: _blue)),
  ]);

  Widget _card({required Widget child, EdgeInsets padding = EdgeInsets.zero}) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
    ),
    child: child,
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: Colors.grey[500]),
      prefixIcon: Icon(icon, size: 17, color: Colors.grey[400]),
      filled: true, fillColor: const Color(0xFFF7F8FC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _blue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
  );

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_blueDark, _blue]),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context)),
                const Expanded(child: Text('Quản lý Thiết bị',
                  style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10)),
                  child: Text('${_assets.length} thiết bị',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm tên, model, mã serial...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                          child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.7), size: 16))
                      : null,
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 9), isDense: true,
                ),
              ),
            ),
            // Category filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: Row(children: [
                _chip('Tất cả', null),
                ..._categories.map((c) => _chip(c.categoryName, c.categoryId)),
              ]),
            ),
          ])),
        ),

        // Asset list
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : list.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(color: _blue.withValues(alpha: 0.07), shape: BoxShape.circle),
                      child: Icon(Icons.devices_outlined, size: 52, color: _blue.withValues(alpha: 0.35))),
                    const SizedBox(height: 14),
                    Text(_searchQuery.isNotEmpty ? 'Không tìm thấy kết quả' : 'Chưa có thiết bị nào',
                      style: TextStyle(fontSize: 15, color: Colors.grey[500], fontWeight: FontWeight.w500)),
                  ]))
                : RefreshIndicator(
                    onRefresh: _load, color: _blue,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _buildCard(list[i], i),
                    ),
                  )),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssetSheet,
        backgroundColor: _blue, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: const Text('Thêm thiết bị', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  Widget _chip(String label, int? catId) {
    final sel = _catFilter == catId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _catFilter = catId),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: sel ? Colors.white : Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(20)),
          child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: sel ? _blue : Colors.white)),
        ),
      ),
    );
  }

  Widget _buildCard(Asset asset, int index) {
    final accent  = _accentFor(index);
    final catName = _categoryName(asset.categoryId);
    final icon    = _typeIcon(asset.assetType);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        // Accent left bar
        Container(width: 5, height: 80,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)))),
        const SizedBox(width: 12),
        // Icon
        Container(width: 44, height: 44,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 22, color: accent)),
        const SizedBox(width: 12),
        // Text info
        Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              asset.assetName == '(Chưa xác định)' || asset.assetName.isEmpty
                  ? asset.assetType
                  : asset.assetName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1C1C2E))),
            if (asset.assetModel.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(asset.assetModel, style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
            ],
            const SizedBox(height: 6),
            Wrap(spacing: 5, runSpacing: 4, children: [
              _badge(asset.assetType, accent),
              if (catName.isNotEmpty) _badge('📁 $catName', _blue),
              if (asset.assetCode.isNotEmpty) _badge('# ${asset.assetCode}', Colors.grey),
            ]),
          ]),
        )),
        // Actions
        Column(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
            icon: Icon(Icons.edit_rounded, size: 18, color: accent),
            tooltip: 'Sửa',
            onPressed: () => _showAssetSheet(existing: asset)),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFE53935)),
            tooltip: 'Xóa',
            onPressed: () => _deleteAsset(asset)),
        ]),
        const SizedBox(width: 4),
      ]),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
  );
}
