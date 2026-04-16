import 'package:flutter/material.dart';

class RequestTypeSelector extends StatelessWidget {
  final String currentType;
  final ValueChanged<String> onTypeChanged;

  const RequestTypeSelector({
    super.key,
    required this.currentType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        key: 'repair',
        label: 'Sửa chữa',
        subtitle: 'Yêu cầu IT hỗ trợ sửa chữa thiết bị',
        icon: Icons.build_rounded,
        color: const Color(0xFF1976D2),
      ),
      (
        key: 'reopen_medical',
        label: 'Mở lại bệnh án',
        subtitle: 'Yêu cầu mở lại hồ sơ bệnh án',
        icon: Icons.folder_open_rounded,
        color: const Color.fromARGB(255, 148, 182, 234),
      ),
      (
        key: 'feedback',
        label: 'Góp ý M3',
        subtitle: 'Gửi góp ý, đề xuất cải tiến hệ thống',
        icon: Icons.feedback_rounded,
        color: const Color(0xFF00897B),
      ),
    ];

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
                  color: const Color(0xFF5C6BC0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.apps_rounded,
                  color: Color(0xFF5C6BC0),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Loại yêu cầu',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1C1C2E),
                ),
              ),
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
          ),
          const SizedBox(height: 14),
          ...options.map((opt) {
            final selected = currentType == opt.key;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GestureDetector(
                onTap: () {
                  if (!selected) {
                    onTypeChanged(opt.key);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? opt.color.withValues(alpha: 0.08)
                        : const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? opt.color : Colors.grey.shade200,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? opt.color.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          opt.icon,
                          color: selected ? opt.color : Colors.grey[500],
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? opt.color
                                    : const Color(0xFF1C1C2E),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt.subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? opt.color.withValues(alpha: 0.7)
                                    : Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: selected ? opt.color : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? opt.color : Colors.grey.shade400,
                            width: selected ? 0 : 2,
                          ),
                        ),
                        child: selected
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
