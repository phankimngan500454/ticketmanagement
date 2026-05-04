import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../data/ticket_repository.dart';

class WebITSidebar extends StatefulWidget {
  final User currentUser;
  final int selectedIndex; // 0 = Chờ nhận, 1 = Việc của tôi, 2 = Tất cả
  final ValueChanged<int> onIndexSelected;
  final int notificationCount;

  const WebITSidebar({
    super.key,
    required this.currentUser,
    required this.selectedIndex,
    required this.onIndexSelected,
    this.notificationCount = 0,
  });

  @override
  State<WebITSidebar> createState() => _WebITSidebarState();
}

class _WebITSidebarState extends State<WebITSidebar> {
  static const _green = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(right: BorderSide(color: Colors.grey.shade200, width: 1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(2, 0))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Logo
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF00695C), Color(0xFF00897B)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.computer_rounded, color: Colors.white, size: 20),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _navItem(0, Icons.inbox_rounded, 'Chờ nhận'),
                  _navItem(1, Icons.assignment_rounded, 'Việc của tôi'),
                  _navItem(2, Icons.list_alt_rounded, 'Tất cả'),
                  
                  const SizedBox(height: 24),
                  _notificationNavItem(context, Icons.notifications_rounded, 'Thông báo', '/notifications'),
                  _directNavItem(context, Icons.person_rounded, 'Hồ sơ', '/profile'),
                ],
              ),
            ),
          ),
          
          // User Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade100))),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: _green.withValues(alpha: 0.1),
              child: Text(
                widget.currentUser.fullName.isNotEmpty ? widget.currentUser.fullName[0].toUpperCase() : 'IT',
                style: const TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              onPressed: () async {
                await TicketRepository.instance.logout();
                if (context.mounted) context.go('/login');
              },
              tooltip: 'Đăng xuất',
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = widget.selectedIndex == index;
    final child = InkWell(
      onTap: () => widget.onIndexSelected(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? _green.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? _green : Colors.grey.shade400,
        ),
      ),
    );
    return Tooltip(message: label, child: child);
  }

  Widget _directNavItem(BuildContext context, IconData icon, String label, String route) {
    final child = InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        alignment: Alignment.center,
        child: Icon(icon, size: 24, color: Colors.grey.shade400),
      ),
    );
    return Tooltip(message: label, child: child);
  }

  Widget _notificationNavItem(BuildContext context, IconData icon, String label, String route) {
    final count = widget.notificationCount;
    final child = InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 24, color: Colors.grey.shade400),
            if (count > 0)
              Positioned(
                top: -6,
                right: -8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 4)],
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return Tooltip(message: label, child: child);
  }
}
