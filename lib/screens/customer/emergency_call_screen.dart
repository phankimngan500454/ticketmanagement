import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/emergency_contact.dart';
import '../../models/user.dart';
import '../../data/ticket_repository.dart';
import 'create_ticket_screen.dart';

class EmergencyCallScreen extends StatefulWidget {
  final User currentUser;
  const EmergencyCallScreen({super.key, required this.currentUser});

  @override
  State<EmergencyCallScreen> createState() => _EmergencyCallScreenState();
}

class _EmergencyCallScreenState extends State<EmergencyCallScreen> {
  final _repo = TicketRepository.instance;
  List<EmergencyContact> _contacts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final contacts = await _repo.getEmergencyContacts();
      if (mounted) setState(() { _contacts = contacts; _loading = false; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Không tải được danh bạ: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _call(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Không thể gọi $phone trên thiết bị này'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(
        children: [
          // ── Red Header ─────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(0xFFB71C1C), Color(0xFFE53935)],
              ),
            ),
            child: SafeArea(bottom: false, child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(child: Text('Gọi Khẩn Cấp IT',
                      style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Đường dây hỗ trợ khẩn cấp',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    SizedBox(height: 2),
                    Text('Chọn số để gọi ngay hoặc tạo ticket sau khi liên hệ',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ])),
                ]),
              ),
            ])),
          ),

          // ── Contacts List ──────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
                : _contacts.isEmpty
                    ? _emptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: _contacts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _contactCard(_contacts[index]),
                      ),
          ),

          // ── Create Ticket Button ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(children: [
              const Divider(),
              const SizedBox(height: 8),
              const Text('Sau khi gọi xong, hãy tạo ticket để ghi nhận sự cố',
                  style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    final nav = Navigator.of(context);
                    final result = await nav.push(MaterialPageRoute(
                        builder: (_) => CreateTicketScreen(
                              currentUser: widget.currentUser,
                              isEmergency: true,
                            )));
                  if (mounted && result == true) {
                    nav.pop(true);
                  }
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Tạo Ticket Sự Cố', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _contactCard(EmergencyContact contact) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.07),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFE53935), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(contact.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E))),
            const SizedBox(height: 3),
            Text(contact.phoneNumber,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFFE53935), letterSpacing: 0.5)),
            if (contact.description != null && contact.description!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(contact.description!,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ])),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _call(contact.phoneNumber),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.call_rounded, color: Colors.white, size: 16),
                SizedBox(width: 5),
                Text('Gọi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _emptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFFE53935).withValues(alpha: 0.08), shape: BoxShape.circle),
        child: Icon(Icons.phone_disabled_rounded, size: 48, color: Colors.red[200]),
      ),
      const SizedBox(height: 16),
      const Text('Chưa có số khẩn cấp nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      Text('Admin chưa cấu hình đường dây hỗ trợ', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
    ]));
  }
}
