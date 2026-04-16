import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../data/ticket_repository.dart';
import '../models/ticket.dart';
import '../models/user.dart';

// Screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/web/web_admin_dashboard.dart'; // Web Dashboard
import 'screens/web/web_customer_dashboard.dart';
import 'screens/web/web_it_dashboard.dart';
import 'screens/web/web_manager_dashboard.dart';
import 'screens/it/it_agent_dashboard.dart';
import 'screens/customer/customer_dashboard.dart';
import 'screens/manager/manager_dashboard.dart';
import 'screens/shared/ticket_detail_screen.dart';
import 'screens/shared/feedback_detail_screen.dart';
import 'screens/shared/notifications_screen.dart';
import 'package:flutter/foundation.dart'; // Thêm kIsWeb
import 'screens/shared/not_found_screen.dart';
import 'screens/customer/create_ticket_screen.dart';
import 'screens/customer/emergency_call_screen.dart';
import 'screens/admin/admin_users_screen.dart';
import 'screens/admin/admin_categories_screen.dart';
import 'screens/admin/admin_departments_screen.dart';
import 'screens/admin/admin_assets_screen.dart';
import 'screens/admin/admin_emergency_contacts_screen.dart';
import 'screens/admin/it_workload_screen.dart';
import 'screens/admin/report_screen.dart';
import 'screens/shared/profile_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

// ── Đường dẫn nào cần đăng nhập trước ───────────────────────────
const _publicRoutes = {'/login', '/'};

class TicketDetailWrapper extends StatefulWidget {
  final int ticketId;
  final Ticket? ticket;
  final User currentUser;
  final bool isAdmin;
  final bool isEmbedded;
  
  const TicketDetailWrapper({
    super.key, 
    required this.ticketId, 
    this.ticket, 
    required this.currentUser, 
    required this.isAdmin,
    this.isEmbedded = false,
  });

  @override
  State<TicketDetailWrapper> createState() => _TicketDetailWrapperState();
}

class _TicketDetailWrapperState extends State<TicketDetailWrapper> {
  Ticket? _ticket;
  
  @override
  void initState() {
    super.initState();
    if (widget.ticket != null) {
      _ticket = widget.ticket;
    } else {
      TicketRepository.instance.getTicketById(widget.ticketId).then((t) {
        if (mounted) setState(() => _ticket = t);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ticket == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Color(0xFF3949AB))),
      );
    }
    // Feedback / reopen_medical tickets → màn hình đơn giản
    if (_ticket!.ticketType == 'feedback' || _ticket!.ticketType == 'reopen_medical') {
      return FeedbackDetailScreen(
        ticket: _ticket!,
        currentUser: widget.currentUser,
        isEmbedded: widget.isEmbedded,
      );
    }
    return TicketDetailScreen(
      ticket: _ticket!, 
      currentUser: widget.currentUser, 
      isAdmin: widget.isAdmin,
      isEmbedded: widget.isEmbedded,
    );
  }
}

// ── Trả về route mặc định theo role sau khi đăng nhập ───────────
String _homeForUser(User user) {
  if (user.role == 'Admin') return '/admin';
  if (user.role == 'IT') return '/it';
  final p = user.permissions ?? '';
  if (user.role == 'Manager' || p.contains('insurance') || p.contains('finance')) return '/manager';
  return '/customer';
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  errorBuilder: (context, state) => NotFoundScreen(location: state.uri.path),
  // ── REDIRECT LOGIC: xử lý tập trung, không để trong builder ────
  redirect: (context, state) {
    final path = state.matchedLocation;
    final isPublic = _publicRoutes.contains(path);
    final user = TicketRepository.instance.currentUser;
    
    // Đang ở trang Splash (/) và đã có session → đi thẳng vào app
    if (path == '/' && user != null) {
      return _homeForUser(user);
    }
    
    // Ở trang công khai (/, /login) → không can thiệp
    if (isPublic) return null;
    
    // Ở trang cần auth mà chưa login → về Splash để auto-login
    if (user == null) return '/?redirect=${Uri.encodeComponent(path)}';
    
    // ── PHÂN QUYỀN THEO ROLE & PERMISSIONS ───────────────────────
    final role = user.role;
    final p = user.permissions ?? '';
    final isMedicalApprover = p.contains('insurance') || p.contains('finance');

    // Customer chỉ được vào /customer và /ticket/:id và /notifications
    if (role == 'Customer' && !isMedicalApprover && (path.startsWith('/admin') || path.startsWith('/it') || path.startsWith('/manager'))) {
      return '/customer';
    }
    // Nếu là Customer nhưng được phân quyền duyệt bệnh án, chặn Admin/IT nhưng pass Manager
    if (role == 'Customer' && isMedicalApprover && (path.startsWith('/admin') || path.startsWith('/it'))) {
      return '/manager';
    }
    // IT chỉ được vào /it và /ticket/:id và /notifications, không vào /admin
    if (role == 'IT' && (path.startsWith('/admin') || path.startsWith('/manager'))) {
      return '/it';
    }
    // Manager chỉ được vào /manager và /ticket/:id và /notifications
    if (role == 'Manager' && (path.startsWith('/admin') || path.startsWith('/it') || path.startsWith('/customer'))) {
      return '/manager';
    }
    
    return null; // OK, pass through
  },
  routes: [
    // ── Auth ─────────────────────────────────────────────────────
    GoRoute(
      path: '/',
      builder: (context, state) {
        // Lấy redirect param nếu có (khi F5 tại màn hình con)
        final redirectUrl = state.uri.queryParameters['redirect'];
        return SplashScreen(redirectUrl: redirectUrl);
      },
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    // ── Dashboards theo role ─────────────────────────────────────
    GoRoute(
      path: '/admin',
      builder: (context, state) {
        final user = TicketRepository.instance.currentUser!;
        if (kIsWeb) {
          return WebAdminDashboard(currentUser: user);
        }
        return AdminDashboard(currentUser: user);
      },
    ),
    GoRoute(
      path: '/it',
      builder: (context, state) {
        final user = TicketRepository.instance.currentUser!;
        if (kIsWeb) {
          return WebITDashboard(currentUser: user);
        }
        return ITAgentDashboard(currentUser: user);
      },
    ),
    GoRoute(
      path: '/customer',
      builder: (context, state) {
        final user = TicketRepository.instance.currentUser!;
        if (kIsWeb) {
          return WebCustomerDashboard(currentUser: user);
        }
        return CustomerDashboard(currentUser: user);
      },
    ),
    GoRoute(
      path: '/manager',
      builder: (context, state) {
        final user = TicketRepository.instance.currentUser!;
        if (kIsWeb) {
          return WebManagerDashboard(currentUser: user);
        }
        return ManagerDashboard(currentUser: user);
      },
    ),

    // ── Shared screens ───────────────────────────────────────────
    GoRoute(
      path: '/ticket/:id',
      builder: (context, state) {
        final ticketId = int.tryParse(state.pathParameters['id'] ?? '');
        final ticket = state.extra is Ticket ? state.extra as Ticket : null;
        final user = TicketRepository.instance.currentUser!;
        if (ticketId == null) return const Scaffold(body: Center(child: Text('Ticket không hợp lệ')));
        return TicketDetailWrapper(
          ticket: ticket,
          ticketId: ticketId,
          currentUser: user,
          isAdmin: user.role == 'Admin',
        );
      },
    ),
    GoRoute(
      path: '/create-ticket',
      builder: (context, state) => CreateTicketScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
    GoRoute(
      path: '/emergency',
      builder: (context, state) => EmergencyCallScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => NotificationsScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen(currentUser: TicketRepository.instance.currentUser!),
    ),

    // ── Admin only routes ─────────────────────────────────────────
    GoRoute(
      path: '/admin/users',
      builder: (context, state) => AdminUsersScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
    GoRoute(
      path: '/admin/categories',
      builder: (context, state) => AdminCategoriesScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
    GoRoute(
      path: '/admin/departments',
      builder: (context, state) => AdminDepartmentsScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
    GoRoute(
      path: '/admin/assets',
      builder: (context, state) => AdminAssetsScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
    GoRoute(
      path: '/admin/emergency-contacts',
      builder: (context, state) => const AdminEmergencyContactsScreen(),
    ),
    GoRoute(
      path: '/admin/it-workload',
      builder: (context, state) => ITWorkloadScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => ReportScreen(currentUser: TicketRepository.instance.currentUser!),
    ),
  ],
);
