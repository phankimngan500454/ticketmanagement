import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/user.dart';
import '../../services/notification_service.dart';

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

  bool _obscure   = true;
  bool _loading   = false;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  final _repo = TicketRepository.instance;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
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

  void _navigateByRole(User user) {
    NotificationService.init(user.userId);
    if (user.role == 'Admin') {
      context.go('/admin');
    } else if (user.role == 'IT') {
      context.go('/it');
    } else {
      context.go('/customer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(children: [

        // ── Background gradient ─────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0D1B6E),
                Color(0xFF1A237E),
                Color(0xFF283593),
                Color(0xFF1565C0),
              ],
              stops: [0.0, 0.35, 0.65, 1.0],
            ),
          ),
        ),

        // ── Decorative blobs ────────────────────────────────────
        Positioned(
          top: -size.width * 0.3,
          right: -size.width * 0.2,
          child: _blob(size.width * 0.75, const Color(0xFF5C6BC0), 0.35),
        ),
        Positioned(
          bottom: -size.width * 0.25,
          left: -size.width * 0.15,
          child: _blob(size.width * 0.65, const Color(0xFF1976D2), 0.3),
        ),
        Positioned(
          top: size.height * 0.35,
          left: size.width * 0.65,
          child: _blob(size.width * 0.4, const Color(0xFF7986CB), 0.2),
        ),

        // ── Content ─────────────────────────────────────────────
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

                      // ── Logo ──────────────────────────────────
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 88, height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF7986CB), Color(0xFF3F51B5)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3949AB).withValues(alpha: 0.5),
                                blurRadius: 24, offset: const Offset(0, 8)),
                            ],
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3), width: 2),
                          ),
                          child: const Icon(Icons.support_agent_rounded,
                              size: 44, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // ── App name ──────────────────────────────
                      const Text(
                        'IT HELPDESK',
                        style: TextStyle(
                          fontSize: 30, fontWeight: FontWeight.w900,
                          color: Colors.white, letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Hệ thống quản lý yêu cầu hỗ trợ kỹ thuật',
                        style: TextStyle(
                          fontSize: 13, letterSpacing: 0.3,
                          color: Colors.white.withValues(alpha: 0.65)),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // ── Glassmorphism card ─────────────────────
                      ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22), width: 1.5),
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [

                                  // Title
                                  Row(children: [
                                    Container(
                                      width: 4, height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF90CAF9),
                                        borderRadius: BorderRadius.circular(2)),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('Đăng nhập tài khoản',
                                      style: TextStyle(fontSize: 18,
                                          fontWeight: FontWeight.bold, color: Colors.white)),
                                  ]),
                                  const SizedBox(height: 26),

                                  // ── Username ───────────────────
                                  _fieldLabel('Tên đăng nhập'),
                                  const SizedBox(height: 7),
                                  TextFormField(
                                    controller: _usernameCtrl,
                                    cursorWidth: 3.0,
                                    cursorColor: Colors.white,
                                    cursorRadius: const Radius.circular(2),
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập tên đăng nhập' : null,
                                    decoration: _fieldDeco(
                                      icon: Icons.person_outline_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  // ── Password ───────────────────
                                  _fieldLabel('Mật khẩu'),
                                  const SizedBox(height: 7),
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    obscureText: _obscure,
                                    cursorWidth: 3.0,
                                    cursorColor: Colors.white,
                                    cursorRadius: const Radius.circular(2),
                                    style: const TextStyle(color: Colors.white, fontSize: 15),
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    validator: (v) =>
                                        (v == null || v.trim().isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                                    decoration: _fieldDeco(
                                      icon: Icons.lock_outline_rounded,
                                      suffix: IconButton(
                                        icon: Icon(
                                          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                          color: Colors.white.withValues(alpha: 0.55), size: 20),
                                        onPressed: () => setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),

                                  // ── Login button ───────────────
                                  SizedBox(
                                    height: 54,
                                    child: ElevatedButton(
                                      onPressed: _loading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16)),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Ink(
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)],
                                          ),
                                          borderRadius: BorderRadius.circular(16),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF3949AB).withValues(alpha: 0.5),
                                              blurRadius: 14, offset: const Offset(0, 5)),
                                          ],
                                        ),
                                        child: Center(
                                          child: _loading
                                              ? const SizedBox(
                                                  width: 22, height: 22,
                                                  child: CircularProgressIndicator(
                                                      color: Colors.white, strokeWidth: 2.5))
                                              : const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.login_rounded,
                                                        color: Colors.white, size: 20),
                                                    SizedBox(width: 10),
                                                    Text('ĐĂNG NHẬP',
                                                      style: TextStyle(
                                                        fontSize: 15, fontWeight: FontWeight.bold,
                                                        color: Colors.white, letterSpacing: 2)),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ── Footer ────────────────────────────────
                      const SizedBox(height: 32),
                      Text(
                        '© 2025 IT Helpdesk System',
                        style: TextStyle(
                          fontSize: 11, color: Colors.white.withValues(alpha: 0.35)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 12, fontWeight: FontWeight.w600,
      color: Colors.white.withValues(alpha: 0.75), letterSpacing: 0.3),
  );

  InputDecoration _fieldDeco({
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.09),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        errorStyle: const TextStyle(color: Color(0xFFEF9A9A), fontSize: 12),
      );

  Widget _blob(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: opacity),
    ),
  );
}
