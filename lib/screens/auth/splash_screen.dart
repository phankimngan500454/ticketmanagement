import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';
import '../../models/user.dart';
import '../../services/notification_service.dart';
import '../../../main.dart' show setFullWindowSize;

class SplashScreen extends StatefulWidget {
  // redirectUrl được truyền qua query parameter ?redirect=...
  final String? redirectUrl;
  const SplashScreen({super.key, this.redirectUrl});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final repo = TicketRepository.instance;
    final User? user = await repo.tryAutoLogin();
    
    if (!mounted) return;
    
    if (user != null) {
      // 🔔 Register FCM token for push notifications
      NotificationService.init(user.userId);
      // Expand to full window on desktop when auto-login succeeds
      await setFullWindowSize();
      if (!mounted) return;
      // Nếu có redirectUrl (từ F5 tại màn hình khác), quay về đó
      final redirect = widget.redirectUrl;
      if (redirect != null && redirect.isNotEmpty && redirect != '/') {
        context.go(redirect);
      } else if (user.role == 'Admin') {
        context.go('/admin');
      } else if (user.role == 'IT') {
        context.go('/it');
      } else {
        context.go('/customer');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E), // indigo[900]
              Color(0xFF303F9F), // indigo[700]
              Color(0xFF3949AB), // indigo[600]
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_hospital_rounded,
                size: 80,
                color: Colors.white,
              ),
              SizedBox(height: 20),
              CircularProgressIndicator(color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
