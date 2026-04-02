import 'package:flutter/material.dart';
import '../../data/ticket_repository.dart';
import '../../models/category.dart';
import '../../models/user.dart';

class AdminCategoriesScreen extends StatefulWidget {
  final User currentUser;
  const AdminCategoriesScreen({super.key, required this.currentUser});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  final _repo = TicketRepository.instance;
  List<Category> _categories = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _purple = Color(0xFF7B1FA2);
  static const _purpleDark = Color(0xFF4A148C);

  // Màu sắc xoay vòng cho mỗi danh mục
  static const _colors = [
    Color(0xFF7B1FA2), Color(0xFF1976D2), Color(0xFF00897B),
    Color(0xFFE53935), Color(0xFFF57C00), Color(0xFF303F9F),
  ];

  Color _colorFor(int index) => _colors[index % _colors.length];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final cats = await _repo.getCategories();
      if (mounted) setState(() { _categories = cats; _loading = false; });
    } catch (e) {
      if (mounted) { setState(() => _loading = false); _showError('Đã xảy ra lỗi, vui lòng thử lại!'); }
    }
  }

  List<Category> get _filtered {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _categories;
    return _categories.where((c) => c.categoryName.toLowerCase().contains(q)).toList();
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFF43A047), behavior: SnackBarBehavior.floating));

  Future<void> _showUpsertDialog({Category? existing}) async {
    final nameCtrl = TextEditingController(text: existing?.categoryName ?? '');
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _purple.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.category_rounded, color: _purple, size: 20),
          ),
          const SizedBox(width: 10),
          Text(existing == null ? 'Thêm danh mục' : 'Sửa danh mục',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ]),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const SizedBox(height: 4),
              TextFormField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Tên danh mục',
                  hintText: 'Ví dụ: Lỗi phần cứng...',
                  prefixIcon: const Icon(Icons.label_rounded, color: _purple, size: 18),
                  filled: true,
                  fillColor: const Color(0xFFF9F4FD),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _purple, width: 1.5)),
                  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.redAccent)),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên danh mục' : null,
              ),
            ]),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(ctx, true); },
            icon: const Icon(Icons.save_rounded, size: 16),
            label: const Text('Lưu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _purple, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final cat = Category(
          categoryId: existing?.categoryId ?? 0,
          categoryName: nameCtrl.text.trim(),
        );
        await _repo.upsertCategory(cat);
        _showSuccess(existing == null ? '✅ Đã thêm danh mục' : '✅ Đã cập nhật');
        _load();
      } catch (e) { _showError('❌ Đã xảy ra lỗi, vui lòng thử lại!'); }
    }
  }

  Future<void> _confirmDelete(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa danh mục', style: TextStyle(fontWeight: FontWeight.bold)),
        content: RichText(text: TextSpan(
          style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E)),
          children: [
            const TextSpan(text: 'Bạn có chắc muốn xóa danh mục '),
            TextSpan(text: '"${cat.categoryName}"', style: const TextStyle(fontWeight: FontWeight.bold)),
            const TextSpan(text: '?\n\nLưu ý: ticket thuộc danh mục này sẽ không bị xóa.'),
          ],
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.deleteCategory(cat.categoryId);
        _showSuccess('🗑️ Đã xóa "${cat.categoryName}"');
        _load();
      } catch (e) { _showError('❌ Đã xảy ra lỗi, vui lòng thử lại!'); }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FA),
      body: Column(children: [
        // ── Header ──────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [_purpleDark, _purple],
            ),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(child: Text('Quản lý Danh Mục',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                  child: Text('${_categories.length} danh mục',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm danh mục...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                          child: Icon(Icons.close, size: 16, color: Colors.white.withValues(alpha: 0.7)))
                      : null,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.6), width: 1.5)),
                ),
              ),
            ),
          ])),
        ),

        // ── Body ────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _purple))
              : filtered.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(color: _purple.withValues(alpha: 0.08), shape: BoxShape.circle),
                        child: Icon(Icons.category_outlined, size: 56, color: _purple.withValues(alpha: 0.4)),
                      ),
                      const SizedBox(height: 16),
                      Text(_searchQuery.isNotEmpty ? 'Không tìm thấy kết quả' : 'Chưa có danh mục nào',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      if (_searchQuery.isEmpty)
                        ElevatedButton.icon(
                          onPressed: _showUpsertDialog,
                          icon: const Icon(Icons.add),
                          label: const Text('Thêm danh mục đầu tiên'),
                          style: ElevatedButton.styleFrom(backgroundColor: _purple, foregroundColor: Colors.white),
                        ),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load, color: _purple,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _catCard(filtered[i], i),
                      ),
                    ),
        ),
      ]),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUpsertDialog,
        backgroundColor: _purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm danh mục', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _catCard(Category cat, int index) {
    final color = _colorFor(index);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.category_rounded, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(cat.categoryName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: Text('ID: ${cat.categoryId}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
            ),
          ])),
          IconButton(
            icon: Icon(Icons.edit_outlined, size: 20, color: color),
            tooltip: 'Sửa',
            onPressed: () => _showUpsertDialog(existing: cat),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE53935)),
            tooltip: 'Xóa',
            onPressed: () => _confirmDelete(cat),
          ),
        ]),
      ),
    );
  }
}
