import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/ticket_repository.dart';
import '../../main.dart' show setLoginWindowSize;

/// Widget header dùng chung cho tất cả các Dashboard.
/// Nhận vào: tiêu đề, tên người dùng, lời chào,
/// gradient màu, và một widget con tuỳ chọn (stat cards, tab bar...).
class DashboardHeader extends StatelessWidget {
  final String title;
  final String userName;
  final String greeting;
  final List<Color> gradientColors;
  final Widget? bottomContent;
  final Widget? leadingAction;
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final bool showGreeting;

  const DashboardHeader({
    super.key,
    required this.title,
    required this.userName,
    required this.greeting,
    required this.gradientColors,
    this.bottomContent,
    this.leadingAction,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.showGreeting = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: title + actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
              child: Row(
                children: [
                  // Left side: menu + title (Expanded để chiếm hết phần còn lại)
                  Expanded(
                    child: Row(
                      children: [
                        if (leadingAction != null) ...[
                          leadingAction!,
                          const SizedBox(width: 4),
                        ],
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Notification bell + Avatar
                  Row(
                    children: [
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                            onPressed: onNotificationTap,
                          ),
                          if (notificationCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$notificationCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      _LogoutAvatar(userName: userName),
                    ],
                  ),
                ],
              ),
            ),

            // ── Greeting ──
            if (showGreeting)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(greeting, style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            // ── Bottom content (stat cards / tab bar) ──
            if (bottomContent != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: bottomContent!,
              ),
            ] else
              const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Avatar bấm vào → popup menu Hồ sơ + Đăng xuất.
/// Dùng Builder để lấy đúng context cho Navigator + PopupMenu.
class _LogoutAvatar extends StatelessWidget {
  final String userName;
  const _LogoutAvatar({required this.userName});

  @override
  Widget build(BuildContext context) {
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) async {
        if (value == 'logout') {
          TicketRepository.instance.logout();
          await setLoginWindowSize();
          if (context.mounted) context.go('/login');
        } else if (value == 'profile') {
          await context.push('/profile');
        }
      },
      itemBuilder: (_) => [
        // User info header (non-selectable)
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF3949AB).withValues(alpha: 0.12),
                child: Text(initial,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF3949AB))),
              ),
              const SizedBox(width: 10),
              Flexible(child: Text(userName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1C1C2E)),
                overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            const Divider(height: 1),
          ]),
        ),
        // Hồ sơ
        const PopupMenuItem(
          value: 'profile',
          child: Row(children: [
            Icon(Icons.manage_accounts_rounded, color: Color(0xFF3949AB), size: 18),
            SizedBox(width: 10),
            Text('Hồ sơ & đổi mật khẩu',
                style: TextStyle(color: Color(0xFF3949AB), fontWeight: FontWeight.w600)),
          ]),
        ),
        const PopupMenuDivider(),
        // Đăng xuất
        const PopupMenuItem(
          value: 'logout',
          child: Row(children: [
            Icon(Icons.logout_rounded, color: Colors.red, size: 18),
            SizedBox(width: 10),
            Text('Đăng xuất',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ]),
        ),
      ],
      child: CircleAvatar(
        radius: 18,
        backgroundColor: Colors.white.withValues(alpha: 0.25),
        child: Text(initial,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}
