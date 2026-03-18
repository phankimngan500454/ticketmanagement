import 'package:flutter/material.dart';
import '../../data/ticket_repository.dart';
import '../../models/asset.dart';
import '../../models/category.dart';
import '../../models/user.dart';

class AdminAssetsScreen extends StatefulWidget {
  final User currentUser;
  const AdminAssetsScreen({Key? key, required this.currentUser}) : super(key: key);

  @override
  State<AdminAssetsScreen> createState() => _AdminAssetsScreenState();
}

class _AdminAssetsScreenState extends State<AdminAssetsScreen> {
  final _repo = TicketRepository.instance;
  List<Asset> _assets = [];
  List<Category> _categories = [];
  bool _loading = true;
  String _searchQuery = '';
  String? _groupFilter;
  final _searchCtrl = TextEditingController();

  static const _blue = Color(0xFF3949AB);

  // ── Cấu trúc phân cấp ────────────────────────────────────
  static const Map<String, Map<String, dynamic>> _groups = {
    'Phần cứng': {
      'icon': Icons.memory_rounded,
      'color': Color(0xFF1976D2),
      'types': [
        {'label': 'Laptop', 'icon': Icons.laptop_rounded},
        {'label': 'Máy tính để bàn', 'icon': Icons.desktop_windows_rounded},
        {'label': 'Màn hình', 'icon': Icons.monitor_rounded},
        {'label': 'Máy in', 'icon': Icons.print_rounded},
        {'label': 'Cáp / Dây', 'icon': Icons.cable_rounded},
        {'label': 'Bàn phím & Chuột', 'icon': Icons.keyboard_rounded},
        {'label': 'Điện thoại / Tablet', 'icon': Icons.smartphone_rounded},
        {'label': 'Khác', 'icon': Icons.devices_other_rounded},
      ],
    },
    'Phần mềm': {
      'icon': Icons.apps_rounded,
      'color': Color(0xFFF57C00),
      'types': [
        {'label': 'Bản quyền phần mềm', 'icon': Icons.verified_rounded},
        {'label': 'Hệ điều hành', 'icon': Icons.computer_rounded},
        {'label': 'Phần mềm quản lý', 'icon': Icons.manage_accounts_rounded},
        {'label': 'Phần mềm diệt virus', 'icon': Icons.security_rounded},
        {'label': 'Khác', 'icon': Icons.extension_rounded},
      ],
    },
    'Mạng': {
      'icon': Icons.router_rounded,
      'color': Color(0xFF00897B),
      'types': [
        {'label': 'Router', 'icon': Icons.router_rounded},
        {'label': 'Switch', 'icon': Icons.device_hub_rounded},
        {'label': 'Wifi AP', 'icon': Icons.wifi_rounded},
        {'label': 'Cáp mạng', 'icon': Icons.cable_rounded},
        {'label': 'Firewall', 'icon': Icons.shield_rounded},
        {'label': 'Khác', 'icon': Icons.devices_other_rounded},
      ],
    },
  };

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([_repo.getAssets(), _repo.getCategories()]);
    if (mounted) setState(() {
      _assets = results[0] as List<Asset>;
      _categories = results[1] as List<Category>;
      _loading = false;
    });
  }

  List<Asset> get _filtered {
    var list = _assets;
    if (_groupFilter != null) list = list.where((a) => a.assetGroup == _groupFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((a) =>
        a.assetName.toLowerCase().contains(q) ||
        a.assetCode.toLowerCase().contains(q) ||
        a.assetModel.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Color _groupColor(String group) => (_groups[group]?['color'] as Color?) ?? Colors.grey;
  IconData _groupIcon(String group) => (_groups[group]?['icon'] as IconData?) ?? Icons.devices_rounded;
  List<Map<String, dynamic>> _typesForGroup(String group) =>
    List<Map<String, dynamic>>.from((_groups[group]?['types'] as List?) ?? []);

  IconData _typeIcon(String group, String type) {
    final types = _typesForGroup(group);
    return types.firstWhere((t) => t['label'] == type,
      orElse: () => {'icon': Icons.devices_other_rounded})['icon'] as IconData;
  }

  String _categoryName(int? id) {
    if (id == null) return '';
    return _categories.firstWhere((c) => c.categoryId == id,
      orElse: () => Category(categoryId: 0, categoryName: '')).categoryName;
  }

  // ── Add / Edit Sheet ─────────────────────────────────────
  void _showAssetSheet({Asset? existing}) {
    final nameCtrl = TextEditingController(text: existing?.assetName ?? '');
    final codeCtrl = TextEditingController(text: existing?.assetCode ?? '');
    final modelCtrl = TextEditingController(text: existing?.assetModel ?? '');
    String selectedGroup = existing?.assetGroup ?? 'Phần cứng';
    String selectedType = existing?.assetType ?? 'Laptop';
    int? selectedCategoryId = existing?.categoryId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        final types = _typesForGroup(selectedGroup);
        // Ensure selected type is valid for the group
        if (!types.any((t) => t['label'] == selectedType)) {
          selectedType = types.first['label'] as String;
        }

        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: SingleChildScrollView(child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(existing == null ? 'Thêm thiết bị / phần mềm' : 'Sửa thông tin',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // ── Bước 1: chọn nhóm lớn ─────
              Text('1. Nhóm', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: _groups.entries.map((e) {
                final sel = selectedGroup == e.key;
                final color = e.value['color'] as Color;
                return Expanded(child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setS(() {
                      selectedGroup = e.key;
                      selectedType = (_typesForGroup(e.key).first['label'] as String);
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? color : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? color : Colors.transparent, width: 1.5),
                      ),
                      child: Column(children: [
                        Icon(e.value['icon'] as IconData, size: 18, color: sel ? Colors.white : Colors.grey[600]),
                        const SizedBox(height: 3),
                        Text(e.key, textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: sel ? Colors.white : Colors.grey[600])),
                      ]),
                    ),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 12),

              // ── Bước 2: chọn loại cụ thể ──
              Text('2. Loại thiết bị', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(spacing: 7, runSpacing: 7, children: types.map((t) {
                final sel = selectedType == t['label'];
                final color = _groupColor(selectedGroup);
                return GestureDetector(
                  onTap: () => setS(() => selectedType = t['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: sel ? color : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: sel ? color : Colors.transparent, width: 1.5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(t['icon'] as IconData, size: 13, color: sel ? Colors.white : Colors.grey[600]),
                      const SizedBox(width: 5),
                      Text(t['label'] as String,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : Colors.grey[600])),
                    ]),
                  ),
                );
              }).toList()),
              const SizedBox(height: 12),

              // ── Model ──────────────────────
              Text('3. Thông tin chi tiết', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _inputField(nameCtrl, 'Tên thiết bị / phần mềm', Icons.label_rounded),
              const SizedBox(height: 8),
              _inputField(modelCtrl, 'Model (VD: Dell XPS 15, HP LaserJet Pro...)', Icons.info_outline_rounded),
              const SizedBox(height: 8),
              _inputField(codeCtrl, 'Mã / Số serial', Icons.qr_code_2_rounded),
              const SizedBox(height: 12),

              // ── Danh mục liên quan ─────────
              if (_categories.isNotEmpty) ...[
                Text('4. Danh mục liên quan (tuỳ chọn)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int?>(
                  value: selectedCategoryId,
                  decoration: InputDecoration(
                    filled: true, fillColor: const Color(0xFFF4F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    prefixIcon: const Icon(Icons.category_outlined, size: 18),
                    isDense: true,
                  ),
                  hint: const Text('Không liên kết'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— Không liên kết —')),
                    ..._categories.map((c) => DropdownMenuItem(value: c.categoryId, child: Text(c.categoryName))),
                  ],
                  onChanged: (v) => setS(() => selectedCategoryId = v),
                ),
                const SizedBox(height: 12),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: Icon(existing == null ? Icons.add_rounded : Icons.save_rounded, size: 17),
                  label: Text(existing == null ? 'Thêm thiết bị' : 'Lưu thay đổi',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    Navigator.pop(ctx);
                    try {
                      final asset = Asset(
                        assetId: existing?.assetId ?? 0,
                        assetName: name,
                        assetCode: codeCtrl.text.trim(),
                        assetGroup: selectedGroup,
                        assetType: selectedType,
                        assetModel: modelCtrl.text.trim(),
                        status: 'Active',
                        categoryId: selectedCategoryId,
                      );
                      await _repo.upsertAsset(asset);
                      _load();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(existing == null ? '✅ Đã thêm "$name"' : '✅ Đã cập nhật thiết bị'),
                        backgroundColor: const Color(0xFF43A047), behavior: SnackBarBehavior.floating));
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red));
                    }
                  },
                ),
              ),
            ],
          )),
        );
      }),
    );
  }

  Future<void> _deleteAsset(Asset asset) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá thiết bị?'),
        content: Text('Bạn có chắc muốn xoá "${asset.assetName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteAsset(asset.assetId);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('🗑️ Đã xoá thiết bị'),
        backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('❌ Lỗi: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _inputField(TextEditingController ctrl, String label, IconData icon) => TextField(
    controller: ctrl,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 17, color: Colors.grey[500]),
      filled: true, fillColor: const Color(0xFFF4F5F9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _blue, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    // Group by assetGroup for section headers
    final grouped = <String, List<Asset>>{};
    for (final a in list) {
      grouped.putIfAbsent(a.assetGroup, () => []).add(a);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // ── Header ──────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1A237E), Color(0xFF3949AB)]),
          ),
          child: SafeArea(bottom: false, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context)),
                const Expanded(child: Text('Quản lý Thiết bị',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                Text('${_assets.length} mục',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
              ]),
            ),
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm tên, model, mã serial...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                        child: Icon(Icons.close, color: Colors.white.withOpacity(0.7), size: 16))
                    : null,
                  filled: true, fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8), isDense: true,
                ),
              ),
            ),
            // Group filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(children: [
                _chip('Tất cả', null),
                ..._groups.keys.map((g) => _chip(g, g)),
              ]),
            ),
          ])),
        ),

        // ── List ───────────────────────────────────────
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : list.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Container(padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: _blue.withOpacity(0.07), shape: BoxShape.circle),
                      child: Icon(Icons.devices_outlined, size: 52, color: _blue.withOpacity(0.4))),
                    const SizedBox(height: 14),
                    Text('Chưa có thiết bị nào', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                  ]))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    children: grouped.entries.expand((entry) {
                      final groupColor = _groupColor(entry.key);
                      final groupIcon = _groupIcon(entry.key);
                      return [
                        // Section header
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 6),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: groupColor.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                              child: Icon(groupIcon, size: 16, color: groupColor)),
                            const SizedBox(width: 8),
                            Text(entry.key, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: groupColor)),
                            const SizedBox(width: 6),
                            Text('(${entry.value.length})', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                          ]),
                        ),
                        ...entry.value.map((a) => _buildAssetCard(a)),
                      ];
                    }).toList(),
                  )),
      ]),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAssetSheet(),
        backgroundColor: _blue, foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm mới', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  Widget _chip(String label, String? value) {
    final selected = _groupFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _groupFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? _blue : Colors.white)),
        ),
      ),
    );
  }

  Widget _buildAssetCard(Asset asset) {
    final groupColor = _groupColor(asset.assetGroup);
    final typeIcon = _typeIcon(asset.assetGroup, asset.assetType);
    final catName = _categoryName(asset.categoryId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: groupColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(typeIcon, size: 21, color: groupColor),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(asset.assetName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF1C1C2E))),
            if (asset.assetModel.isNotEmpty)
              Text(asset.assetModel, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            const SizedBox(height: 4),
            Wrap(spacing: 5, children: [
              _badge(asset.assetType, groupColor),
              if (catName.isNotEmpty)
                _badge('📁 $catName', _blue.withOpacity(0.7)),
              if (asset.assetCode.isNotEmpty)
                _badge(asset.assetCode, Colors.grey.shade500),
            ]),
          ])),
          Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(icon: const Icon(Icons.edit_rounded, size: 17, color: _blue),
              onPressed: () => _showAssetSheet(existing: asset)),
            IconButton(icon: const Icon(Icons.delete_outline, size: 17, color: Colors.redAccent),
              onPressed: () => _deleteAsset(asset)),
          ]),
        ]),
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
  );
}
