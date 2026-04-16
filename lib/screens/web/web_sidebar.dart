import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';

class WebSidebar extends StatefulWidget {
  final User currentUser;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const WebSidebar({
    super.key,
    required this.currentUser,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  State<WebSidebar> createState() => _WebSidebarState();
}

class _WebSidebarState extends State<WebSidebar> {
  final bool _isCollapsed = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
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
          )
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
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(
                Icons.local_hospital_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('MAIN'),
                  _navItem(0, Icons.dashboard_rounded, 'Dashboard'),
                  _navItem(1, Icons.bar_chart_rounded, 'Báo cáo & Thống kê'),
                  
                  const SizedBox(height: 16),
                  _sectionLabel('MANAGEMENT'),
                  _navItem(2, Icons.monitor_heart_rounded, 'Theo dõi IT'),
                  _navItem(3, Icons.phone_in_talk_rounded, 'DB Khẩn Cấp'),
                  
                  const SizedBox(height: 16),
                  _sectionLabel('SETTINGS'),
                  _directNavItem(context, Icons.people_rounded, 'Người dùng', '/admin/users'),
                  _directNavItem(context, Icons.devices_rounded, 'Thiết bị', '/admin/assets'),
                  _directNavItem(context, Icons.business_rounded, 'Phòng ban', '/admin/departments'),


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
                widget.currentUser.fullName.isNotEmpty ? widget.currentUser.fullName[0].toUpperCase() : '?',
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
              icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.redAccent),
              onPressed: () => context.go('/login'),
              tooltip: 'Đăng xuất',
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return const SizedBox.shrink();
  }

  Widget _navItem(int index, IconData icon, String label) {
    final isSelected = widget.selectedIndex == index;
    final child = InkWell(
      onTap: () => widget.onItemSelected(index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 24,
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade500,
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
        child: Icon(icon, size: 24, color: Colors.grey.shade500),
      ),
    );
    return Tooltip(message: label, child: child);
  }
}
