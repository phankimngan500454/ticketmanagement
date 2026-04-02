import 'package:flutter/material.dart';
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

  // Role filter: null=all
  String? _roleFilter;

  static const _blue = Color(0xFF3949AB);
  static const _roles = [
    {'label': 'Admin', 'id': 1, 'color': Color(0xFF9C27B0)},
    {'label': 'IT', 'id': 2, 'color': Color(0xFF1976D2)},
    {'label': 'Người dùng', 'id': 3, 'color': Color(0xFF43A047)},
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
      // Deduplicate departments by deptId to prevent DropdownButton assertion error
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
        u.phone.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'Admin': return const Color(0xFF9C27B0);
      case 'IT': return const Color(0xFF1976D2);
      default: return const Color(0xFF43A047);
    }
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'Admin': return 'Admin';
      case 'IT': return 'IT';
      default: return 'User';
    }
  }

  // ── Create / Edit user sheet ────────────────────────────────
  void _showUserSheet({User? existing}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    int roleId = existing != null
        ? (existing.role == 'Admin' ? 1 : existing.role == 'IT' ? 2 : 3)
        : 3;
    int? deptId = existing?.deptId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: SingleChildScrollView(child: Form(key: formKey, child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(existing == null ? 'Tạo tài khoản mới' : 'Sửa thông tin người dùng',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Full name
          _inputField(nameCtrl, 'Họ tên', Icons.person_outline,
            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập họ tên' : null),
          const SizedBox(height: 10),

          // Phone
          _inputField(phoneCtrl, 'Số điện thoại', Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (v) {
              if (v != null && v.trim().isNotEmpty) {
                if (!RegExp(r'^[0-9]+$').hasMatch(v.trim())) return 'Chỉ được nhập số';
                if (v.trim().length < 9) return 'Số điện thoại quá ngắn';
              }
              return null;
            }),
          const SizedBox(height: 10),

          // Username + Password (only for new user)
          if (existing == null) ...[ 
            _inputField(usernameCtrl, 'Tên đăng nhập', Icons.account_circle_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Vui lòng nhập tên đăng nhập';
                if (v.trim().contains(' ')) return 'Không được chứa khoảng trắng';
                return null;
              }),
            const SizedBox(height: 10),
            _inputField(passCtrl, 'Mật khẩu', Icons.lock_outline,
              obscureText: true,
              validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mật khẩu' : null),
            const SizedBox(height: 10),
          ],

          // Role selector
          Text('Vai trò', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Row(children: _roles.map((r) {
            final selected = roleId == r['id'] as int;
            final color = r['color'] as Color;
            return Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setS(() => roleId = r['id'] as int),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? color : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? color : Colors.transparent, width: 1.5),
                  ),
                  child: Text(r['label'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: selected ? Colors.white : Colors.grey[600])),
                ),
              ),
            ));
          }).toList()),
          const SizedBox(height: 10),

          // Department
          if (_departments.isNotEmpty && roleId != 2) ...[ 
            Text('Phòng ban', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            DropdownButtonFormField<int?>(
              initialValue: _departments.any((d) => d.deptId == deptId) ? deptId : null,
              decoration: InputDecoration(
                filled: true, fillColor: const Color(0xFFF4F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              ),
              hint: const Text('Không có phòng ban'),
              items: [
                const DropdownMenuItem(value: null, child: Text('— Không có —')),
                ..._departments.map((d) => DropdownMenuItem(
                  value: d.deptId, child: Text(d.deptName))),
              ],
              onChanged: (v) => setS(() => deptId = v),
            ),
            const SizedBox(height: 10),
          ],

          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: Icon(existing == null ? Icons.person_add_rounded : Icons.save_rounded, size: 17),
              label: Text(existing == null ? 'Tạo tài khoản' : 'Lưu thay đổi',
                style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                
                final name = nameCtrl.text.trim();
                Navigator.pop(ctx);
                try {
                  final finalDeptId = roleId == 2 ? null : deptId;
                  if (existing == null) {
                    // Create new user
                    final username = usernameCtrl.text.trim();
                    final password = passCtrl.text.trim();
                    
                    final result = await _repo.register(
                      username: username, password: password,
                      fullName: name, phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      roleId: roleId, deptId: finalDeptId,
                    );
                    
                    if (result == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('❌ Lỗi: Tên đăng nhập này đã tồn tại!'),
                          backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));
                      }
                      return; // Dừng lại, không chạy load hay báo thành công
                    }
                  } else {
                    await _repo.updateUser(
                      userId: existing.userId, fullName: name,
                      phone: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      roleId: roleId, deptId: finalDeptId,
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('❌ Đã xảy ra lỗi, vui lòng thử lại!'), backgroundColor: Colors.red));
                  }
                }
              },
            ),
          ),
        ]))),
      )),
    );
  }

  // ── Reset password sheet ────────────────────────────────────
  void _showResetPasswordSheet(User user) {
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
        child: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Reset mật khẩu — ${user.fullName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Nhập mật khẩu mới cho tài khoản này.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 16),
          _inputField(passCtrl, 'Mật khẩu mới', Icons.lock_outline, obscureText: true,
            validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập mật khẩu mới' : null),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock_reset_rounded, size: 17),
              label: const Text('Đặt lại mật khẩu', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
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
                      backgroundColor: Colors.orange,
                      behavior: SnackBarBehavior.floating));
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
        ])),
      ),
    );
  }

  // ── Delete user ─────────────────────────────────────────────
  Future<void> _deleteUser(User user) async {
    if (user.userId == widget.currentUser.userId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('❌ Không thể xoá tài khoản đang đăng nhập'),
        backgroundColor: Colors.red));
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
          content: Text('🗑️ Đã xoá tài khoản'),
          backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Đã xảy ra lỗi, vui lòng thử lại!'), backgroundColor: Colors.red));
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────
  Widget _inputField(TextEditingController ctrl, String label, IconData icon,
      {bool obscureText = false, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
        filled: true, fillColor: const Color(0xFFF4F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _blue, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
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
                const Expanded(child: Text('Quản lý Người dùng',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                Text('${_users.length} tài khoản',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
              ]),
            ),
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, SĐT...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
                  suffixIcon: _searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                        child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.7), size: 16))
                    : null,
                  filled: true, fillColor: Colors.white.withValues(alpha: 0.15),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            // Role filter chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(children: [
                _filterChip('Tất cả', null),
                ..._roles.map((r) => _filterChip(r['label'] as String, r['label'] as String)),
              ]),
            ),
          ])),
        ),

        // ── List ────────────────────────────────────────
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: _blue))
            : list.isEmpty
                ? Center(child: Text('Không tìm thấy', style: TextStyle(color: Colors.grey[500])))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: list.length,
                    itemBuilder: (ctx, i) => _buildUserCard(list[i]),
                  )),
      ]),

      // ── FAB ─────────────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserSheet(),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Thêm user', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _filterChip(String label, String? roleValue) {
    final selected = _roleFilter == roleValue;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _roleFilter = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? _blue : Colors.white)),
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    final roleColor = _roleColor(user.role);
    final roleLabel = _roleLabel(user.role);
    final isSelf = user.userId == widget.currentUser.userId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: roleColor.withValues(alpha: 0.12),
            child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: roleColor)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Flexible(child: Text(user.fullName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1C1C2E)),
                overflow: TextOverflow.ellipsis)),
              if (isSelf) ...[ 
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                  child: const Text('Bạn', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blue)),
                ),
              ],
            ]),
            Row(children: [
              Container(
                margin: const EdgeInsets.only(top: 3, right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
                child: Text(roleLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor)),
              ),
              if (user.phone.isNotEmpty)
                Text(user.phone,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          ])),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.grey[400]),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_rounded, size: 16, color: Color(0xFF3949AB)),
                  SizedBox(width: 8),
                  Text('Sửa thông tin'),
                ])),
              const PopupMenuItem(value: 'reset',
                child: Row(children: [
                  Icon(Icons.lock_reset_rounded, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Reset mật khẩu'),
                ])),
              if (!isSelf) const PopupMenuItem(value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Xoá tài khoản', style: TextStyle(color: Colors.red)),
                ])),
            ],
            onSelected: (v) {
              if (v == 'edit') _showUserSheet(existing: user);
              if (v == 'reset') _showResetPasswordSheet(user);
              if (v == 'delete') _deleteUser(user);
            },
          ),
        ]),
      ),
    );
  }
}
