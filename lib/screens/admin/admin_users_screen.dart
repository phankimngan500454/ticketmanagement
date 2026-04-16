import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/user.dart';
import '../../models/department.dart';

class AdminUsersScreen extends StatefulWidget {
  final User currentUser;
  const AdminUsersScreen({super.key, required this.currentUser});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _repo = TicketRepository.instance;
  List<User> _users = [];
  List<Department> _departments = [];
  bool _loading = true;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  String? _roleFilter;

  static const _accent = Color(0xFF2563EB);
  static const _roles = [
    {'label': 'Admin', 'id': 1, 'color': Color(0xFF9C27B0), 'icon': Icons.admin_panel_settings_rounded},
    {'label': 'IT', 'id': 2, 'color': Color(0xFF1976D2), 'icon': Icons.build_circle_rounded},
    {'label': 'Người dùng', 'id': 3, 'color': Color(0xFF43A047), 'icon': Icons.person_rounded},
    {'label': 'Manager', 'id': 4, 'color': Color(0xFF7B1FA2), 'icon': Icons.supervisor_account_rounded},
  ];

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
    final results = await Future.wait([
      _repo.getUsers(),
      _repo.getDepartments(),
    ]);
    if (mounted) {
      final rawDepts = results[1] as List<Department>;
      final seenDepts = <int>{};
      setState(() {
        _users = results[0] as List<User>;
        _departments = rawDepts.where((d) => seenDepts.add(d.deptId)).toList();
        _loading = false;
      });
    }
  }

  List<User> get _filtered {
    var list = _users;
    if (_roleFilter != null) list = list.where((u) => u.role == _roleFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) =>
        u.fullName.toLowerCase().contains(q) ||
        u.username.toLowerCase().contains(q) ||
        u.phone.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin': return const Color(0xFF9C27B0);
      case 'IT': return const Color(0xFF1976D2);
      case 'Manager': return const Color(0xFF7B1FA2);
      default: return const Color(0xFF43A047);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'Admin': return 'Admin';
      case 'IT': return 'IT';
      case 'Manager': return 'Manager';
      default: return 'User';
    }
  }

  int _countByRole(String? role) {
    if (role == null) return _users.length;
    return _users.where((u) => u.role == role).length;
  }

  String? _deptName(int? deptId) {
    if (deptId == null) return null;
    try {
      return _departments.firstWhere((d) => d.deptId == deptId).deptName;
    } catch (_) {
      return null;
    }
  }

  // ── Create / Edit user dialog ────────────────────────────────
  void _showUserDialog({User? existing}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    int roleId = existing != null
        ? (existing.role == 'Admin' ? 1 : existing.role == 'IT' ? 2 : existing.role == 'Manager' ? 4 : 3)
        : 3;
    int? deptId = existing?.deptId;

    final initialPerms = existing?.permissions?.split(',') ?? [];
    bool canViewInsurance = initialPerms.contains('insurance');
    bool canViewFinance = initialPerms.contains('finance');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 660),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Dialog header ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        existing == null ? Icons.person_add_rounded : Icons.edit_rounded,
                        color: _accent, size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(existing == null ? 'Tạo tài khoản mới' : 'Sửa thông tin',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                      const SizedBox(height: 2),
                      Text(existing == null ? 'Nhập thông tin để tạo tài khoản' : 'Chỉnh sửa thông tin người dùng',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ])),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ]),
                ),

                // ── Dialog body ──
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Form(key: formKey, child: Column(
                      mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

                      _dialogInputField(nameCtrl, 'Họ tên', Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null),
                      const SizedBox(height: 14),

                      if (existing == null) ...[
                        _dialogInputField(usernameCtrl, 'Tên đăng nhập', Icons.account_circle_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên đăng nhập';
                            if (v.trim().contains(' ')) return 'Không được chứa khoảng trắng';
                            return null;
                          }),
                        const SizedBox(height: 14),
                        _dialogInputField(passCtrl, 'Mật khẩu', Icons.lock_outline,
                          obscureText: true,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mật khẩu' : null),
                        const SizedBox(height: 14),
                      ],

                      // Role selector
                      Text('Vai trò', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 8,
                        children: _roles.map((r) {
                          final selected = roleId == r['id'] as int;
                          final color = r['color'] as Color;
                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setS(() => roleId = r['id'] as int),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: selected ? color.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: selected ? color.withValues(alpha: 0.5) : Colors.grey.shade200,
                                  width: selected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(r['icon'] as IconData, size: 16, color: selected ? color : Colors.grey.shade400),
                                const SizedBox(width: 6),
                                Text(r['label'] as String,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: selected ? color : Colors.grey.shade600)),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Department (searchable)
                      if (_departments.isNotEmpty && roleId != 2) ...[
                        Text('Phòng ban', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final selected = await showDialog<int?>(
                              context: ctx,
                              builder: (dialogCtx) {
                                final searchCtrl = TextEditingController();
                                return StatefulBuilder(builder: (dialogCtx, setDialog) {
                                  final query = searchCtrl.text.toLowerCase();
                                  final filtered = query.isEmpty
                                      ? _departments
                                      : _departments.where((d) => d.deptName.toLowerCase().contains(query)).toList();
                                  return AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Text('Chọn phòng ban', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      height: 350,
                                      child: Column(children: [
                                        TextField(
                                          controller: searchCtrl,
                                          onChanged: (_) => setDialog(() {}),
                                          decoration: InputDecoration(
                                            hintText: 'Tìm phòng ban...',
                                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                                            prefixIcon: Icon(Icons.search_rounded, size: 18, color: Colors.grey[400]),
                                            suffixIcon: searchCtrl.text.isNotEmpty
                                                ? GestureDetector(
                                                    onTap: () { searchCtrl.clear(); setDialog(() {}); },
                                                    child: Icon(Icons.close, size: 16, color: Colors.grey[400]))
                                                : null,
                                            filled: true, fillColor: const Color(0xFFF1F5F9),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            isDense: true,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: ListView(
                                            children: [
                                              ListTile(
                                                dense: true,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                leading: Icon(Icons.block_rounded, size: 18, color: Colors.grey[400]),
                                                title: const Text('— Không có —', style: TextStyle(fontSize: 13, color: Colors.grey)),
                                                selected: deptId == null,
                                                selectedTileColor: _accent.withValues(alpha: 0.08),
                                                onTap: () => Navigator.pop(dialogCtx, -1),
                                              ),
                                              ...filtered.map((d) => ListTile(
                                                dense: true,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                leading: Icon(Icons.apartment_rounded, size: 18, color: deptId == d.deptId ? _accent : Colors.grey[400]),
                                                title: Text(d.deptName, style: TextStyle(fontSize: 13,
                                                  fontWeight: deptId == d.deptId ? FontWeight.bold : FontWeight.normal,
                                                  color: deptId == d.deptId ? _accent : null)),
                                                selected: deptId == d.deptId,
                                                selectedTileColor: _accent.withValues(alpha: 0.08),
                                                onTap: () => Navigator.pop(dialogCtx, d.deptId),
                                              )),
                                              if (filtered.isEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(vertical: 24),
                                                  child: Center(child: Text('Không tìm thấy', style: TextStyle(fontSize: 13, color: Colors.grey[400]))),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ]),
                                    ),
                                  );
                                });
                              },
                            );
                            if (selected != null) {
                              setS(() => deptId = selected == -1 ? null : selected);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(children: [
                              Icon(Icons.apartment_rounded, size: 18, color: Colors.grey.shade500),
                              const SizedBox(width: 10),
                              Expanded(child: Text(
                                deptId != null && _departments.any((d) => d.deptId == deptId)
                                    ? _departments.firstWhere((d) => d.deptId == deptId).deptName
                                    : 'Chọn phòng ban...',
                                style: TextStyle(fontSize: 13,
                                  color: deptId != null ? const Color(0xFF1E293B) : Colors.grey.shade500),
                              )),
                              Icon(Icons.arrow_drop_down_rounded, color: Colors.grey.shade500),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Permissions
                      Text('Phân quyền giám định (Bệnh án)', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(children: [
                          CheckboxListTile(
                            title: const Text('Quyền xem Tab BẢO HIỂM', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: canViewInsurance,
                            activeColor: _accent,
                            dense: true,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                            onChanged: (v) => setS(() => canViewInsurance = v ?? false),
                          ),
                          Divider(height: 1, color: Colors.grey.shade200),
                          CheckboxListTile(
                            title: const Text('Quyền xem Tab TÀI CHÍNH', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            value: canViewFinance,
                            activeColor: _accent,
                            dense: true,
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(bottom: Radius.circular(12))),
                            onChanged: (v) => setS(() => canViewFinance = v ?? false),
                          ),
                        ]),
                      ),
                    ])),
                  ),
                ),

                // ── Dialog footer ──
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.grey.shade100)),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(flex: 2,
                      child: ElevatedButton.icon(
                        icon: Icon(existing == null ? Icons.person_add_rounded : Icons.save_rounded, size: 17),
                        label: Text(existing == null ? 'Tạo tài khoản' : 'Lưu thay đổi',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent, foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final name = nameCtrl.text.trim();
                          Navigator.pop(ctx);
                          try {
                            final finalDeptId = roleId == 2 ? null : deptId;
                            final List<String> perms = [];
                            if (canViewInsurance) perms.add('insurance');
                            if (canViewFinance) perms.add('finance');
                            final permissionsString = perms.isNotEmpty ? perms.join(',') : null;

                            if (existing == null) {
                              final username = usernameCtrl.text.trim();
                              final password = passCtrl.text.trim();
                              final result = await _repo.register(
                                username: username, password: password,
                                fullName: name,
                                roleId: roleId, deptId: finalDeptId, permissions: permissionsString,
                              );
                              if (result == null) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                    content: Text('❌ Lỗi: Tên đăng nhập này đã tồn tại!'),
                                    backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
                                }
                                return;
                              }
                            } else {
                              await _repo.updateUser(
                                userId: existing.userId, fullName: name,
                                roleId: roleId, deptId: finalDeptId, permissions: permissionsString,
                              );
                            }
                            _load();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(existing == null ? '✅ Đã tạo tài khoản $name' : '✅ Đã cập nhật thông tin'),
                                backgroundColor: const Color(0xFF43A047),
                                behavior: SnackBarBehavior.floating));
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('❌ Đã xảy ra lỗi, vui lòng thử lại!'), backgroundColor: Colors.red));
                            }
                          }
                        },
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ── Reset password dialog ────────────────────────────────────
  void _showResetPasswordDialog(User user) {
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Reset mật khẩu', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(user.fullName, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              ])),
              IconButton(
                icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
                onPressed: () => Navigator.pop(ctx),
              ),
            ]),
            const SizedBox(height: 20),
            _dialogInputField(passCtrl, 'Mật khẩu mới', Icons.lock_outline, obscureText: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mật khẩu mới' : null),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Huỷ', style: TextStyle(fontWeight: FontWeight.w600)),
              )),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_reset_rounded, size: 17),
                label: const Text('Đặt lại mật khẩu', style: TextStyle(fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final pw = passCtrl.text.trim();
                  Navigator.pop(ctx);
                  try {
                    await _repo.resetPassword(user.userId, pw);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('🔑 Đã reset mật khẩu'),
                        backgroundColor: Colors.orange, behavior: SnackBarBehavior.floating));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('❌ Đã xảy ra lỗi!'), backgroundColor: Colors.red));
                    }
                  }
                },
              )),
            ]),
          ])),
        ),
      ),
    );
  }

  // ── Delete user ──────────────────────────────────────────────
  Future<void> _deleteUser(User user) async {
    if (user.userId == widget.currentUser.userId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ Không thể xoá tài khoản đang đăng nhập'), backgroundColor: Colors.red));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xoá tài khoản?'),
        content: Text('Bạn có chắc muốn xoá tài khoản của "${user.fullName}"?\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _repo.deleteUser(user.userId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🗑️ Đã xoá tài khoản'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Đã xảy ra lỗi!'), backgroundColor: Colors.red));
      }
    }
  }

  // ── Input helper ─────────────────────────────────────────────
  Widget _dialogInputField(TextEditingController ctrl, String label, IconData icon,
      {bool obscureText = false, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        prefixIcon: Icon(icon, size: 18, color: Colors.grey.shade400),
        filled: true, fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accent, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(children: [
        // ── Top bar ──
        Container(
          padding: const EdgeInsets.fromLTRB(28, 22, 28, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Title row
            Row(children: [
              _iconButton(Icons.arrow_back_rounded, () => context.pop()),
              const SizedBox(width: 16),
              const Expanded(
                child: Text('Quản lý Người dùng',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: Color(0xFF1E293B))),
              ),
              _iconButton(Icons.refresh_rounded, _load),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent, foregroundColor: Colors.white, elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.person_add_rounded, size: 18),
                label: const Text('Thêm user', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                onPressed: () => _showUserDialog(),
              ),
            ]),
            const SizedBox(height: 18),

            // Search + filters
            Row(children: [
              SizedBox(
                width: 260,
                height: 36,
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên, username...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade400),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? GestureDetector(
                            onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                            child: Icon(Icons.close, size: 16, color: Colors.grey.shade400))
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true, fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _accent, width: 1.5)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _roleChip('Tất cả', null, null, Icons.dashboard_rounded),
                  ..._roles.map((r) => _roleChip(r['label'] as String, r['label'] as String, r['color'] as Color, r['icon'] as IconData)),
                ]),
              )),
            ]),
          ]),
        ),

        // ── Table header ──
        Container(
          margin: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            const SizedBox(width: 56), // avatar col
            Expanded(flex: 4, child: Text('NGƯỜI DÙNG', style: _colHeader)),
            Expanded(flex: 3, child: Text('PHÒNG BAN', style: _colHeader)),
            Expanded(flex: 2, child: Text('QUYỀN', style: _colHeader)),
            SizedBox(width: 120, child: Text('HÀNH ĐỘNG', style: _colHeader, textAlign: TextAlign.center)),
          ]),
        ),

        // ── List ──
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : list.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                      itemCount: list.length,
                      itemBuilder: (ctx, i) => _buildUserRow(list[i]),
                    ),
        ),

        // ── Footer ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(children: [
            Text('Tổng: ${_users.length} tài khoản', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (_roleFilter != null || _searchQuery.isNotEmpty)
              Text('Hiển thị: ${list.length} kết quả', style: TextStyle(fontSize: 12, color: _accent, fontWeight: FontWeight.w600)),
          ]),
        ),
      ]),
    );
  }

  TextStyle get _colHeader => TextStyle(
    fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500,
    letterSpacing: 0.8,
  );

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: const Color(0xFFF1F5F9),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _roleChip(String label, String? roleValue, Color? color, IconData icon) {
    final isSelected = _roleFilter == roleValue;
    final count = _countByRole(roleValue);
    final chipColor = color ?? const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _roleFilter = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? chipColor.withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? chipColor.withValues(alpha: 0.4) : Colors.grey.shade200,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: isSelected ? chipColor : Colors.grey.shade400),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(
              fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? chipColor : Colors.grey.shade600,
            )),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? chipColor.withValues(alpha: 0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text('$count', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.bold,
                color: isSelected ? chipColor : Colors.grey.shade500,
              )),
            ),
          ]),
        ),
      ),
    );
  }

  // ── User row ─────────────────────────────────────────────────
  Widget _buildUserRow(User user) {
    final roleColor = _roleColor(user.role);
    final roleLabel = _roleLabel(user.role);
    final isSelf = user.userId == widget.currentUser.userId;
    final dept = _deptName(user.deptId);

    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelf ? _accent.withValues(alpha: 0.2) : Colors.grey.shade100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _showUserDialog(existing: user),
          hoverColor: const Color(0xFFF8FAFC),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [

              // ── Avatar ──
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [roleColor.withValues(alpha: 0.15), roleColor.withValues(alpha: 0.05)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(
                  user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: roleColor),
                )),
              ),
              const SizedBox(width: 14),

              // ── Name + Username + Role badge ──
              Expanded(flex: 4, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(user.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis)),
                  if (isSelf) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(color: _accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                      child: const Text('Bạn', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: _accent)),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                    child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor)),
                  ),
                ]),
                if (user.username.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Row(children: [
                    Icon(Icons.alternate_email_rounded, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(user.username,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      overflow: TextOverflow.ellipsis),
                  ]),
                ],
              ])),

              // ── Department ──
              Expanded(flex: 3, child: dept != null
                  ? Row(children: [
                      Icon(Icons.apartment_rounded, size: 14, color: Colors.grey.shade400),
                      const SizedBox(width: 6),
                      Flexible(child: Text(dept,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        overflow: TextOverflow.ellipsis)),
                    ])
                  : Text('—', style: TextStyle(fontSize: 12, color: Colors.grey.shade300)),
              ),

              // ── Permissions ──
              Expanded(flex: 2, child: Row(children: [
                if (user.permissions?.contains('insurance') ?? false) _permBadge('Bảo hiểm', const Color(0xFF0288D1)),
                if ((user.permissions?.contains('insurance') ?? false) && (user.permissions?.contains('finance') ?? false))
                  const SizedBox(width: 4),
                if (user.permissions?.contains('finance') ?? false) _permBadge('Tài chính', const Color(0xFF7B1FA2)),
                if (user.permissions == null || user.permissions!.isEmpty)
                  Text('—', style: TextStyle(fontSize: 12, color: Colors.grey.shade300)),
              ])),

              // ── Actions ──
              SizedBox(width: 120, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _actionBtn(Icons.edit_outlined, 'Sửa', _accent, () => _showUserDialog(existing: user)),
                _actionBtn(Icons.lock_reset_rounded, 'Reset MK', Colors.orange, () => _showResetPasswordDialog(user)),
                if (!isSelf)
                  _actionBtn(Icons.delete_outline_rounded, 'Xoá', Colors.red, () => _deleteUser(user)),
              ])),

            ]),
          ),
        ),
      ),
    );
  }

  Widget _permBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          hoverColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(icon, size: 17, color: color.withValues(alpha: 0.7)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text('Không tìm thấy người dùng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
        const SizedBox(height: 4),
        Text('Thử đổi bộ lọc hoặc tìm kiếm khác', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
      ]),
    );
  }
}
