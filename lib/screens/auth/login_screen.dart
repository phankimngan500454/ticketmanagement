import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/user.dart';
import '../../services/notification_service.dart';
import '../../../main.dart' show setFullWindowSize;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  bool _obscure  = true;
  bool _loading  = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  final _repo = TicketRepository.instance;

  // ── Palette đồng bộ với toàn app ──────────────────────────────
  // Admin dùng: #1A237E (dark) / #3949AB (accent)
  // IT dùng:    #004D40 (dark) / #00897B (accent)
  // Login: dùng cùng navy/indigo của Admin → nhất quán
  static const _darkBlue   = Color(0xFF1A237E);
  static const _midBlue    = Color(0xFF283593);
  static const _accentBlue = Color(0xFF3949AB);
  static const _lightBlue  = Color(0xFF3D5AFE);
  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.07), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── Logic ─────────────────────────────────────────────────────
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final User? user = await _repo.login(
        _usernameCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() => _loading = false);
      if (user == null) {
        _showError('Tên đăng nhập hoặc mật khẩu không đúng.');
        return;
      }
      _navigateByRole(user);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showError('Không kết nối được máy chủ. Kiểm tra lại WiFi!');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg,
            style: const TextStyle(fontWeight: FontWeight.w500))),
      ]),
      backgroundColor: const Color(0xFFB71C1C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 4),
    ));
  }

  void _navigateByRole(User user) async {
    NotificationService.init(user.userId);
    await setFullWindowSize();
    if (!mounted) return;
    if (user.role == 'Admin') {
      context.go('/admin');
    } else if (user.role == 'IT') {
      context.go('/it');
    } else {
      context.go('/customer');
    }
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq    = MediaQuery.of(context);
    final isWide = mq.size.width >= 760;
    final minH  = mq.size.height - mq.padding.top - mq.padding.bottom;

    return Scaffold(
      body: Stack(children: [
        // Background gradient — giống header của các trang kia
        Positioned.fill(child: _buildBackground(context)),

        // Nội dung
        SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minH),
              child: Center(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: isWide
                          ? _buildWideCard()
                          : _buildNarrowCard(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Background: gradient + blobs nhẹ ──────────────────────────
  Widget _buildBackground(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SizedBox.expand(
      child: Stack(children: [
        // Gradient xanh navy — đồng bộ header admin & IT
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_darkBlue, _midBlue, Color(0xFF3949AB), Color(0xFF1565C0)],
              stops: [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        ),
        // Blob trang trí nhẹ nhàng (cùng tông màu)
        Positioned(
          top: -size.width * 0.12,
          right: -size.width * 0.08,
          child: _blob(size.width * 0.4, const Color(0xFF5C6BC0), 0.3)),
        Positioned(
          bottom: -size.height * 0.05,
          left: -size.width * 0.06,
          child: _blob(size.width * 0.3, const Color(0xFF3D5AFE), 0.2)),
        Positioned(
          top: size.height * 0.55,
          left: size.width * 0.55,
          child: _blob(size.width * 0.12, const Color(0xFF7986CB), 0.15)),
      ]),
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
      width: size, height: size,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity)));

  // ── Layout rộng (≥760px) ──────────────────────────────────────
  Widget _buildWideCard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 860),
        child: Container(
          decoration: BoxDecoration(
            // Card trắng — giống card của các trang kia
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 56,
                offset: const Offset(0, 16)),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(children: [
              // LEFT: branding xanh — giống header admin
              Expanded(
                flex: 4,
                child: _buildBrandingPanel(),
              ),
              // RIGHT: form trắng
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 44),
                  child: _buildForm(),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Layout hẹp (<760px) ───────────────────────────────────────
  Widget _buildNarrowCard() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 48,
                offset: const Offset(0, 12)),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _buildLogo(size: 56),
            const SizedBox(height: 12),
            const Text('MEDHUB',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900,
                    color: _darkBlue, letterSpacing: 3)),
            const SizedBox(height: 28),
            _buildForm(),
          ]),
        ),
      ),
    );
  }

  // ── Branding panel (trái) — giống style header admin/IT ───────
  Widget _buildBrandingPanel() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          // Cùng màu gradient với header admin dashboard
          colors: [_darkBlue, _accentBlue],
        ),
        borderRadius:
            const BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLogo(size: 64),
          const SizedBox(height: 22),
          const Text('MEDHUB',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900,
                  color: Colors.white, letterSpacing: 3.5)),
          const SizedBox(height: 6),
          Text('Cổng hỗ trợ nội bộ\nbệnh viện',
              style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.75),
                  height: 1.6)),
          const SizedBox(height: 36),
          // Feature list
          ...const [
            (Icons.speed_rounded,               'Xử lý yêu cầu nhanh chóng'),
            (Icons.track_changes_rounded,        'Theo dõi tiến độ thời gian thực'),
            (Icons.notifications_active_rounded, 'Thông báo tức thì'),
            (Icons.bar_chart_rounded,            'Báo cáo & thống kê'),
          ].map((e) => _featureRow(e.$1, e.$2)),
          const SizedBox(height: 32),
          // Divider
          Container(height: 1,
              color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 20),
          // Stats nhỏ
          Row(children: [
            _statItem('99%', 'Uptime'),
            _vDivider(),
            _statItem('< 1h', 'Phản hồi'),
            _vDivider(),
            _statItem('24/7', 'Hỗ trợ'),
          ]),
        ],
      ),
    );
  }

  Widget _buildLogo({required double size}) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.18),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.35), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4)),
        ],
      ),
      child: Icon(Icons.local_hospital_rounded,
          size: size * 0.44, color: Colors.white),
    );
  }

  Widget _featureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 15)),
        const SizedBox(width: 12),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.88),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _statItem(String value, String label) => Expanded(
    child: Column(children: [
      Text(value,
          style: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(
              fontSize: 10,
              color: Colors.white.withValues(alpha: 0.6))),
    ]),
  );

  Widget _vDivider() => Container(
      width: 1, height: 28,
      color: Colors.white.withValues(alpha: 0.2));

  // ── Form ──────────────────────────────────────────────────────
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
        // Header — giống style trong các màn hình admin
        Row(children: [
          Container(
            width: 4, height: 26,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_accentBlue, _lightBlue],
              ),
              borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 10),
          const Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Đăng nhập',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _darkBlue)),
            Text('Cổng hỗ trợ nội bộ bệnh viện',
                style: TextStyle(fontSize: 11, color: Color(0xFF78909C))),
          ]),
        ]),
        const SizedBox(height: 30),

        // Username field
        _field(
          label: 'Tên đăng nhập',
          controller: _usernameCtrl,
          icon: Icons.person_outline_rounded,
          action: TextInputAction.next,
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Vui lòng nhập tên đăng nhập'
              : null,
        ),
        const SizedBox(height: 16),

        // Password field
        _field(
          label: 'Mật khẩu',
          controller: _passwordCtrl,
          icon: Icons.lock_outline_rounded,
          obscure: _obscure,
          action: TextInputAction.done,
          onSubmitted: (_) => _login(),
          validator: (v) => (v == null || v.trim().isEmpty)
              ? 'Vui lòng nhập mật khẩu'
              : null,
          suffix: IconButton(
            icon: Icon(
              _obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: Colors.grey[400],
              size: 20),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
        const SizedBox(height: 28),

        // Login button — giống ElevatedButton trong admin
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _login,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              shadowColor: _accentBlue.withValues(alpha: 0.4),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.login_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('ĐĂNG NHẬP',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5)),
                    ]),
          ),
        ),
        const SizedBox(height: 22),
        Center(
          child: Text('© 2026 MedHub',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ),
      ]),
    );
  }

  // ── Field — style giống các form trong admin ───────────────────
  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    FormFieldValidator<String>? validator,
    Widget? suffix,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF455A64),
              letterSpacing: 0.3)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        textInputAction: action,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        style: const TextStyle(color: Color(0xFF1C1C2E), fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _accentBlue, size: 20),
          suffixIcon: suffix,
          filled: true,
          // Giống fillColor của các form admin (#F4F6FB / #F7F8FC)
          fillColor: const Color(0xFFF4F6FB),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _accentBlue, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935))),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE53935), width: 1.5)),
          errorStyle:
              const TextStyle(color: Color(0xFFE53935), fontSize: 11),
        ),
      ),
    ]);
  }
}
