import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/ticket_repository.dart';
import '../../models/category.dart';
import '../../models/asset.dart';
import '../../models/user.dart';

class CreateTicketScreen extends StatefulWidget {
  final User currentUser;
  final bool isEmergency;
  const CreateTicketScreen({Key? key, required this.currentUser, this.isEmergency = false}) : super(key: key);

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = TicketRepository.instance;

  final _subjectController     = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  List<Category> _categories = [];
  List<Asset>    _assets     = [];
  bool _loadingOptions = true;
  bool _submitting     = false;
  bool _editingInfo    = false;

  Category? _selectedCategory;
  Asset?    _selectedAsset;
  String    _priority         = 'Medium';
  DateTime? _proposedDeadline;

  @override
  void initState() {
    super.initState();
    _nameController  = TextEditingController(text: widget.currentUser.fullName);
    _phoneController = TextEditingController(text: widget.currentUser.phone);
    if (widget.isEmergency) _priority = 'High';
    _loadOptions();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final categories = await _repo.getCategories();
    final assets     = await _repo.getAssets();
    if (mounted) setState(() {
      _categories     = categories;
      _assets         = assets;
      _loadingOptions = false;
    });
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
    if (_selectedCategory == null) { _showError('Vui lòng chọn Danh mục lỗi!'); return; }
    setState(() => _submitting = true);
    try {
      // Bước 1: Tạo ticket
      final newTicket = await _repo.createTicket(
        requesterId:   widget.currentUser.userId,
        categoryId:    _selectedCategory!.categoryId,
        subject:       _subjectController.text.trim(),
        description:   _descriptionController.text.trim(),
        priority:      _priority,
        assetId:       _selectedAsset?.assetId,
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
          // Ticket đã tạo thành công, chỉ deadline fail → cảnh báo nhẹ
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('⚠️ Ticket đã tạo nhưng không gửi được deadline: $e'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ));
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('✅ Gửi yêu cầu thành công!'),
          backgroundColor: Color(0xFF43A047),
          behavior: SnackBarBehavior.floating,
        ));
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Có lỗi xảy ra: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }


  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── FORMAT DATE ──────────────────────────────────────────────
  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: Column(children: [
        // ── Header ────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
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
                const Expanded(child: Text('Tạo Yêu Cầu Mới',
                    style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              child: Row(children: [
                CircleAvatar(radius: 20,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: widget.isEmergency
                        ? const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20)
                        : Text(widget.currentUser.fullName[0],
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.currentUser.fullName,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(widget.currentUser.role,
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    widget.isEmergency ? '🚨 Khẩn cấp' : 'Yêu cầu mới',
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
                ),
              ]),
            ),
          ])),
        ),

        // ── Body ──────────────────────────────────────────────
        Expanded(
          child: _loadingOptions
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF1976D2)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  child: Form(
                    key: _formKey,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                      // ── 1. Thông tin người gửi ───────────────
                      _buildCard(
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
                                  : const Color(0xFF5C6BC0).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(
                                _editingInfo ? Icons.check_rounded : Icons.edit_outlined,
                                size: 13,
                                color: _editingInfo ? Colors.white : const Color(0xFF5C6BC0),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _editingInfo ? 'Xong' : 'Chỉnh sửa',
                                style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600,
                                  color: _editingInfo ? Colors.white : const Color(0xFF5C6BC0),
                                ),
                              ),
                            ]),
                          ),
                        ),
                        child: Column(children: [
                          _infoField(label: 'Họ và tên', icon: Icons.badge_outlined,
                              controller: _nameController, enabled: _editingInfo),
                          const SizedBox(height: 10),
                          _infoField(label: 'Số điện thoại', icon: Icons.phone_outlined,
                              controller: _phoneController, enabled: _editingInfo,
                              keyboard: TextInputType.phone),
                        ]),
                      ),
                      const SizedBox(height: 14),

                      // ── 2. Chủ đề ────────────────────────────
                      _buildCard(
                        icon: Icons.title_rounded,
                        iconColor: const Color(0xFF1976D2),
                        label: 'Chủ đề yêu cầu',
                        required: true,
                        child: TextFormField(
                          controller: _subjectController,
                          decoration: _inputDecoration('Nhập tiêu đề ngắn gọn cho sự cố...'),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E)),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Vui lòng nhập chủ đề' : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── 3. Danh mục ──────────────────────────
                      _buildCard(
                        icon: Icons.category_rounded,
                        iconColor: const Color(0xFF7B1FA2),
                        label: 'Danh mục lỗi',
                        required: true,
                        child: DropdownButtonFormField<Category>(
                          value: _selectedCategory,
                          hint: Text('Chọn danh mục lỗi',
                              style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                          decoration: _inputDecoration(''),
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF7B1FA2)),
                          items: _categories.map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat.categoryName, style: const TextStyle(fontSize: 14)),
                          )).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val),
                          validator: (v) => v == null ? 'Vui lòng chọn danh mục' : null,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── 4. Độ ưu tiên ────────────────────────
                      if (widget.isEmergency)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: const Color(0xFFE53935).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.flag_rounded, color: Color(0xFFE53935), size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text('Độ ưu tiên', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E))),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFE53935), borderRadius: BorderRadius.circular(10)),
                              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.keyboard_double_arrow_up, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('CAO', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                SizedBox(width: 6),
                                Icon(Icons.lock_outline, size: 12, color: Colors.white70),
                              ]),
                            ),
                          ]),
                        )
                      else
                        _buildCard(
                          icon: Icons.flag_rounded,
                          iconColor: const Color(0xFFE53935),
                          label: 'Độ ưu tiên',
                          required: true,
                          child: Row(
                            children: ['Low', 'Medium'].map((p) {
                              final selected = _priority == p;
                              final color = p == 'Medium' ? const Color(0xFFFB8C00)
                                  : const Color(0xFF29B6F6);
                              return Expanded(child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: GestureDetector(
                                  onTap: () => setState(() => _priority = p),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: selected ? color : color.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: selected ? color : color.withOpacity(0.3), width: 1.5),
                                    ),
                                    child: Column(children: [
                                      Icon(
                                        p == 'Medium' ? Icons.drag_handle
                                            : Icons.keyboard_double_arrow_down,
                                        size: 18,
                                        color: selected ? Colors.white : color,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        p == 'Medium' ? 'Trung bình' : 'Thấp',
                                        style: TextStyle(
                                          fontSize: 11, fontWeight: FontWeight.bold,
                                          color: selected ? Colors.white : color,
                                        ),
                                      ),
                                    ]),
                                  ),
                                ),
                              ));
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 14),

                      // ── 5. Hạn xử lý (ProposedDeadline) ──────
                      _buildCard(
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
                            child: Row(children: [
                              Icon(Icons.event_rounded, size: 18,
                                  color: _proposedDeadline != null
                                      ? const Color(0xFF00838F)
                                      : Colors.grey[400]),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
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
                                      child: Row(children: [
                                        Icon(Icons.hourglass_top_rounded,
                                            size: 11, color: Colors.orange[600]),
                                        const SizedBox(width: 3),
                                        Text('Đang chờ Admin phê duyệt',
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.orange[600],
                                                fontWeight: FontWeight.w500)),
                                      ]),
                                    ),
                                ],
                              )),
                              if (_proposedDeadline != null)
                                GestureDetector(
                                  onTap: () => setState(() => _proposedDeadline = null),
                                  child: Icon(Icons.close_rounded, size: 16, color: Colors.grey[400]),
                                ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── 6. Thiết bị (nếu có) ──────────────────
                      if (_assets.isNotEmpty) ...[
                        _buildCard(
                          icon: Icons.devices_rounded,
                          iconColor: const Color(0xFF6D4C41),
                          label: 'Thiết bị liên quan',
                          badge: 'TÙY CHỌN',
                          child: DropdownButtonFormField<Asset?>(
                            value: _selectedAsset,
                            hint: Text('Không liên quan đến thiết bị cụ thể',
                                style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                            decoration: _inputDecoration(''),
                            dropdownColor: Colors.white,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF6D4C41)),
                            items: [
                              DropdownMenuItem<Asset?>(
                                  value: null,
                                  child: Text('-- Không chọn --',
                                      style: TextStyle(color: Colors.grey[500], fontSize: 14))),
                              ..._assets.map((a) => DropdownMenuItem<Asset?>(
                                value: a,
                                child: Text('${a.assetName}  (${a.assetCode})',
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              )),
                            ],
                            onChanged: (val) => setState(() => _selectedAsset = val),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // ── 7. Mô tả ─────────────────────────────
                      _buildCard(
                        icon: Icons.description_outlined,
                        iconColor: const Color(0xFF1A237E),
                        label: 'Mô tả chi tiết',
                        required: true,
                        child: TextFormField(
                          controller: _descriptionController,
                          maxLines: 5,
                          decoration: _inputDecoration('Mô tả rõ sự cố gặp phải...'),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E), height: 1.5),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vui lòng nhập mô tả chi tiết' : null,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Submit ───────────────────────────────
                      Container(
                        width: double.infinity, height: 54,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)]),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(
                              color: const Color(0xFF1976D2).withOpacity(0.4),
                              blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _submitting ? null : _submitForm,
                          icon: _submitting
                              ? const SizedBox(height: 18, width: 18,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          label: Text(
                            _submitting ? 'Đang gửi...' : 'GỬI YÊU CẦU',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold,
                                color: Colors.white, letterSpacing: 1.2),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
        ),
      ]),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────

  Widget _buildCard({
    required IconData icon, required Color iconColor, required String label,
    required Widget child, bool required = false, String? badge, Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05), blurRadius: 8,
            offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1C1C2E))),
          if (required) ...[
            const SizedBox(width: 4),
            const Text('*', style: TextStyle(
                color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
          if (badge != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
              child: Text(badge, style: TextStyle(
                  fontSize: 9, color: Colors.grey[500], fontWeight: FontWeight.bold)),
            ),
          ],
          if (trailing != null) ...[const Spacer(), trailing],
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );
  }

  Widget _infoField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool enabled = false,
    TextInputType keyboard = TextInputType.text,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      TextField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboard,
        inputFormatters: keyboard == TextInputType.phone
            ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: const TextStyle(fontSize: 14, color: Color(0xFF1C1C2E)),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 16,
              color: enabled ? const Color(0xFF5C6BC0) : Colors.grey[400]),
          filled: true,
          fillColor: enabled ? const Color(0xFFF3F4FF) : const Color(0xFFF8F9FF),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: enabled
                      ? const Color(0xFF5C6BC0).withOpacity(0.4)
                      : Colors.grey.shade200)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                  color: Color(0xFF5C6BC0), width: 1.5)),
        ),
      ),
    ]);
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
    filled: true, fillColor: const Color(0xFFF8F9FF),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade200)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5)),
  );
}
