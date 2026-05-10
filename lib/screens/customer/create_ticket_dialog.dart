import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/ticket_repository.dart';
import '../../models/category.dart';
import '../../models/asset.dart';
import '../../models/user.dart';

/// Dialog tạo yêu cầu dành cho Web — gọn gàng, 1 header chung + tab chuyển mượt
class CreateTicketDialog extends StatefulWidget {
  final User currentUser;

  const CreateTicketDialog({super.key, required this.currentUser});

  /// Hiển thị dialog tạo yêu cầu (trả về true nếu đã tạo thành công)
  static Future<bool?> show(BuildContext context, User currentUser) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'CreateTicketDialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim, secAnim) => CreateTicketDialog(currentUser: currentUser),
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        return ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );
  }

  @override
  State<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends State<CreateTicketDialog> with SingleTickerProviderStateMixin {
  final _repo = TicketRepository.instance;
  final _formKey = GlobalKey<FormState>();

  // ── TẠM ẨN: mặc định mở tab bệnh án ──
  late TabController _tabCtrl;
  int _currentTab = 1; // TẠM: force bệnh án tab, gốc = 0

  // ── Shared controllers ──
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  // ── Repair fields ──
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  List<Category> _categories = [];
  List<Asset> _assets = [];
  Category? _selectedCategory;
  Asset? _selectedAsset;
  String _priority = 'Medium';
  DateTime? _proposedDeadline;
  bool _loadingOptions = true;

  // ── Reopen Medical fields ──
  final _medicalRecordCtrl = TextEditingController();
  final _reopenReasonCtrl = TextEditingController();
  final _patientNameCtrl = TextEditingController();
  bool _affectsFinance = false;

  // ── Feedback fields ──
  final _feedbackSubjectCtrl = TextEditingController();
  final _feedbackDescCtrl = TextEditingController();

  // ── Shared ──
  final List<({String name, String mime, Uint8List bytes})> _pendingFiles = [];
  bool _submitting = false;

  // ── Tab config ──
  static const _tabConfigs = [
    (icon: Icons.build_rounded, label: 'Sửa chữa', color: Color(0xFF2563EB)),
    (icon: Icons.folder_open_rounded, label: 'Mở lại BA', color: Color(0xFF0891B2)),
    (icon: Icons.chat_bubble_outline_rounded, label: 'Góp ý', color: Color(0xFF059669)),
  ];

  Color get _activeColor => _tabConfigs[_currentTab].color;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this, initialIndex: 1); // TẠM: bệnh án tab
    _tabCtrl.addListener(() {
      if (_tabCtrl.indexIsChanging) return;
      setState(() => _currentTab = _tabCtrl.index);
    });
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _loadOptions();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _medicalRecordCtrl.dispose();
    _reopenReasonCtrl.dispose();
    _patientNameCtrl.dispose();
    _feedbackSubjectCtrl.dispose();
    _feedbackDescCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final categories = await _repo.getCategories();
      final rawAssets = await _repo.getAssets();
      final seen = <int>{};
      final assets = rawAssets.where((a) => seen.add(a.assetId)).toList();
      if (mounted) setState(() { _categories = categories; _assets = assets; _loadingOptions = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp', 'pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result == null) return;
    for (final f in result.files) {
      if (f.bytes == null) continue;
      if (f.size > 5 * 1024 * 1024) continue;
      final ext = (f.extension ?? 'bin').toLowerCase();
      String mime = 'application/octet-stream';
      if (['jpg', 'jpeg'].contains(ext)) { mime = 'image/jpeg'; }
      else if (ext == 'png') { mime = 'image/png'; }
      else if (ext == 'gif') { mime = 'image/gif'; }
      else if (ext == 'webp') { mime = 'image/webp'; }
      else if (ext == 'pdf') { mime = 'application/pdf'; }
      else if (['doc', 'docx'].contains(ext)) { mime = 'application/msword'; }
      setState(() => _pendingFiles.add((name: f.name, mime: mime, bytes: f.bytes!)));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      late final String subject;
      late final String description;
      late final String ticketType;
      late final String priority;
      int? assetId;
      int categoryId = 1;

      if (_currentTab == 0) {
        // Repair
        if (_selectedCategory == null) {
          _showError('Vui lòng chọn danh mục lỗi!');
          setState(() => _submitting = false);
          return;
        }
        subject = _subjectCtrl.text.trim();
        description = [
          if (_locationCtrl.text.trim().isNotEmpty) 'Địa điểm: ${_locationCtrl.text.trim()}',
          _descriptionCtrl.text.trim(),
        ].join('\n\n');
        ticketType = 'ticket';
        priority = _priority;
        categoryId = _selectedCategory!.categoryId;
        assetId = _selectedAsset?.assetId;
      } else if (_currentTab == 1) {
        // Reopen Medical
        subject = 'Mở lại bệnh án - MVP: ${_medicalRecordCtrl.text.trim()}';
        description = [
          'Mã viện phí của bệnh nhân: ${_medicalRecordCtrl.text.trim()}',
          'Tên người yêu cầu: ${_nameCtrl.text.trim()}',
          'SĐT: ${_phoneCtrl.text.trim()}',
          'Ảnh hưởng tài chính: ${_affectsFinance ? "CÓ" : "KHÔNG"}',
          '',
          'Lý do mở lại:',
          _reopenReasonCtrl.text.trim(),
        ].join('\n');
        ticketType = 'reopen_medical';
        priority = 'Low';
        final categories = await _repo.getCategories();
        categoryId = categories.isNotEmpty ? categories.first.categoryId : 1;
      } else {
        // Feedback
        subject = _feedbackSubjectCtrl.text.trim();
        description = _feedbackDescCtrl.text.trim();
        ticketType = 'feedback';
        priority = 'Low';
        final categories = await _repo.getCategories();
        categoryId = categories.isNotEmpty ? categories.first.categoryId : 1;
      }

      final newTicket = await _repo.createTicket(
        requesterId: widget.currentUser.userId,
        categoryId: categoryId,
        subject: subject,
        description: description,
        priority: priority,
        assetId: assetId,
        ticketType: ticketType,
        patientName: _currentTab == 1 && _patientNameCtrl.text.trim().isNotEmpty
            ? _patientNameCtrl.text.trim()
            : null,
      );

      // Upload attachments
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Row(children: [Icon(Icons.check_circle_outline, color: Colors.white, size: 18), SizedBox(width: 8), Expanded(child: Text('Gửi yêu cầu thành công!'))]), backgroundColor: Color(0xFF43A047), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Có lỗi xảy ra, vui lòng thử lại!');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final screenW = MediaQuery.of(context).size.width;
    final dialogWidth = screenW > 900 ? 780.0 : screenW * 0.92;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth,
          constraints: BoxConstraints(maxHeight: screenH * 0.92),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                spreadRadius: -4,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: _activeColor.withValues(alpha: 0.08),
                blurRadius: 60,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(),
                _buildTabBar(),
                Flexible(
                  child: Form(
                    key: _formKey,
                    child: TabBarView(
                      controller: _tabCtrl,
                      children: [
                        _buildRepairTab(),
                        _buildReopenTab(),
                        _buildFeedbackTab(),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // HEADER — Clean gradient with user info
  // ═══════════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _activeColor,
            _activeColor.withValues(alpha: 0.85),
            Color.lerp(_activeColor, const Color(0xFF1E293B), 0.3)!,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
        child: Row(
          children: [
            // User avatar
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Text(
                  widget.currentUser.fullName[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Title block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tạo Yêu Cầu Mới',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded, size: 13, color: Colors.white.withValues(alpha: 0.8)),
                      const SizedBox(width: 4),
                      Text(
                        widget.currentUser.fullName,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      if (widget.currentUser.deptName != null) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.4), shape: BoxShape.circle)),
                        ),
                        Icon(Icons.apartment_rounded, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.currentUser.deptName!,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Close button
            Material(
              color: Colors.white.withValues(alpha: 0.12),
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB BAR — Pill-shaped segmented control
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          // ── TẠM ẨN: chỉ hiện tab Bệnh án ──
          children: [1].map((i) {
            final cfg = _tabConfigs[i];
            final selected = _currentTab == i;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  _tabCtrl.animateTo(i);
                  setState(() => _currentTab = i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: cfg.color.withValues(alpha: 0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        cfg.icon,
                        size: 16,
                        color: selected ? cfg.color : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        cfg.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? cfg.color : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // FOOTER — Submit button
  // ═══════════════════════════════════════════════════════════════
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          // File count indicator
          if (_pendingFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.attach_file_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(
                    '${_pendingFiles.length} file',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          const Spacer(),
          // Cancel
          TextButton(
            onPressed: _submitting ? null : () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF64748B),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
          const SizedBox(width: 10),
          // Submit
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: ElevatedButton(
              onPressed: _submitting ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: _activeColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _activeColor.withValues(alpha: 0.6),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_submitting)
                    const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  else
                    const Icon(Icons.send_rounded, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    _submitting ? 'Đang gửi...' : 'Gửi yêu cầu',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 1: SỬA CHỮA
  // ══════════════════════════════════════════════════════════════
  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _proposedDeadline ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: _activeColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _proposedDeadline = picked);
  }

  Widget _buildRepairTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Section: Thông tin người gửi ──
        _sectionHeader('Thông tin người gửi', Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _formCard(
          child: Builder(builder: (ctx) {
            final narrow = MediaQuery.of(ctx).size.width < 500;
            final nameField = _field('Họ và tên', required: true, child: TextFormField(
              controller: _nameCtrl,
              decoration: _deco('Nhập họ tên...', Icons.badge_outlined),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ));
            final phoneField = _field('Số điện thoại', required: true, child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco('SĐT...', Icons.phone_outlined),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ));
            final deptField = _field('Khoa / Phòng ban', child: TextFormField(
              initialValue: widget.currentUser.deptName ?? 'Không rõ',
              readOnly: true,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              decoration: _deco('', Icons.apartment_rounded).copyWith(fillColor: const Color(0xFFF1F5F9)),
            ));
            if (narrow) {
              return Column(children: [nameField, const SizedBox(height: 10), phoneField, const SizedBox(height: 10), deptField]);
            }
            return Row(children: [
              Expanded(flex: 3, child: nameField),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: phoneField),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: deptField),
            ]);
          }),
        ),

        const SizedBox(height: 18),

        // ── Section: Chi tiết yêu cầu ──
        _sectionHeader('Chi tiết yêu cầu', Icons.description_outlined),
        const SizedBox(height: 10),
        _formCard(
          child: Column(children: [
            _field('Chủ đề yêu cầu', required: true, child: TextFormField(
              controller: _subjectCtrl,
              decoration: _deco('Nhập tiêu đề ngắn gọn...', Icons.title_rounded),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            )),
            const SizedBox(height: 14),
            Builder(builder: (ctx) {
              final narrow = MediaQuery.of(ctx).size.width < 500;
              final catField = _field('Danh mục lỗi', required: true, child: _loadingOptions
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<Category>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: _deco('Chọn', Icons.category_outlined),
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.categoryName, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                  ),
              );
              final assetField = _field('Thiết bị liên quan', child: _loadingOptions
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<Asset>(
                    initialValue: _selectedAsset,
                    isExpanded: true,
                    decoration: _deco('Chọn', Icons.devices_rounded),
                    items: _assets.map((a) => DropdownMenuItem(value: a, child: Text(a.assetName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis))).toList(),
                    onChanged: (v) => setState(() => _selectedAsset = v),
                  ),
              );
              if (narrow) {
                return Column(children: [catField, const SizedBox(height: 10), assetField]);
              }
              return Row(children: [Expanded(child: catField), const SizedBox(width: 12), Expanded(child: assetField)]);
            }),
            const SizedBox(height: 14),
            Builder(builder: (ctx) {
              final narrow = MediaQuery.of(ctx).size.width < 500;
              final locField = _field('Vị trí', child: TextFormField(
                controller: _locationCtrl,
                decoration: _deco('VD: P.203 - Tầng 2...', Icons.location_on_outlined),
              ));
              final deadlineField = _field('Deadline mong muốn', child: GestureDetector(
                onTap: _pickDeadline,
                child: AbsorbPointer(
                  child: TextFormField(
                    decoration: _deco(
                      _proposedDeadline != null
                        ? '${_proposedDeadline!.day}/${_proposedDeadline!.month}/${_proposedDeadline!.year}'
                        : 'Chọn ngày...',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                ),
              ));
              if (narrow) {
                return Column(children: [locField, const SizedBox(height: 10), deadlineField]);
              }
              return Row(children: [Expanded(child: locField), const SizedBox(width: 12), Expanded(child: deadlineField)]);
            }),
          ]),
        ),

        const SizedBox(height: 18),

        // ── Section: Độ ưu tiên ──
        _sectionHeader('Độ ưu tiên', Icons.flag_outlined),
        const SizedBox(height: 10),
        _buildPrioritySelector(),

        const SizedBox(height: 18),

        // ── Section: Mô tả ──
        _sectionHeader('Mô tả chi tiết', Icons.notes_rounded),
        const SizedBox(height: 10),
        _formCard(
          child: TextFormField(
            controller: _descriptionCtrl,
            maxLines: 3,
            decoration: _deco('Mô tả chi tiết sự cố để IT hỗ trợ nhanh hơn...', null).copyWith(
              prefixIcon: null,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ── Attachments ──
        _buildAttachments(),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 2: MỞ LẠI BỆNH ÁN
  // ══════════════════════════════════════════════════════════════
  Widget _buildReopenTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Lưu ý: Bệnh án sẽ được đóng trong ngày, người dùng ghi rõ lí do và tích dòng ảnh hưởng đến tài chính (Nếu có).',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.amber.shade900,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        _sectionHeader('Thông tin người yêu cầu', Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _formCard(
          child: Builder(builder: (ctx) {
            final narrow = MediaQuery.of(ctx).size.width < 500;
            final nameField = _field('Họ tên', required: true, child: TextFormField(
              controller: _nameCtrl,
              decoration: _deco('Nhập họ tên...', Icons.badge_outlined),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ));
            final phoneField = _field('Số điện thoại', required: true, child: TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco('SĐT...', Icons.phone_outlined),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            ));
            final deptField = _field('Khoa / Phòng ban', child: TextFormField(
              initialValue: widget.currentUser.deptName ?? 'Không rõ',
              readOnly: true,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              decoration: _deco('', Icons.apartment_rounded).copyWith(fillColor: const Color(0xFFF1F5F9)),
            ));
            if (narrow) {
              return Column(children: [nameField, const SizedBox(height: 10), phoneField, const SizedBox(height: 10), deptField]);
            }
            return Row(children: [
              Expanded(flex: 3, child: nameField),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: phoneField),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: deptField),
            ]);
          }),
        ),

        const SizedBox(height: 18),

        _sectionHeader('Thông tin bệnh án', Icons.medical_information_outlined),
        const SizedBox(height: 10),
        _formCard(
          child: Column(children: [
            _field('Mã viện phí của bệnh nhân', required: true, child: TextFormField(
              controller: _medicalRecordCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _deco('Nhập mã viện phí của bệnh nhân...', Icons.numbers_rounded),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            )),
            const SizedBox(height: 14),
            _field('Tên bệnh nhân', required: false, child: TextFormField(
              controller: _patientNameCtrl,
              decoration: _deco('Nhập tên bệnh nhân...', Icons.personal_injury_outlined),
            )),
            const SizedBox(height: 14),
            _field('Lý do mở lại', required: true, child: TextFormField(
              controller: _reopenReasonCtrl,
              maxLines: 3,
              decoration: _deco('Mô tả lý do cần mở lại bệnh án...', null).copyWith(prefixIcon: null),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            )),
            const SizedBox(height: 14),
            // Finance toggle
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _affectsFinance ? _activeColor.withValues(alpha: 0.06) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _affectsFinance ? _activeColor.withValues(alpha: 0.3) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _affectsFinance ? _activeColor.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.monetization_on_outlined, size: 16,
                    color: _affectsFinance ? _activeColor : const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ảnh hưởng tài chính?',
                        style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: _affectsFinance ? _activeColor : const Color(0xFF334155),
                        ),
                      ),
                      Text(
                        'Đánh dấu nếu yêu cầu liên quan đến chi phí',
                        style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      ),
                    ],
                  ),
                ),
                Transform.scale(scale: 0.85, child: Switch(
                  value: _affectsFinance,
                  onChanged: (v) => setState(() => _affectsFinance = v),
                  activeThumbColor: _activeColor,
                  activeTrackColor: _activeColor.withValues(alpha: 0.3),
                )),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 18),
        _buildAttachments(),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // TAB 3: GÓP Ý
  // ══════════════════════════════════════════════════════════════
  Widget _buildFeedbackTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionHeader('Nội dung góp ý', Icons.lightbulb_outline_rounded),
        const SizedBox(height: 10),
        _formCard(
          child: Column(children: [
            _field('Chủ đề', required: true, child: TextFormField(
              controller: _feedbackSubjectCtrl,
              decoration: _deco('Nhập tiêu đề ngắn gọn...', Icons.title_rounded),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            )),
            const SizedBox(height: 14),
            _field('Nội dung chi tiết', required: true, child: TextFormField(
              controller: _feedbackDescCtrl,
              maxLines: 6,
              decoration: _deco('Mô tả chi tiết góp ý, đề xuất cải tiến...', null).copyWith(prefixIcon: null),
              validator: (v) => v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
            )),
          ]),
        ),

        const SizedBox(height: 18),

        // ── Gợi ý  ──
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _activeColor.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _activeColor.withValues(alpha: 0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.tips_and_updates_rounded, size: 18, color: _activeColor.withValues(alpha: 0.7)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mẹo gửi góp ý hiệu quả',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _activeColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '• Mô tả rõ vấn đề bạn gặp phải\n• Đề xuất hướng cải tiến cụ thể\n• Đính kèm ảnh minh họa nếu có',
                      style: TextStyle(fontSize: 11.5, color: Colors.grey[600], height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),
        _buildAttachments(),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ══════════════════════════════════════════════════════════════

  /// Priority selector with animated chips
  Widget _buildPrioritySelector() {
    const priorities = [
      (key: 'Low', label: 'Thấp', icon: Icons.keyboard_double_arrow_down_rounded, color: Color(0xFF0EA5E9)),
      (key: 'Medium', label: 'Trung bình', icon: Icons.drag_handle_rounded, color: Color(0xFFF59E0B)),
      (key: 'High', label: 'Cao', icon: Icons.keyboard_double_arrow_up_rounded, color: Color(0xFFEF4444)),
    ];

    return Row(
      children: priorities.map((p) {
        final selected = _priority == p.key;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _priority = p.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: selected ? p.color : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? p.color : const Color(0xFFE2E8F0),
                    width: selected ? 2 : 1.5,
                  ),
                  boxShadow: selected
                      ? [BoxShadow(color: p.color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                      : [],
                ),
                child: Column(
                  children: [
                    Icon(
                      p.icon,
                      size: 22,
                      color: selected ? Colors.white : p.color,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      p.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : p.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Section header with icon
  Widget _sectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: _activeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 14, color: _activeColor),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _activeColor,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  /// Form card container
  Widget _formCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  /// Attachments section
  Widget _buildAttachments() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionHeader('Đính kèm', Icons.attach_file_rounded),
      const SizedBox(height: 10),
      if (_pendingFiles.isNotEmpty) ...[
        SizedBox(
          height: 78,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _pendingFiles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final pf = _pendingFiles[i];
              final isImg = pf.mime.startsWith('image/');
              return Stack(clipBehavior: Clip.none, children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: isImg ? Colors.grey.shade100 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: isImg
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.memory(pf.bytes, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.insert_drive_file_rounded, color: _activeColor, size: 24),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(pf.name, style: const TextStyle(fontSize: 8, color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ]),
                ),
                Positioned(top: -5, right: -5, child: GestureDetector(
                  onTap: () => setState(() => _pendingFiles.removeAt(i)),
                  child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.close_rounded, size: 10, color: Colors.white),
                  ),
                )),
              ]);
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
      GestureDetector(
        onTap: _pickFiles,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _activeColor.withValues(alpha: 0.25),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _activeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.cloud_upload_outlined, size: 18, color: _activeColor),
            ),
            const SizedBox(height: 6),
            Text(
              'Chọn ảnh hoặc file đính kèm',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _activeColor),
              textAlign: TextAlign.center,
            ),
            Text(
              '(tối đa 5MB)',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ]),
        ),
      ),
    ]);
  }

  /// Field wrapper with label
  Widget _field(String label, {required Widget child, bool required = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(
        children: [
          Flexible(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)), overflow: TextOverflow.ellipsis)),
          if (required)
            const Text(' *', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
      const SizedBox(height: 6),
      child,
    ]);
  }

  /// Input decoration
  InputDecoration _deco(String hint, IconData? icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    prefixIcon: icon != null ? Icon(icon, size: 17, color: const Color(0xFF94A3B8)) : null,
    prefixIconConstraints: icon != null ? const BoxConstraints(minWidth: 42) : null,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _activeColor, width: 1.5)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2)),
  );
}
