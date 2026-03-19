import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/emergency_contact.dart';
import '../../models/user.dart';
import '../../data/ticket_repository.dart';

class AdminEmergencyContactsScreen extends StatefulWidget {
  const AdminEmergencyContactsScreen({super.key});

  @override
  State<AdminEmergencyContactsScreen> createState() => _AdminEmergencyContactsScreenState();
}

class _AdminEmergencyContactsScreenState extends State<AdminEmergencyContactsScreen> {
  final _repo = TicketRepository.instance;
  List<EmergencyContact> _contacts = [];
  List<User> _itStaff = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        _repo.getEmergencyContacts(),
        _repo.getITStaff(),
      ]);
      if (mounted) {
        setState(() {
          _contacts = results[0] as List<EmergencyContact>;
          _itStaff = results[1] as List<User>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showError('Không tải được dữ liệu: $e');
      }
    }
  }

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: const Color(0xFF43A047), behavior: SnackBarBehavior.floating));

  /// Dialog thêm/sửa — mode: "staff" (chọn IT) hoặc "custom" (số mới)
  Future<void> _showUpsertDialog({EmergencyContact? existing}) async {
    // Determine initial mode — if existing is linked to staff, start in staff mode
    final bool wasStaffMode = existing?.userId != null;
    bool isStaffMode = wasStaffMode;

    User? selectedStaff = existing?.userId != null
        ? _itStaff.where((u) => u.userId == existing!.userId).firstOrNull
        : null;

    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final orderCtrl = TextEditingController(text: (existing?.sortOrder ?? _contacts.length).toString());
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          title: Text(existing == null ? 'Thêm số khẩn cấp' : 'Chỉnh sửa',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [

                  // ── Mode toggle ──────────────────────────────
                  Row(children: [
                    Expanded(child: _modeBtn(
                      ctx: ctx,
                      label: '👤 Nhân viên IT',
                      active: isStaffMode,
                      onTap: () => setDialog(() {
                        isStaffMode = true;
                        if (selectedStaff != null) {
                          nameCtrl.text = selectedStaff!.fullName;
                          phoneCtrl.text = selectedStaff!.phone;
                        }
                      }),
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _modeBtn(
                      ctx: ctx,
                      label: '📞 Số tùy chỉnh',
                      active: !isStaffMode,
                      onTap: () => setDialog(() {
                        isStaffMode = false;
                        selectedStaff = null;
                      }),
                    )),
                  ]),
                  const SizedBox(height: 14),

                  // ── Staff picker (mode: staff) ───────────────
                  if (isStaffMode) ...[
                    const Text('Chọn nhân viên IT đang trực',
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<User>(
                          isExpanded: true,
                          value: selectedStaff,
                          hint: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('Chọn nhân viên...', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          borderRadius: BorderRadius.circular(10),
                          items: _itStaff.map((u) => DropdownMenuItem(
                            value: u,
                            child: Row(children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFF1976D2).withValues(alpha: 0.1),
                                child: Text(u.fullName[0],
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min, children: [
                                Text(u.fullName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                Text(u.phone.isNotEmpty ? u.phone : 'Chưa có SĐT',
                                    style: TextStyle(fontSize: 11, color: u.phone.isNotEmpty ? Colors.grey[500] : Colors.orange[600])),
                              ])),
                            ]),
                          )).toList(),
                          onChanged: (u) => setDialog(() {
                            selectedStaff = u;
                            if (u != null) {
                              nameCtrl.text = u.fullName;
                              phoneCtrl.text = u.phone;
                            }
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Preview / override fields
                    if (selectedStaff != null) ...[
                      const Text('Tên hiển thị (có thể chỉnh)',
                          style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                    ],
                  ],

                  // ── Name field (always shown) ─────────────────
                  if (!isStaffMode || selectedStaff != null) ...[
                    TextFormField(
                      controller: nameCtrl,
                      decoration: _dec(isStaffMode ? 'Tên hiển thị' : 'Tên liên hệ', Icons.badge_outlined),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]'))],
                      decoration: _dec('Số điện thoại', Icons.phone_outlined),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập SĐT' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: descCtrl,
                      decoration: _dec('Mô tả (tùy chọn)', Icons.notes_outlined),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: orderCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _dec('Thứ tự hiển thị', Icons.sort_rounded),
                    ),
                  ],

                  const SizedBox(height: 4),
                ]),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                if (!isStaffMode || selectedStaff != null) {
                  if (formKey.currentState!.validate()) Navigator.pop(ctx, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Vui lòng chọn nhân viên IT'),
                    behavior: SnackBarBehavior.floating,
                  ));
                }
              },
              child: const Text('Lưu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final contact = EmergencyContact(
        id: existing?.id,
        userId: isStaffMode ? selectedStaff?.userId : null,
        name: nameCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        sortOrder: int.tryParse(orderCtrl.text) ?? 0,
      );
      try {
        await _repo.upsertEmergencyContact(contact);
        _showSuccess(existing == null ? 'Đã thêm số khẩn cấp' : 'Đã cập nhật');
        _loadAll();
      } catch (e) {
        _showError('Lỗi: $e');
      }
    }
  }

  Widget _modeBtn({required BuildContext ctx, required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1976D2) : const Color(0xFFF4F5F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF1976D2) : Colors.grey.shade300),
        ),
        child: Text(label, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? Colors.white : Colors.grey[700])),
      ),
    );
  }

  Future<void> _confirmDelete(EmergencyContact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa số khẩn cấp', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Bạn có chắc muốn xóa "${contact.name}" (${contact.phoneNumber})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && contact.id != null) {
      try {
        await _repo.deleteEmergencyContact(contact.id!);
        _showSuccess('Đã xóa "${contact.name}"');
        _loadAll();
      } catch (e) {
        _showError('Lỗi khi xóa: $e');
      }
    }
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
    filled: true, fillColor: const Color(0xFFF8F9FF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5)),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      appBar: AppBar(
        title: const Text('Danh Bạ Khẩn Cấp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            onPressed: () => _showUpsertDialog(),
            tooltip: 'Thêm số mới',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
          : _contacts.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.phone_disabled_rounded, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Chưa có số khẩn cấp', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showUpsertDialog(),
                    icon: const Icon(Icons.add), label: const Text('Thêm số đầu tiên'),
                  ),
                ]))
              : RefreshIndicator(
                  onRefresh: _loadAll,
                  color: const Color(0xFF1976D2),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _contacts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = _contacts[i];
                      final isStaffLinked = c.userId != null;
                      return Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        elevation: 1,
                        shadowColor: Colors.black.withValues(alpha: 0.06),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                          child: Row(children: [
                            // Avatar
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: isStaffLinked
                                    ? const Color(0xFF1976D2).withValues(alpha: 0.1)
                                    : const Color(0xFFE53935).withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: isStaffLinked
                                  ? Center(child: Text(c.name[0].toUpperCase(),
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))))
                                  : const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFE53935), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Flexible(child: Text(c.name,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1C1C2E)))),
                                const SizedBox(width: 6),
                                if (isStaffLinked)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1976D2).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('IT Staff', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF1976D2))),
                                  ),
                              ]),
                              const SizedBox(height: 3),
                              Text(c.phoneNumber,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFE53935))),
                              if (c.description != null && c.description!.isNotEmpty)
                                Text(c.description!, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                            ])),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF1976D2)),
                              onPressed: () => _showUpsertDialog(existing: c),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFE53935)),
                              onPressed: () => _confirmDelete(c),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUpsertDialog(),
        backgroundColor: const Color(0xFFE53935),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Thêm số mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
