import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/ticket_repository.dart';
import '../../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final User currentUser;
  const ProfileScreen({super.key, required this.currentUser});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _repo = TicketRepository.instance;
  late TabController _tabCtrl;

  // ── Tab 1: Thông tin cá nhân ──
  final _infoKey   = GlobalKey<FormState>();
  late TextEditingController _phoneCtrl;
  bool _savingInfo = false;

  // ── Tab 2: Mật khẩu ──
  final _pwKey     = GlobalKey<FormState>();
  final _oldPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confCtrl  = TextEditingController();
  bool _oldVisible = false;
  bool _newVisible = false;
  bool _confVisible = false;
  bool _savingPw   = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl  = TabController(length: 2, vsync: this);
    _phoneCtrl = TextEditingController(text: widget.currentUser.phone);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _phoneCtrl.dispose();
    _oldPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confCtrl.dispose();
    super.dispose();
  }

  // ── Màu / label theo role ──────────────────────────────────────
  Color get _roleColor {
    switch (widget.currentUser.role) {
      case 'Admin': return const Color(0xFF283593); // Indigo đậm, rất chuyên nghiệp
      case 'IT':    return const Color(0xFF0288D1); // Xanh dương nhạt
      default:      return const Color(0xFF00897B); // Xanh ngọc
    }
  }

  String get _roleLabel {
    switch (widget.currentUser.role) {
      case 'Admin': return 'Quản trị viên';
      case 'IT':    return 'Kỹ thuật viên IT';
      default:      return 'Nhân viên';
    }
  }

  IconData get _roleIcon {
    switch (widget.currentUser.role) {
      case 'Admin': return Icons.shield_rounded;
      case 'IT':    return Icons.build_rounded;
      default:      return Icons.person_rounded;
    }
  }

  // ── Lưu số điện thoại ─────────────────────────────────────────
  Future<void> _savePhone() async {
    if (!_infoKey.currentState!.validate()) return;
    final newPhone = _phoneCtrl.text.trim();
    if (newPhone == widget.currentUser.phone) {
      _showSnack('Số điện thoại chưa thay đổi.', Colors.orange);
      return;
    }
    setState(() => _savingInfo = true);
    try {
      // roleId: Admin=1, IT=2, Customer=3
      final roleId = widget.currentUser.role == 'Admin'
          ? 1 : widget.currentUser.role == 'IT' ? 2 : 3;
      await _repo.updateUser(
        userId: widget.currentUser.userId,
        fullName: widget.currentUser.fullName,
        phone: newPhone,
        roleId: roleId,
        deptId: widget.currentUser.deptId == 0 ? null : widget.currentUser.deptId,
      );
      if (!mounted) return;
      _showSnack('✅ Cập nhật số điện thoại thành công!', const Color(0xFF43A047));
    } catch (e) {
      if (mounted) _showSnack('Đã xảy ra lỗi, vui lòng thử lại!', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _savingInfo = false);
    }
  }

  // ── Đổi mật khẩu ──────────────────────────────────────────────
  Future<void> _changePassword() async {
    if (!_pwKey.currentState!.validate()) return;
    setState(() => _savingPw = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('saved_username') ?? '';

      // Xác thực mật khẩu cũ
      final verified = await _repo.login(savedUsername, _oldPwCtrl.text.trim());
      if (verified == null) {
        if (mounted) _showSnack('❌ Mật khẩu hiện tại không đúng!', const Color(0xFFE53935));
        setState(() => _savingPw = false);
        return;
      }

      // Đổi mật khẩu
      final ok = await _repo.resetPassword(widget.currentUser.userId, _newPwCtrl.text.trim());
      if (!mounted) return;

      if (ok) {
        await prefs.setString('saved_password', _newPwCtrl.text.trim());
        _oldPwCtrl.clear(); _newPwCtrl.clear(); _confCtrl.clear();
        _showSnack('✅ Đổi mật khẩu thành công!', const Color(0xFF43A047));
      } else {
        _showSnack('❌ Đổi mật khẩu thất bại, thử lại!', const Color(0xFFE53935));
      }
    } catch (e) {
      if (mounted) _showSnack('Đã xảy ra lỗi, vui lòng thử lại!', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _savingPw = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor;
    final initials = widget.currentUser.fullName
        .trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // ── HEADER ──────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.black, 0.25)!,
                color,
              ],
            ),
          ),
          child: SafeArea(bottom: false, child: Column(children: [
            // Back + title
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text('Tài khoản của tôi',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ]),
            ),

            // Avatar + thông tin
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(children: [
                // Avatar circle
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.22),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 2.5),
                  ),
                  child: Center(child: Text(
                    initials,
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                  )),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.currentUser.fullName,
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_roleIcon, size: 12, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(_roleLabel,
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  if (widget.currentUser.deptName != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.business_outlined, size: 12, color: Colors.white.withValues(alpha: 0.75)),
                      const SizedBox(width: 4),
                      Expanded(child: Text(widget.currentUser.deptName!,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                  ],
                ])),
              ]),
            ),

            // Tab bar
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: color,
                unselectedLabelColor: Colors.white.withValues(alpha: 0.85),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: '👤  Thông tin'),
                  Tab(text: '🔒  Mật khẩu'),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ])),
        ),

        // ── TAB VIEWS ──────────────────────────────────────────
        Expanded(child: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildInfoTab(color),
            _buildPasswordTab(color),
          ],
        )),
      ]),
    );
  }

  // ── TAB 1: Thông tin cá nhân ──────────────────────────────────
  Widget _buildInfoTab(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Form(
        key: _infoKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Thông tin chỉ đọc
          _card(children: [
            _readOnlyRow(Icons.badge_outlined, 'Họ và tên', widget.currentUser.fullName, color),
            _divider(),
            _readOnlyRow(_roleIcon, 'Vai trò', _roleLabel, color),
            if (widget.currentUser.deptName != null) ...[
              _divider(),
              _readOnlyRow(Icons.business_outlined, 'Phòng ban', widget.currentUser.deptName!, color),
            ],
          ]),
          const SizedBox(height: 16),

          // Số điện thoại (có thể chỉnh sửa)
          _card(children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.phone_outlined, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text('Số điện thoại',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF43A047).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Có thể chỉnh sửa',
                    style: TextStyle(fontSize: 10, color: Color(0xFF43A047), fontWeight: FontWeight.bold)),
                ),
              ]),
            ),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập số điện thoại';
                if (v.length < 9 || v.length > 11) return 'Số điện thoại không hợp lệ';
                return null;
              },
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E)),
              decoration: _inputDeco('VD: 0901234567', color,
                prefix: const Icon(Icons.phone_rounded, size: 18)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _savingInfo ? null : _savePhone,
                icon: _savingInfo
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_rounded, size: 20),
                label: Text(_savingInfo ? 'Đang lưu...' : 'Lưu thay đổi',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),

          // Ghi chú
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.info_outline_rounded, size: 15, color: Colors.orange),
              const SizedBox(width: 8),
              const Expanded(child: Text(
                'Họ tên, phòng ban và vai trò do quản trị viên quản lý. Liên hệ Admin nếu cần thay đổi.',
                style: TextStyle(fontSize: 11, color: Colors.orange, height: 1.5),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── TAB 2: Đổi mật khẩu ──────────────────────────────────────
  Widget _buildPasswordTab(Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Form(
        key: _pwKey,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Mô tả
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(children: [
              Icon(Icons.lock_outline_rounded, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text(
                'Mật khẩu mới phải có ít nhất 6 ký tự và khác mật khẩu hiện tại.',
                style: TextStyle(fontSize: 12, color: color, height: 1.5),
              )),
            ]),
          ),
          const SizedBox(height: 16),

          _card(children: [
            // Mật khẩu hiện tại
            _pwLabel('Mật khẩu hiện tại'),
            _pwField(
              ctrl: _oldPwCtrl, hint: 'Nhập mật khẩu đang dùng...',
              visible: _oldVisible, onToggle: () => setState(() => _oldVisible = !_oldVisible),
              color: color,
              validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
            ),
            const SizedBox(height: 4),
            Divider(height: 28, color: Colors.grey.shade100),

            // Mật khẩu mới
            _pwLabel('Mật khẩu mới'),
            _pwField(
              ctrl: _newPwCtrl, hint: 'Tối thiểu 6 ký tự...',
              visible: _newVisible, onToggle: () => setState(() => _newVisible = !_newVisible),
              color: color,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng nhập mật khẩu mới';
                if (v.length < 6) return 'Ít nhất 6 ký tự';
                if (v == _oldPwCtrl.text) return 'Phải khác mật khẩu hiện tại';
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Xác nhận
            _pwLabel('Xác nhận mật khẩu mới'),
            _pwField(
              ctrl: _confCtrl, hint: 'Nhập lại mật khẩu mới...',
              visible: _confVisible, onToggle: () => setState(() => _confVisible = !_confVisible),
              color: color,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                if (v != _newPwCtrl.text) return 'Mật khẩu không khớp';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Nút
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _savingPw ? null : _changePassword,
                icon: _savingPw
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.lock_reset_rounded, size: 20),
                label: Text(_savingPw ? 'Đang lưu...' : 'Cập nhật mật khẩu',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _divider() => Divider(height: 22, color: Colors.grey.shade100);

  Widget _readOnlyRow(IconData icon, String label, String value, Color color) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E))),
      ])),
    ]);
  }

  Widget _pwLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(label,
      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600)),
  );

  Widget _pwField({
    required TextEditingController ctrl,
    required String hint,
    required bool visible,
    required VoidCallback onToggle,
    required Color color,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: !visible,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
        prefixIcon: Icon(Icons.lock_outline, size: 18, color: Colors.grey[400]),
        suffixIcon: IconButton(
          icon: Icon(visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18, color: Colors.grey[400]),
          onPressed: onToggle,
        ),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: color, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, Color color, {Widget? prefix}) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    prefixIcon: prefix,
    filled: true,
    fillColor: const Color(0xFFF8F9FF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
  );
}
