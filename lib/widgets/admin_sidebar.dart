import 'package:flutter/material.dart';
import '../models/user.dart';
import '../screens/auth/login_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_assets_screen.dart';

/// Sidebar navigation giống Jira Service Management.
/// Dùng như Drawer trong AdminDashboard.
class AdminSidebar extends StatelessWidget {
  final User currentUser;
  final int selectedIndex; // 0=Queues, 1=Reports, 2=Customers
  final ValueChanged<int> onItemSelected;

  const AdminSidebar({
    Key? key,
    required this.currentUser,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF4F5F9),
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── PROJECT HEADER ─────────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3949AB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.confirmation_number_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ticket System',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Admin Project',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── MAIN NAVIGATION ────────────────────────────────────────────────
          _sectionLabel('CHÍNH'),
          _navItem(
            context,
            index: 0,
            icon: Icons.queue_rounded,
            label: 'Quản lý hàng đợi',
          ),
          _navItem(
            context,
            index: 1,
            icon: Icons.bar_chart_rounded,
            label: 'Báo cáo & Thống kê',
          ),

          const SizedBox(height: 8),
          const Divider(indent: 16, endIndent: 16),

          // ── PEOPLE ─────────────────────────────────────────────────────────
          _sectionLabel('QUẢN LÝ'),
          _navItem(
            context,
            index: 2,
            icon: Icons.notifications_outlined,
            label: 'Thông báo',
          ),
          _navItem(
            context,
            index: 3,
            icon: Icons.monitor_heart_rounded,
            label: 'Theo dõi IT',
          ),
          _navItem(
            context,
            index: 4,
            icon: Icons.phone_in_talk_rounded,
            label: 'Danh Bạ Khẩn Cấp',
          ),

          const SizedBox(height: 4),
          const Divider(indent: 16, endIndent: 16),
          _sectionLabel('CÀI ĐẶT'),
          // Navigate full-screen (not index-based) to avoid rebuilding whole dashboard

          _directNavItem(
            context,
            icon: Icons.manage_accounts_rounded,
            label: 'Tài khoản người dùng',
            screen: AdminUsersScreen(currentUser: currentUser),
          ),
          _directNavItem(
            context,
            icon: Icons.devices_rounded,
            label: 'Thiết bị',
            screen: AdminAssetsScreen(currentUser: currentUser),
          ),

          // _navItem(context, index: 4, icon: Icons.people_outline_rounded, label: 'Khách hàng'),
          const Spacer(),
          const Divider(indent: 16, endIndent: 16),

          // ── USER INFO ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF3949AB).withOpacity(0.15),
                  child: Text(
                    currentUser.fullName[0],
                    style: const TextStyle(
                      color: Color(0xFF3949AB),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser.fullName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Admin',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── LOGOUT ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: const [
                  Icon(Icons.logout_rounded, size: 17, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text('Đăng xuất', style: TextStyle(fontSize: 13, color: Colors.redAccent, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.grey[500],
        letterSpacing: 1,
      ),
    ),
  );

  Widget _navItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final selected = selectedIndex == index;
    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close drawer
        onItemSelected(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3949AB).withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? const Color(0xFF3949AB) : Colors.grey[600],
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? const Color(0xFF3949AB) : Colors.grey[700],
              ),
            ),
            if (selected) ...[
              const Spacer(),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF3949AB),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _directNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Widget screen,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 2, 8, 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ]),
      ),
    );
  }
}
