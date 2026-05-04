import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import 'web_sidebar.dart';

/// Wrapper dùng trên web cho các trang admin con (departments, categories, v.v.)
/// Hiển thị sidebar bên trái + nội dung trang bên phải, giống WebAdminDashboard.
class WebAdminSubpageWrapper extends StatelessWidget {
  final User currentUser;
  final Widget child;
  /// Index sidebar highlight (-1 = không highlight item nào)
  final int sidebarIndex;

  const WebAdminSubpageWrapper({
    super.key,
    required this.currentUser,
    required this.child,
    this.sidebarIndex = -1,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // Sidebar giống admin dashboard
          WebSidebar(
            currentUser: currentUser,
            selectedIndex: sidebarIndex,
            onItemSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/admin');
                  break;
                case 1:
                  context.go('/admin/reports');
                  break;
                case 2:
                  context.go('/admin/it-workload');
                  break;
                case 3:
                  context.go('/admin/emergency-contacts');
                  break;
              }
            },
          ),
          // Nội dung chính
          Expanded(child: child),
        ],
      ),
    );
  }
}
