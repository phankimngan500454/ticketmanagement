import 'dart:ui';
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

  static const _darkBlue  = Color(0xFF0D1B6E);
  static const _midBlue   = Color(0xFF1A237E);
  static const _accentBlue= Color(0xFF3949AB);
  static const _lightBlue = Color(0xFF1565C0);

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
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

  // ── Logic ──────────────────────────────────────────────────────
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
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w500))),
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

  // ── Build ──────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    // 680px là ngưỡng: dưới đây = mobile layout, trên = desktop layout
    final isWide = width >= 680;

    return Scaffold(
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  // ── DESKTOP: 2 cột ────────────────────────────────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // ── LEFT: Branding panel ──────────────────────────────
        Expanded(
          flex: 5,
          child: _BrandingPanel(),
        ),
        // ── RIGHT: Login form (trắng sạch) ───────────────────
        Expanded(
          flex: 4,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Container(
                color: Colors.white,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 380),
                        child: _buildFormCard(isWide: true),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── MOBILE: Full-screen gradient + form ───────────────────────
  Widget _buildMobileLayout() {
    final size = MediaQuery.of(context).size;
    return Stack(children: [
      // Background gradient
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [_darkBlue, _midBlue, Color(0xFF283593), _lightBlue],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
      ),
      // Decorative blobs
      Positioned(top: -size.width * 0.3, right: -size.width * 0.2,
          child: _blob(size.width * 0.75, const Color(0xFF5C6BC0), 0.35)),
      Positioned(bottom: -size.width * 0.25, left: -size.width * 0.15,
          child: _blob(size.width * 0.65, const Color(0xFF1976D2), 0.3)),
      // Content
      SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: [Color(0xFF7986CB), Color(0xFF3F51B5)],
                          ),
                          boxShadow: [BoxShadow(
                            color: _accentBlue.withValues(alpha: 0.5),
                            blurRadius: 24, offset: const Offset(0, 8))],
                          border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                        ),
                        child: const Icon(Icons.support_agent_rounded, size: 40, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('IT HELPDESK',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 4)),
                    const SizedBox(height: 5),
                    Text('Hệ thống quản lý yêu cầu hỗ trợ kỹ thuật',
                      style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.65)),
                      textAlign: TextAlign.center),
                    const SizedBox(height: 36),
                    _buildFormCard(isWide: false),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Form card (dùng chung cho cả 2 layout) ────────────────────
  Widget _buildFormCard({required bool isWide}) {
    if (isWide) {
      // Desktop: clean white card, không glassmorphism
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(children: [
            Container(
              width: 4, height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accentBlue, _lightBlue], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 12),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Đăng nhập', style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
              Text('IT Helpdesk System', style: TextStyle(
                  fontSize: 12, color: Color(0xFF78909C))),
            ]),
          ]),
          const SizedBox(height: 36),
          // Form
          Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _desktopField(
                label: 'Tên đăng nhập',
                controller: _usernameCtrl,
                icon: Icons.person_outline_rounded,
                action: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
              ),
              const SizedBox(height: 20),
              _desktopField(
                label: 'Mật khẩu',
                controller: _passwordCtrl,
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                action: TextInputAction.done,
                onSubmitted: (_) => _login(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                suffix: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey[400], size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              const SizedBox(height: 32),
              // Login button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    shadowColor: _accentBlue.withValues(alpha: 0.4),
                    padding: EdgeInsets.zero,
                  ),
                  child: _loading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.login_rounded, size: 20),
                          SizedBox(width: 10),
                          Text('ĐĂNG NHẬP',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ]),
                ),
              ),
              const SizedBox(height: 24),
              Center(child: Text('© 2026 IT Helpdesk System',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]))),
            ]),
          ),
        ],
      );
    }

    // Mobile: glassmorphism card như cũ
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.22), width: 1.5),
          ),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(width: 4, height: 22,
                  decoration: BoxDecoration(color: const Color(0xFF90CAF9), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 10),
                const Text('Đăng nhập tài khoản',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
              ]),
              const SizedBox(height: 24),
              _fieldLabel('Tên đăng nhập'),
              const SizedBox(height: 7),
              TextFormField(
                controller: _usernameCtrl,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
                decoration: _mobileFieldDeco(icon: Icons.person_outline_rounded),
              ),
              const SizedBox(height: 16),
              _fieldLabel('Mật khẩu'),
              const SizedBox(height: 7),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _obscure,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _login(),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                decoration: _mobileFieldDeco(
                  icon: Icons.lock_outline_rounded,
                  suffix: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: Colors.white.withValues(alpha: 0.55), size: 20),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: EdgeInsets.zero,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF5C6BC0), _accentBlue]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                        color: _accentBlue.withValues(alpha: 0.5),
                        blurRadius: 14, offset: const Offset(0, 5))],
                    ),
                    child: Center(
                      child: _loading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.login_rounded, color: Colors.white, size: 20),
                              SizedBox(width: 10),
                              Text('ĐĂNG NHẬP',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                                    color: Colors.white, letterSpacing: 2)),
                            ]),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Desktop field ──────────────────────────────────────────────
  Widget _desktopField({
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
      Text(label, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF455A64), letterSpacing: 0.3)),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        obscureText: obscure,
        textInputAction: action,
        onFieldSubmitted: onSubmitted,
        validator: validator,
        style: const TextStyle(color: Color(0xFF1C1C2E), fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF3949AB), size: 20),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF4F6FB),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accentBlue, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
          ),
          errorStyle: const TextStyle(color: Color(0xFFE53935), fontSize: 11),
        ),
      ),
    ]);
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _fieldLabel(String text) => Text(text,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
        color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.3));

  InputDecoration _mobileFieldDeco({required IconData icon, Widget? suffix}) =>
      InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.09),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF9A9A)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF9A9A), width: 1.5),
        ),
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 11),
      );

  Widget _blob(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)));
}

// ── BRANDING PANEL (Left side on desktop) ──────────────────────
class _BrandingPanel extends StatefulWidget {
  const _BrandingPanel();
  @override
  State<_BrandingPanel> createState() => _BrandingPanelState();
}

class _BrandingPanelState extends State<_BrandingPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF0D1B6E), Color(0xFF1A237E), Color(0xFF283593), Color(0xFF1565C0)],
          stops: [0.0, 0.3, 0.65, 1.0],
        ),
      ),
      child: Stack(children: [
        // Animated blobs
        AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = _ctrl.value;
            return Stack(children: [
              Positioned(
                top: -80 + t * 30, right: -60 + t * 20,
                child: _blob(320, const Color(0xFF5C6BC0), 0.3)),
              Positioned(
                bottom: -60 + t * 25, left: -50 + t * 15,
                child: _blob(280, const Color(0xFF1976D2), 0.25)),
              Positioned(
                top: 200 + t * 40, left: 80 + t * 20,
                child: _blob(160, const Color(0xFF7986CB), 0.2)),
            ]);
          },
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Hero(
                  tag: 'app_logo',
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [Color(0xFF7986CB), Color(0xFF3F51B5)],
                      ),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFF3949AB).withValues(alpha: 0.6),
                        blurRadius: 16, offset: const Offset(0, 4))],
                      border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(Icons.support_agent_rounded, size: 28, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('IT HELPDESK',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900,
                      color: Colors.white, letterSpacing: 3)),
                const SizedBox(height: 6),
                Text('Hệ thống quản lý yêu cầu hỗ trợ kỹ thuật',
                  style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7),
                      height: 1.5)),
                // Flexible spacer — co lại nếu không đủ chỗ
                const Flexible(child: SizedBox(height: 24)),
                // Feature list
                ...[
                  (Icons.speed_rounded,                 'Phản hồi nhanh chóng'),
                  (Icons.track_changes_rounded,          'Theo dõi tiến độ realtime'),
                  (Icons.notifications_active_rounded,   'Thông báo tức thì'),
                  (Icons.bar_chart_rounded,              'Báo cáo & thống kê'),
                ].map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(item.$1, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(item.$2,
                      style: TextStyle(fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w500)),
                  ]),
                )),

              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _blob(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: opacity)));
}
