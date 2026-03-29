import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/ticket_repository.dart';

class NotFoundScreen extends StatelessWidget {
  final String? location;
  const NotFoundScreen({super.key, this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Big number
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
                ).createShader(bounds),
                child: const Text(
                  '404',
                  style: TextStyle(
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF3949AB).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFF3949AB)),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Trang không tìm thấy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E)),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                location != null
                    ? 'Địa chỉ "$location" không tồn tại trong hệ thống.'
                    : 'Trang bạn đang tìm không tồn tại hoặc đã bị xóa.',
                style: TextStyle(fontSize: 13, color: Colors.grey[500], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Back button
              FilledButton.icon(
                onPressed: () {
                  final user = TicketRepository.instance.currentUser;
                  if (user == null) {
                    context.go('/login');
                  } else if (user.role == 'Admin') {
                    context.go('/admin');
                  } else if (user.role == 'IT') {
                    context.go('/it');
                  } else {
                    context.go('/customer');
                  }
                },
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text('Về trang chủ'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3949AB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
