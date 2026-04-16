import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';

class WebCustomerSidebar extends StatefulWidget {
  final User currentUser;
  final String?
  selectedType; // null -> Tất cả, 'ticket', 'reopen_medical', 'feedback'
  final ValueChanged<String?> onTypeSelected;

  const WebCustomerSidebar({
    super.key,
    required this.currentUser,
    required this.selectedType,
    required this.onTypeSelected,
  });

  @override
  State<WebCustomerSidebar> createState() => _WebCustomerSidebarState();
}

class _WebCustomerSidebarState extends State<WebCustomerSidebar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, // Using collapsed sidebar by default like Admin Dashboard
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _navItem(
                    null,
                    Icons.apps_rounded,
                    'Tất cả',
                    const Color(0xFF2563EB),
                  ),
                  // _navItem('ticket', Icons.computer_rounded, 'Yêu cầu IT', const Color(0xFF1976D2)),
                  _navItem(
                    'reopen_medical',
                    Icons.folder_open_rounded,
                    'Mở lại bệnh án',
                    const Color.fromARGB(255, 148, 182, 234),
                  ),

                  // _navItem('feedback', Icons.rate_review_rounded, 'Góp ý', const Color(0xFF00897B)),
                  const SizedBox(height: 24),
                  _directNavItem(
                    context,
                    Icons.notifications_rounded,
                    'Thông báo',
                    '/notifications',
                  ),
                  _directNavItem(
                    context,
                    Icons.phone_in_talk_rounded,
                    'Gọi IT / Khẩn Cấp',
                    '/emergency',
                  ),
                  _directNavItem(
                    context,
                    Icons.person_rounded,
                    'Hồ sơ',
                    '/profile',
                  ),
                ],
              ),
            ),
          ),

          // User Section
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
              child: Text(
                widget.currentUser.fullName.isNotEmpty
                    ? widget.currentUser.fullName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(bottom: 20),
            alignment: Alignment.center,
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                size: 20,
                color: Colors.redAccent,
              ),
              onPressed: () => context.go('/login'),
              tooltip: 'Đăng xuất',
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(String? type, IconData icon, String label, Color iconColor) {
    final isSelected = widget.selectedType == type;
    final child = InkWell(
      onTap: () => widget.onTypeSelected(type),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? iconColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? iconColor : Colors.grey.shade400,
        ),
      ),
    );
    return Tooltip(message: label, child: child);
  }

  Widget _directNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
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
}
