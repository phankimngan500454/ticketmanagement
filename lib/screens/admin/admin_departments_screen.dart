import 'package:flutter/material.dart';
import '../../data/ticket_repository.dart';
import '../../models/department.dart';
import '../../models/user.dart';

class AdminDepartmentsScreen extends StatefulWidget {
  final User currentUser;
  const AdminDepartmentsScreen({super.key, required this.currentUser});

  @override
  State<AdminDepartmentsScreen> createState() => _AdminDepartmentsScreenState();
}

class _AdminDepartmentsScreenState extends State<AdminDepartmentsScreen> {
  final _repo = TicketRepository.instance;
  List<Department> _departments = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _indigo = Color(0xFF3949AB);
  static const _indigoDark = Color(0xFF1A237E);

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
      final depts = await _repo.getDepartments();
      if (mounted) {
        setState(() {
          _departments = depts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Không tải được dữ liệu: $e');
      }
    }
  }

  List<Department> get _filtered {
    final q = _searchQuery.toLowerCase().trim();
    if (q.isEmpty) return _departments;
    return _departments
        .where((d) => d.deptName.toLowerCase().contains(q))
        .toList();
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating),
      );

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(msg),
            backgroundColor: const Color(0xFF43A047),
            behavior: SnackBarBehavior.floating),
      );

  // ── Dialog thêm / sửa ─────────────────────────────────────────────
  Future<void> _showUpsertDialog({Department? existing}) async {
    final nameCtrl =
        TextEditingController(text: existing?.deptName ?? '');
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
            decoration: BoxDecoration(
              color: _indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.business_rounded, color: _indigo, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            existing == null ? 'Thêm phòng ban' : 'Sửa phòng ban',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
        ]),
        content: Form(
          key: formKey,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(height: 4),
            TextFormField(
              controller: nameCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Tên phòng ban',
                hintText: 'Nhập tên phòng ban...',
                prefixIcon: const Icon(Icons.corporate_fare_rounded,
                    color: _indigo, size: 18),
                filled: true,
                fillColor: const Color(0xFFF4F5FF),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: _indigo, width: 1.5)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent)),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Vui lòng nhập tên phòng ban' : null,
            ),
          ]),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Hủy'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            icon: const Icon(Icons.save_rounded, size: 16),
            label: const Text('Lưu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final dept = Department(
          deptId: existing?.deptId ?? 0,
          deptName: nameCtrl.text.trim(),
        );
        await _repo.upsertDepartment(dept);
        _showSuccess(
            existing == null ? '✅ Đã thêm phòng ban' : '✅ Đã cập nhật');
        _load();
      } catch (e) {
        _showError('❌ Lỗi: $e');
      }
    }
  }

  // ── Xác nhận xóa ──────────────────────────────────────────────────
  Future<void> _confirmDelete(Department dept) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa phòng ban',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E)),
            children: [
              const TextSpan(text: 'Bạn có chắc muốn xóa phòng ban '),
              TextSpan(
                  text: '"${dept.deptName}"',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const TextSpan(
                  text: '?\n\nLưu ý: nhân viên thuộc phòng ban này sẽ không bị xóa.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repo.deleteDepartment(dept.deptId);
        _showSuccess('🗑️ Đã xóa "${dept.deptName}"');
        _load();
      } catch (e) {
        _showError('❌ Lỗi khi xóa: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // ── Header ─────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_indigoDark, _indigo],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Quản lý Phòng Ban',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      '${_departments.length} phòng ban',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ]),
              ),
              // Search bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Tìm phòng ban...',
                    hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Colors.white.withValues(alpha: 0.7), size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: Icon(Icons.close,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7)))
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.15),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.5)),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ]),
          ),
        ),

        // ── Body ────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _indigo))
              : filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                                color: _indigo.withValues(alpha: 0.08),
                                shape: BoxShape.circle),
                            child: Icon(Icons.business_center_outlined,
                                size: 56,
                                color: _indigo.withValues(alpha: 0.4)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'Không tìm thấy kết quả'
                                : 'Chưa có phòng ban nào',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          if (_searchQuery.isEmpty)
                            ElevatedButton.icon(
                              onPressed: _showUpsertDialog,
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm phòng ban đầu tiên'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _indigo,
                                  foregroundColor: Colors.white),
                            ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: _indigo,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) => _deptCard(filtered[i]),
                      ),
                    ),
        ),
      ]),

      // ── FAB ──────────────────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showUpsertDialog,
        backgroundColor: _indigo,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm phòng ban',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _deptCard(Department dept) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
        child: Row(children: [
          // Icon avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_indigoDark, _indigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                dept.deptName.isNotEmpty
                    ? dept.deptName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + id badge
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dept.deptName,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1C1C2E)),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _indigo.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ID: ${dept.deptId}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _indigo),
                    ),
                  ),
                ]),
          ),
          // Action buttons
          IconButton(
            icon: const Icon(Icons.edit_outlined,
                size: 20, color: _indigo),
            tooltip: 'Sửa',
            onPressed: () => _showUpsertDialog(existing: dept),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 20, color: Color(0xFFE53935)),
            tooltip: 'Xóa',
            onPressed: () => _confirmDelete(dept),
          ),
        ]),
      ),
    );
  }
}
