import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/ticket_repository.dart';
import '../../models/user.dart';
import 'widgets/request_type_selector.dart';

class CreateReopenMedicalScreen extends StatefulWidget {
  final User currentUser;
  final ValueChanged<String> onTypeChanged;
  const CreateReopenMedicalScreen({
    super.key,
    required this.currentUser,
    required this.onTypeChanged,
  });

  @override
  State<CreateReopenMedicalScreen> createState() =>
      _CreateReopenMedicalScreenState();
}

class _CreateReopenMedicalScreenState extends State<CreateReopenMedicalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TicketRepository.instance;

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  final _medicalRecordController = TextEditingController();
  final _reopenReasonController = TextEditingController();
  bool _affectsFinance = false;
  bool _submitting = false;

  final List<({String name, String mime, Uint8List bytes})> _pendingFiles = [];

  static const _themeColor = Color(0xFF2563EB); // Solid Primary Blue
  static const _themeDark = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.fullName);
    _phoneController = TextEditingController(text: widget.currentUser.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _medicalRecordController.dispose();
    _reopenReasonController.dispose();
    super.dispose();
  }

  // ── Pick files ───────────────────────────────────────────────
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'pdf',
        'doc',
        'docx',
      ],
      withData: true,
    );
    if (result == null) return;
    for (final f in result.files) {
      if (f.bytes == null) continue;
      if (f.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${f.name} vượt quá 5MB'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        continue;
      }
      final ext = (f.extension ?? 'bin').toLowerCase();
      String mime = 'application/octet-stream';
      if (['jpg', 'jpeg'].contains(ext))
        mime = 'image/jpeg';
      else if (ext == 'png')
        mime = 'image/png';
      else if (ext == 'gif')
        mime = 'image/gif';
      else if (ext == 'webp')
        mime = 'image/webp';
      else if (ext == 'pdf')
        mime = 'application/pdf';
      else if (['doc', 'docx'].contains(ext))
        mime = 'application/msword';
      setState(
        () => _pendingFiles.add((name: f.name, mime: mime, bytes: f.bytes!)),
      );
    }
  }

  // ── Submit ───────────────────────────────────────────────────
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final subject =
          'Mở lại bệnh án - SBA: ${_medicalRecordController.text.trim()}';
      final description = [
        '📋 Số bệnh án: ${_medicalRecordController.text.trim()}',
        '👤 Người yêu cầu: ${_nameController.text.trim()}',
        '📞 SĐT: ${_phoneController.text.trim()}',
        '💰 Ảnh hưởng tài chính: ${_affectsFinance ? "CÓ" : "KHÔNG"}',
        '',
        '📝 Lý do mở lại:',
        _reopenReasonController.text.trim(),
      ].join('\n');

      final categories = await _repo.getCategories();
      final newTicket = await _repo.createTicket(
        requesterId: widget.currentUser.userId,
        categoryId: categories.isNotEmpty ? categories.first.categoryId : 1,
        subject: subject,
        description: description,
        priority: 'Low',
        assetId: null,
        ticketType: 'reopen_medical',
      );

      // Upload attachments
      if (_pendingFiles.isNotEmpty) {
        for (final pf in _pendingFiles) {
          try {
            await _repo.uploadAttachment(
              ticketId: newTicket.ticketId,
              uploaderId: widget.currentUser.userId,
              fileName: pf.name,
              mimeType: pf.mime,
              fileData: base64Encode(pf.bytes),
              fileSize: pf.bytes.length,
            );
          } catch (_) {}
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gửi yêu cầu mở lại bệnh án thành công!'),
            backgroundColor: Color(0xFF43A047),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Có lỗi xảy ra, vui lòng thử lại!'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_themeDark, _themeColor],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Mở Lại Bệnh Án',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 14,
                                color: Colors.white70,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '📋 Mở lại BA',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          child: Text(
                            widget.currentUser.fullName[0],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.currentUser.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                widget.currentUser.deptName ??
                                    widget.currentUser.role,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ───────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Selector (TẠM ẨN ĐỂ TEST MỞ BỆNH ÁN) ──
                    // RequestTypeSelector(
                    //   currentType: 'reopen_medical',
                    //   onTypeChanged: widget.onTypeChanged,
                    // ),
                    const SizedBox(height: 14),

                    // ── Form chính ──
                    _buildFormCard(),
                    const SizedBox(height: 14),
                    _buildAttachmentCard(),
                    const SizedBox(height: 14),
                    _buildSubmitButton(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form chính: Mở lại bệnh án ─────────────────────────────
  Widget _buildFormCard() {
    return _card(
      icon: Icons.folder_open_rounded,
      iconColor: _themeColor,
      label: 'Thông tin mở lại bệnh án',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Họ tên
          _fieldLabel('Họ tên người yêu cầu', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            decoration: _inputDeco(
              hint: 'Nhập họ tên...',
              icon: Icons.person_outline,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập họ tên' : null,
          ),
          const SizedBox(height: 16),

          // Số điện thoại
          _fieldLabel('Số điện thoại', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDeco(
              hint: 'Nhập số điện thoại...',
              icon: Icons.phone_outlined,
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập SĐT' : null,
          ),
          const SizedBox(height: 16),

          // Số bệnh án
          _fieldLabel('Số bệnh án', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _medicalRecordController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDeco(
              hint: 'VD: 123456...',
              icon: Icons.assignment_outlined,
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Vui lòng nhập số bệnh án'
                : null,
          ),
          const SizedBox(height: 16),

          // Lý do mở lại
          _fieldLabel('Lý do mở lại', required: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _reopenReasonController,
            maxLines: 4,
            decoration: _inputDeco(
              hint: 'Mô tả lý do cần mở lại bệnh án...',
              icon: Icons.edit_note_rounded,
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _reopenReasonController,
                builder: (context, value, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (value.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8, right: 8),
                          child: InkWell(
                            onTap: () => _reopenReasonController.clear(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        const SizedBox(
                          width: 32,
                          height: 32,
                        ), // giữ khung để không bị giật UI
                    ],
                  );
                },
              ),
            ),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Vui lòng nhập lý do' : null,
          ),
          const SizedBox(height: 20),

          // Toggle: Ảnh hưởng tài chính
          _buildFinanceToggle(),
        ],
      ),
    );
  }

  Widget _buildFinanceToggle() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _affectsFinance
            ? _themeColor.withValues(alpha: 0.06)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _affectsFinance
              ? _themeColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _affectsFinance
                  ? _themeColor.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.monetization_on_outlined,
              size: 20,
              color: _affectsFinance ? _themeColor : Colors.grey[500],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Có ảnh hưởng đến tài chính?',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _affectsFinance
                        ? _themeColor
                        : const Color(0xFF1C1C2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _affectsFinance
                      ? 'Có ảnh hưởng — cần xem xét tài chính'
                      : 'Không ảnh hưởng tài chính',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.9,
            child: Switch(
              value: _affectsFinance,
              onChanged: (v) => setState(() => _affectsFinance = v),
              activeColor: _themeColor,
              activeTrackColor: _themeColor.withValues(alpha: 0.3),
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
        ],
      ),
    );
  }

  // ── Attachment card ──
  Widget _buildAttachmentCard() => _card(
    icon: Icons.image_rounded,
    iconColor: const Color(0xFF00897B),
    label: 'Ảnh / File đính kèm',
    badge: 'TÙY CHỌN',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_pendingFiles.isNotEmpty) ...[
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _pendingFiles.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final pf = _pendingFiles[i];
                final isImg = pf.mime.startsWith('image/');
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF00897B).withValues(alpha: 0.3),
                        ),
                      ),
                      child: isImg
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.memory(pf.bytes, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.insert_drive_file_rounded,
                                  color: Color(0xFF00897B),
                                  size: 28,
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  child: Text(
                                    pf.name,
                                    style: const TextStyle(fontSize: 8),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    Positioned(
                      top: -6,
                      right: -6,
                      child: GestureDetector(
                        onTap: () => setState(() => _pendingFiles.removeAt(i)),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE53935),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: _pickFiles,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: _themeColor.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _themeColor.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 28,
                  color: _themeColor,
                ),
                SizedBox(height: 6),
                Text(
                  'Chọn ảnh hoặc file',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _themeColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'JPG · PNG · GIF · PDF · DOC — tối đa 5MB/file',
                  style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSubmitButton() => Container(
    width: double.infinity,
    height: 54,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [_themeDark, _themeColor]),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: _themeColor.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: _submitting ? null : _submitForm,
      icon: _submitting
          ? const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
      label: Text(
        _submitting ? 'Đang gửi...' : 'GỬI YÊU CẦU',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    ),
  );

  // ── Helpers ──
  Widget _fieldLabel(String label, {bool required = false}) => Row(
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1C1C2E),
        ),
      ),
      if (required)
        const Text(
          ' *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFFE53935),
          ),
        ),
    ],
  );

  InputDecoration _inputDeco({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
    prefixIcon: Icon(icon, size: 18, color: Colors.grey[500]),
    suffixIcon: suffixIcon,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    filled: true,
    fillColor: const Color(0xFFF8F9FF),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _themeColor, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE53935)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
    ),
  );

  Widget _card({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    String? badge,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C2E),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
