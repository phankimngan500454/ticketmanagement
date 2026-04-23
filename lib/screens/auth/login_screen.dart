import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/user.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _repo = TicketRepository.instance;

  bool _obscure = true;
  bool _loading = false;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
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
      _showError('Không kết nối được máy chủ. Kiểm tra lại mạng.');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: AppTheme.danger,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _navigateByRole(User user) async {
    NotificationService.init(user.userId);
    await setFullWindowSize();
    if (!mounted) return;
    if (user.role == 'Admin') {
      context.go('/admin');
    } else if (user.role == 'IT') {
      context.go('/it');
    } else if (user.role == 'Manager') {
      context.go('/manager');
    } else {
      context.go('/customer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width >= 980;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _buildBackground()),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1080),
                      child: isWide
                          ? _buildDesktopShell()
                          : _buildMobileShell(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Background ────────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _glow(280, const Color(0xFF60A5FA), 0.18),
          ),
          Positioned(
            right: -110,
            top: 80,
            child: _glow(360, const Color(0xFF22D3EE), 0.14),
          ),
          Positioned(
            bottom: -120,
            right: 120,
            child: _glow(300, const Color(0xFF38BDF8), 0.12),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }

  // ─── Layout shells ─────────────────────────────────────────────────────────

  Widget _buildDesktopShell() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 11,
              child: _buildHeroPanel(
                padding: const EdgeInsets.fromLTRB(44, 44, 32, 44),
              ),
            ),
            Expanded(
              flex: 10,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: _buildFormCard(compact: false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileShell() {
    return _buildFormCard(compact: true);
  }

  // ─── Hero panel ────────────────────────────────────────────────────────────

  Widget _buildHeroPanel({required EdgeInsets padding}) {
    return Padding(
      padding: padding,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo + Tên
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.15),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MedHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Cổng hỗ trợ nội bộ bệnh viện',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Lời chào
            const Row(
              children: [
                Icon(Icons.waving_hand_rounded, color: Colors.white, size: 26),
                SizedBox(width: 8),
                Text(
                  'Xin chào!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Đây là nơi bạn có thể gửi yêu cầu hỗ trợ và theo dõi tiến độ xử lý một cách dễ dàng.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 30),

            // 3 việc người dùng có thể làm
            _userAction(
              icon: Icons.add_circle_outline_rounded,
              color: const Color(0xFF60A5FA),
              title: 'Gửi yêu cầu hỗ trợ',
              desc:
                  'Báo sự cố IT, thiết bị hoặc bất kỳ vấn đề nào cần được hỗ trợ.',
            ),
            const SizedBox(height: 16),
            _userAction(
              icon: Icons.track_changes_rounded,
              color: const Color(0xFF34D399),
              title: 'Theo dõi tiến độ',
              desc:
                  'Xem yêu cầu của bạn đang được xử lý đến đâu, theo thời gian thực.',
            ),
            const SizedBox(height: 16),
            _userAction(
              icon: Icons.notifications_active_outlined,
              color: const Color(0xFFFBBF24),
              title: 'Nhận thông báo kịp thời',
              desc:
                  'Biết ngay khi có cập nhật hoặc phản hồi cho yêu cầu của bạn.',
            ),
            const SizedBox(height: 36),

            // Status dot nhỏ ở dưới
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF4ADE80),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Hệ thống đang hoạt động bình thường',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _userAction({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Form card ─────────────────────────────────────────────────────────────

  Widget _buildFormCard({required bool compact}) {
    return Container(
      constraints: BoxConstraints(maxWidth: compact ? 460 : 520),
      padding: EdgeInsets.all(compact ? 24 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 38,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (compact) ...[
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppTheme.brandDark, AppTheme.brand],
                    ),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Tiêu đề
            Text(
              'Đăng nhập',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: compact ? TextAlign.center : TextAlign.left,
            ),
            const SizedBox(height: 6),
            Text(
              'Nhập tài khoản được cấp để vào hệ thống.',
              textAlign: compact ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Ô nhập
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
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Gợi ý liên hệ
            Text(
              'Chưa có tài khoản? Liên hệ bộ phận IT để được cấp.',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 20),

            // Nút đăng nhập
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _login,
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Đăng nhập'),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2026 MedHub – Cổng hỗ trợ nội bộ bệnh viện',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Field helper ──────────────────────────────────────────────────────────

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    bool obscure = false,
    TextInputAction action = TextInputAction.next,
    ValueChanged<String>? onSubmitted,
    FormFieldValidator<String>? validator,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.text,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textInputAction: action,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          style: const TextStyle(color: AppTheme.text, fontSize: 14),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.brand, size: 20),
            suffixIcon: suffix,
            hintText: hint,
          ),
        ),
      ],
    );
  }
}
