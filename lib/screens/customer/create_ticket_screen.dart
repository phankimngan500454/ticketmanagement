import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/ticket_repository.dart';
import '../../models/category.dart';
import '../../models/asset.dart';
import '../../models/user.dart';
import 'create_reopen_medical_screen.dart';
import 'create_feedback_screen.dart';
import 'widgets/request_type_selector.dart';

class CreateTicketScreen extends StatefulWidget {
  final User currentUser;
  final bool isEmergency;
  const CreateTicketScreen({
    super.key,
    required this.currentUser,
    this.isEmergency = false,
  });

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  // String _requestType = 'repair'; // <- Gốc
  String _requestType =
      'reopen_medical'; // Dùng tạm tĩnh cho reopen_medical để test

  @override
  Widget build(BuildContext context) {
    /* 
    // --- CODE GỐC (TẠM ẨN ĐỂ TEST LUỒNG MỞ BỆNH ÁN) ---
    int currentIndex = _requestType == 'reopen_medical' ? 1 : _requestType == 'feedback' ? 2 : 0;
    
    return IndexedStack(
      index: currentIndex,
      children: [
        CreateRepairScreen(
          currentUser: widget.currentUser,
          isEmergency: widget.isEmergency,
          onTypeChanged: (t) => setState(() => _requestType = t),
        ),
        CreateReopenMedicalScreen(
          currentUser: widget.currentUser,
          onTypeChanged: (t) => setState(() => _requestType = t),
        ),
        CreateFeedbackScreen(
          currentUser: widget.currentUser,
          onTypeChanged: (t) => setState(() => _requestType = t),
        ),
      ],
    );
    */

    // Chỉ render màn hình Mở lại bệnh án để test luồng
    return CreateReopenMedicalScreen(
      currentUser: widget.currentUser,
      onTypeChanged: (t) => setState(() => _requestType = t),
    );
  }
}

class CreateRepairScreen extends StatefulWidget {
  final User currentUser;
  final bool isEmergency;
  final ValueChanged<String> onTypeChanged;
  const CreateRepairScreen({
    super.key,
    required this.currentUser,
    required this.onTypeChanged,
    this.isEmergency = false,
  });

  @override
  State<CreateRepairScreen> createState() => _CreateRepairScreenState();
}

class _CreateRepairScreenState extends State<CreateRepairScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TicketRepository.instance;

  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController
  _locationController; // Số phòng / vị trí cụ thể

  // Pending attachments (picked before submit)
  final List<({String name, String mime, Uint8List bytes})> _pendingFiles = [];

  List<Category> _categories = [];
  List<Asset> _assets = [];
  bool _loadingOptions = true;
  bool _submitting = false;
  bool _editingInfo = false;

  Category? _selectedCategory;
  Asset? _selectedAsset;
  String _priority = 'Medium';
  DateTime? _proposedDeadline;
  String? _selectedAssetType; // lọc theo loại thiết bị

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.fullName);
    _phoneController = TextEditingController(text: widget.currentUser.phone);
    _locationController = TextEditingController();
    if (widget.isEmergency) _priority = 'High';
    _loadOptions();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final categories = await _repo.getCategories();
    final rawAssets = await _repo.getAssets();
    // Deduplicate by assetId (prevents DropdownButton assertion if DB has duplicate rows)
    final seen = <int>{};
    final assets = rawAssets.where((a) => seen.add(a.assetId)).toList();
    if (mounted) {
      setState(() {
        _categories = categories;
        _assets = assets;
        _loadingOptions = false;
      });
    }
  }

  // ── Pick image/file attachments ─────────────────────────────
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
              content: Text('⚠️ ${f.name} vượt quá 5MB, bỏ qua'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        continue;
      }
      final ext = (f.extension ?? 'bin').toLowerCase();
      String mime = 'application/octet-stream';
      if (['jpg', 'jpeg'].contains(ext)) {
        mime = 'image/jpeg';
      } else if (ext == 'png') {
        mime = 'image/png';
      } else if (ext == 'gif') {
        mime = 'image/gif';
      } else if (ext == 'webp') {
        mime = 'image/webp';
      } else if (ext == 'pdf') {
        mime = 'application/pdf';
      } else if (['doc', 'docx'].contains(ext)) {
        mime = 'application/msword';
      }
      setState(
        () => _pendingFiles.add((name: f.name, mime: mime, bytes: f.bytes!)),
      );
    }
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _proposedDeadline ?? now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF1976D2)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _proposedDeadline = picked);
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showError('Vui lòng chọn Danh mục lỗi!');
      return;
    }
    setState(() => _submitting = true);
    try {
      final finalSubject = _subjectController.text.trim();
      final finalDescription = [
        if (_locationController.text.trim().isNotEmpty)
          '📍 Vị trí: ${_locationController.text.trim()}',
        _descriptionController.text.trim(),
      ].join('\n\n');

      // Bước 1: Tạo ticket
      final newTicket = await _repo.createTicket(
        requesterId: widget.currentUser.userId,
        categoryId: _selectedCategory!.categoryId,
        subject: finalSubject,
        description: finalDescription,
        priority: _priority,
        assetId: _selectedAsset?.assetId,
        ticketType: 'ticket',
      );

      // Bước 2: Nếu có deadline → gọi riêng propose-deadline
      if (_proposedDeadline != null) {
        try {
          await _repo.proposeDeadline(
            newTicket.ticketId,
            widget.currentUser.userId,
            _proposedDeadline!,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '⚠️ Ticket đã tạo nhưng gặp lỗi gửi đề xuất',
                ),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }

      // Bước 3: Upload ảnh/file đính kèm (nếu có)
      if (_pendingFiles.isNotEmpty) {
        int successCount = 0;
        final List<String> failedNames = [];
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
            successCount++;
          } catch (e) {
            failedNames.add(pf.name);
          }
        }
        if (mounted && failedNames.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⚠️ $successCount/${_pendingFiles.length} file đã upload. Lỗi: ${failedNames.join(', ')}',
              ),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Gửi yêu cầu thành công!'),
            backgroundColor: Color(0xFF43A047),
            behavior: SnackBarBehavior.floating,
          ),
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
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── FORMAT DATE ──────────────────────────────────────────────
  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
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
                            'Tạo Yêu Cầu Mới',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
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
                          child: widget.isEmergency
                              ? const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Text(
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '🔧 Sửa chữa',
                            style: TextStyle(fontSize: 11, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────
          Expanded(
            child: _loadingOptions
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1976D2)),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth > 700;
                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          isWide ? 32 : 16,
                          16,
                          isWide ? 32 : 16,
                          32,
                        ),
                        child: Form(
                          key: _formKey,
                          child: isWide
                              ? _buildDesktopLayout()
                              : _buildMobileLayout(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ── Desktop 2-column layout ──────────────────────────────────────
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RequestTypeSelector(
                currentType: 'repair',
                onTypeChanged: widget.onTypeChanged,
              ),
              const SizedBox(height: 14),
              _buildSenderInfoCard(),
              const SizedBox(height: 14),
              _buildCategoryAssetCard(),
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right column
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubjectCard(),
              const SizedBox(height: 14),
              _buildPriorityCard(),
              const SizedBox(height: 14),
              _buildDeadlineCard(),
              const SizedBox(height: 14),
              _buildDescriptionCard(),
              const SizedBox(height: 14),
              _buildAttachmentCard(),
              const SizedBox(height: 14),
              _buildSubmitButton(),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mobile single-column layout ──────────────────────────────────
  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequestTypeSelector(
          currentType: 'repair',
          onTypeChanged: widget.onTypeChanged,
        ),
        const SizedBox(height: 14),
        _buildSenderInfoCard(),
        const SizedBox(height: 14),
        _buildSubjectCard(),
        const SizedBox(height: 14),
        _buildCategoryAssetCard(),
        const SizedBox(height: 14),
        _buildPriorityCard(),
        const SizedBox(height: 14),
        _buildDeadlineCard(),
        const SizedBox(height: 14),
        _buildDescriptionCard(),
        const SizedBox(height: 14),
        _buildAttachmentCard(),
        const SizedBox(height: 14),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildSenderInfoCard() {
    return _buildCard(
      icon: Icons.person_outline_rounded,
      iconColor: const Color(0xFF5C6BC0),
      label: 'Thông tin người gửi',
      trailing: GestureDetector(
        onTap: () => setState(() => _editingInfo = !_editingInfo),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _editingInfo
                ? const Color(0xFF5C6BC0)
                : const Color(0xFF5C6BC0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _editingInfo ? Icons.check_rounded : Icons.edit_outlined,
                size: 13,
                color: _editingInfo ? Colors.white : const Color(0xFF5C6BC0),
              ),
              const SizedBox(width: 4),
              Text(
                _editingInfo ? 'Xong' : 'Chỉnh sửa',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _editingInfo ? Colors.white : const Color(0xFF5C6BC0),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        children: [
          _infoField(
            label: 'Họ và tên',
            icon: Icons.badge_outlined,
            controller: _nameController,
            enabled: _editingInfo,
          ),
          const SizedBox(height: 10),
          _infoField(
            label: 'Số điện thoại',
            icon: Icons.phone_outlined,
            controller: _phoneController,
            enabled: _editingInfo,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Số phòng / Vị trí cụ thể',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _locationController,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E)),
                decoration: InputDecoration(
                  hintText: 'VD: P.203 - Tầng 2, Dãy A...',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                  prefixIcon: const Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: Color(0xFF5C6BC0),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FF),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF5C6BC0),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'IT sẽ dùng vị trí này để đến hỗ trợ trực tiếp',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard() => _buildCard(
    icon: Icons.title_rounded,
    iconColor: const Color(0xFF1976D2),
    label: 'Chủ đề yêu cầu',
    required: true,
    child: TextFormField(
      controller: _subjectController,
      decoration: _inputDecoration('Nhập tiêu đề ngắn gọn cho sự cố...'),
      style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E)),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Vui lòng nhập chủ đề' : null,
    ),
  );

  Widget _buildPriorityCard() {
    if (widget.isEmergency) {
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.flag_rounded,
                color: Color(0xFFE53935),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Độ ưu tiên',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1C1C2E),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.keyboard_double_arrow_up,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'CAO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.lock_outline, size: 12, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return _buildCard(
      icon: Icons.flag_rounded,
      iconColor: const Color(0xFFE53935),
      label: 'Độ ưu tiên',
      required: true,
      child: Row(
        children: ['Low', 'Medium', 'High'].map((p) {
          final selected = _priority == p;
          final color = p == 'High'
              ? const Color(0xFFE53935)
              : p == 'Medium'
              ? const Color(0xFFFB8C00)
              : const Color(0xFF29B6F6);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: GestureDetector(
                onTap: () => setState(() => _priority = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? color : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? color : color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        p == 'High'
                            ? Icons.keyboard_double_arrow_up
                            : p == 'Medium'
                            ? Icons.drag_handle
                            : Icons.keyboard_double_arrow_down,
                        size: 18,
                        color: selected ? Colors.white : color,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p == 'High'
                            ? 'Cao'
                            : p == 'Medium'
                            ? 'Trung bình'
                            : 'Thấp',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: selected ? Colors.white : color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDeadlineCard() => _buildCard(
    icon: Icons.calendar_today_rounded,
    iconColor: const Color(0xFF00838F),
    label: 'Hạn mong muốn',
    badge: 'TÙY CHỌN',
    child: GestureDetector(
      onTap: _pickDeadline,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _proposedDeadline != null
                ? const Color(0xFF00838F)
                : Colors.grey.shade200,
            width: _proposedDeadline != null ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.event_rounded,
              size: 18,
              color: _proposedDeadline != null
                  ? const Color(0xFF00838F)
                  : Colors.grey[400],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _proposedDeadline != null
                        ? _fmt(_proposedDeadline!)
                        : 'Chọn ngày bạn mong muốn...',
                    style: TextStyle(
                      fontSize: 14,
                      color: _proposedDeadline != null
                          ? const Color(0xFF1C1C2E)
                          : Colors.grey[400],
                    ),
                  ),
                  if (_proposedDeadline != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Row(
                        children: [
                          Icon(
                            Icons.hourglass_top_rounded,
                            size: 11,
                            color: Colors.orange[600],
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Đang chờ Admin phê duyệt',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.orange[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            if (_proposedDeadline != null)
              GestureDetector(
                onTap: () => setState(() => _proposedDeadline = null),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _buildDescriptionCard() => _buildCard(
    icon: Icons.description_outlined,
    iconColor: const Color(0xFF1A237E),
    label: 'Mô tả chi tiết',
    required: true,
    child: TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: _inputDecoration('Mô tả rõ sự cố gặp phải...'),
      style: const TextStyle(
        fontSize: 14,
        color: Color(0xFF1C1C2E),
        height: 1.5,
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? 'Vui lòng nhập mô tả chi tiết' : null,
    ),
  );

  Widget _buildAttachmentCard() => _buildCard(
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
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFF1C1C2E),
                                    ),
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
              color: const Color(0xFF00897B).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF00897B).withValues(alpha: 0.3),
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.add_photo_alternate_rounded,
                  size: 28,
                  color: Color(0xFF00897B),
                ),
                SizedBox(height: 6),
                Text(
                  'Chọn ảnh hoặc file',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF00897B),
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

  // Removed inline selector as we use the shared RequestTypeSelector now.

  Widget _buildSubmitButton() => Container(
    width: double.infinity,
    height: 54,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1976D2).withValues(alpha: 0.4),
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

  // ── Helpers ────────────────────────────────────────────────────

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget child,
    bool required = false,
    String? badge,
    Widget? trailing,
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
              if (required) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
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
              if (trailing != null) ...[const Spacer(), trailing],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _infoField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[500],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboard,
          inputFormatters: keyboard == TextInputType.phone
              ? [FilteringTextInputFormatter.digitsOnly]
              : null,
          style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E)),
          decoration: InputDecoration(
            prefixIcon: Icon(
              icon,
              size: 16,
              color: enabled ? const Color(0xFF5C6BC0) : Colors.grey[400],
            ),
            filled: true,
            fillColor: enabled
                ? const Color(0xFFF3F4FF)
                : const Color(0xFFF8F9FF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: enabled
                    ? const Color(0xFF5C6BC0).withValues(alpha: 0.4)
                    : Colors.grey.shade200,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF5C6BC0),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    filled: true,
    fillColor: const Color(0xFFF8F9FF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.redAccent),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
    ),
  );

  // ── Combined Category + Asset card ──────────────────────────────────────
  Widget _buildCategoryAssetCard() {
    const purple = Color(0xFF00897B);
    const brown = Color(0xFF6D4C41);
    final filteredAssets = _selectedCategory == null
        ? _assets
        : _assets
              .where(
                (a) =>
                    a.categoryId == _selectedCategory!.categoryId ||
                    a.categoryId == null,
              )
              .toList();

    return Container(
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
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.category_rounded,
                    color: purple,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 9),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Phân loại yêu cầu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C2E),
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(
                          '*',
                          style: TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Chọn danh mục → thiết bị liên quan',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, indent: 16, endIndent: 16),

          // Bước 1: Danh mục
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: purple,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Danh mục lỗi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: _categories.isEmpty
                ? Text(
                    'Không có danh mục',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((cat) {
                      final sel =
                          _selectedCategory?.categoryId == cat.categoryId;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = sel ? null : cat;
                          _selectedAsset = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: sel ? purple : const Color(0xFFF5F0FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: sel ? purple : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                sel
                                    ? Icons.check_circle_rounded
                                    : Icons.circle_outlined,
                                size: 14,
                                color: sel ? Colors.white : purple,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat.categoryName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: sel
                                      ? Colors.white
                                      : const Color(0xFF00695C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          // Bước 2: Thiết bị
          if (_assets.isNotEmpty) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _selectedCategory != null
                          ? brown
                          : Colors.grey.shade300,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '2',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Thiết bị liên quan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _selectedCategory != null
                          ? const Color(0xFF424242)
                          : Colors.grey[400],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      'TÙY CHỌN',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
              child: _selectedCategory == null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 15,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Chọn danh mục trước để lọc thiết bị',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : filteredAssets.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.devices_outlined,
                            size: 15,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Không có thiết bị trong danh mục này',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildAssetPicker(filteredAssets),
            ),
          ],
        ],
      ),
    );
  }

  // ── Asset picker: chip lọc loại + card list ─────────────────────
  Widget _buildAssetPicker(List<Asset> assets) {
    const brown = Color(0xFF6D4C41);

    // Lấy danh sách loại duy nhất, sắp xếp theo tên
    final types = assets.map((a) => a.assetType).toSet().toList()..sort();

    // Icon theo loại thiết bị
    IconData typeIcon(String t) {
      final lower = t.toLowerCase();
      if (lower.contains('laptop') || lower.contains('máy tính'))
        return Icons.laptop_rounded;
      if (lower.contains('máy in')) return Icons.print_rounded;
      if (lower.contains('màn hình')) return Icons.monitor_rounded;
      if (lower.contains('switch') ||
          lower.contains('router') ||
          lower.contains('wifi') ||
          lower.contains('mạng'))
        return Icons.router_rounded;
      if (lower.contains('máy chủ') || lower.contains('server'))
        return Icons.dns_rounded;
      if (lower.contains('tablet') || lower.contains('điện thoại'))
        return Icons.tablet_android_rounded;
      if (lower.contains('camera')) return Icons.videocam_rounded;
      if (lower.contains('ups') || lower.contains('điện'))
        return Icons.electrical_services_rounded;
      if (lower.contains('y tế') ||
          lower.contains('siêu âm') ||
          lower.contains('ecg') ||
          lower.contains('x-quang'))
        return Icons.medical_services_rounded;
      return Icons.devices_other_rounded;
    }

    // Filter theo loại đã chọn
    final displayed = _selectedAssetType == null
        ? assets
        : assets.where((a) => a.assetType == _selectedAssetType).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Chip lọc loại thiết bị ─────────────────────────────
        if (types.length > 1) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Chip "Tất cả"
                GestureDetector(
                  onTap: () => setState(() {
                    _selectedAssetType = null;
                    _selectedAsset = null;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 8, bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedAssetType == null
                          ? brown
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _selectedAssetType == null
                            ? brown
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apps_rounded,
                          size: 13,
                          color: _selectedAssetType == null
                              ? Colors.white
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Tất cả (${assets.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _selectedAssetType == null
                                ? Colors.white
                                : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Chip từng loại
                ...types.map((t) {
                  final selected = _selectedAssetType == t;
                  final count = assets.where((a) => a.assetType == t).length;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedAssetType = selected ? null : t;
                      _selectedAsset = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8, bottom: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? brown : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? brown : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            typeIcon(t),
                            size: 13,
                            color: selected ? Colors.white : Colors.grey[600],
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$t ($count)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // ── Nút "Không chọn thiết bị" ─────────────────────────
        GestureDetector(
          onTap: () => setState(() => _selectedAsset = null),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _selectedAsset == null
                  ? brown.withValues(alpha: 0.08)
                  : Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _selectedAsset == null ? brown : Colors.grey.shade200,
                width: _selectedAsset == null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.not_interested_rounded,
                  size: 15,
                  color: _selectedAsset == null ? brown : Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Text(
                  '-- Không chọn thiết bị --',
                  style: TextStyle(
                    fontSize: 13,
                    color: _selectedAsset == null ? brown : Colors.grey[500],
                    fontWeight: _selectedAsset == null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
                if (_selectedAsset == null) ...[
                  const Spacer(),
                  Icon(Icons.check_circle_rounded, size: 16, color: brown),
                ],
              ],
            ),
          ),
        ),

        // ── Danh sách thiết bị dạng card ──────────────────────
        ...displayed.map((a) {
          final sel = _selectedAsset?.assetId == a.assetId;
          return GestureDetector(
            onTap: () => setState(() => _selectedAsset = sel ? null : a),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: BoxDecoration(
                color: sel ? brown.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? brown : Colors.grey.shade200,
                  width: sel ? 1.5 : 1,
                ),
                boxShadow: sel
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  // Icon loại
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: sel
                          ? brown.withValues(alpha: 0.12)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      typeIcon(a.assetType),
                      size: 16,
                      color: sel ? brown : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.assetName == '(Chưa xác định)' ||
                                  a.assetName.isEmpty
                              ? a.assetType
                              : a.assetName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: sel ? brown : const Color(0xFF1C1C2E),
                          ),
                        ),
                        if (a.assetName != '(Chưa xác định)' &&
                            a.assetName.isNotEmpty)
                          Text(
                            a.assetType,
                            style: TextStyle(
                              fontSize: 11,
                              color: sel
                                  ? brown.withValues(alpha: 0.7)
                                  : Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (sel)
                    Icon(Icons.check_circle_rounded, size: 20, color: brown)
                  else
                    Icon(
                      Icons.circle_outlined,
                      size: 20,
                      color: Colors.grey[300],
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
