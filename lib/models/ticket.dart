/// Status: 'Open' | 'Pending' | 'Resolved' | 'Closed'
/// Priority: 'High' | 'Medium' | 'Low'
class Ticket {
  final int ticketId;
  final int requesterId;
  final int? assigneeId; // nullable — chưa phân công
  final int categoryId;
  final int? assetId; // nullable — không liên quan thiết bị
  final String subject;
  final String description;
  final String status;
  final String priority;
  final DateTime createdAt;
  final DateTime? proposedDeadline; // User đề xuất
  final DateTime? finalDeadline; // Admin quyết định
  final String? deadlineStatus; // null | 'Pending' | 'Approved' | 'Adjusted'

  // Join fields (được populate từ repository)
  final String? requesterName;
  final String? requesterPhone; // SĐT người tạo
  final String? assigneeName;
  final String? categoryName;
  final String? assetName;

  const Ticket({
    required this.ticketId,
    required this.requesterId,
    this.assigneeId,
    required this.categoryId,
    this.assetId,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.proposedDeadline,
    this.finalDeadline,
    this.deadlineStatus,
    this.requesterName,
    this.requesterPhone,
    this.assigneeName,
    this.categoryName,
    this.assetName,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Hỗ trợ 3 variant key: camelCase chuẩn (ticketId), backend (ticketID), PascalCase (TicketID)
    dynamic g(String camel, String camelCap, String pascal) =>
        json[camel] ?? json[camelCap] ?? json[pascal];

    final requesterName =
        (json['requester'] as Map<String, dynamic>?)?['fullName'] as String? ??
        g('requesterName', 'requesterName', 'RequesterName') as String?;
    final assigneeName =
        (json['assignee'] as Map<String, dynamic>?)?['fullName'] as String? ??
        g('assigneeName', 'assigneeName', 'AssigneeName') as String?;
    final categoryName =
        (json['category'] as Map<String, dynamic>?)?['categoryName'] as String? ??
        g('categoryName', 'categoryName', 'CategoryName') as String?;
    final createdAtRaw =
        (json['createdAt'] ?? json['CreatedAt']) as String? ?? '';

    // Helper int — tránh crash khi field null
    int? parseInt(dynamic v) => v == null ? null : (v as num).toInt();

    return Ticket(
      ticketId:     parseInt(g('ticketId', 'ticketID', 'TicketID'))     ?? 0,
      requesterId:  parseInt(g('requesterId', 'requesterID', 'RequesterID')) ?? 0,
      assigneeId:   parseInt(g('assigneeId', 'assigneeID', 'AssigneeID')),
      categoryId:   parseInt(g('categoryId', 'categoryID', 'CategoryID')) ?? 0,
      assetId:      parseInt(g('assetId', 'assetID', 'AssetID')),
      subject:      (json['subject']     ?? json['Subject'])     as String? ?? '',
      description:  (json['description'] ?? json['Description']) as String? ?? '',
      status:       (json['status']      ?? json['Status'])      as String? ?? 'Open',
      priority:     (json['priority']    ?? json['Priority'])    as String? ?? 'Low',
      createdAt: createdAtRaw.isNotEmpty
          ? DateTime.parse(createdAtRaw)
          : DateTime.now(),
      proposedDeadline: DateTime.tryParse(
        (json['proposedDeadline'] ?? json['ProposedDeadline'] ?? '') as String,
      ),
      finalDeadline: DateTime.tryParse(
        (json['finalDeadline'] ?? json['FinalDeadline'] ?? '') as String,
      ),
      deadlineStatus: (json['deadlineStatus'] ?? json['DeadlineStatus']) as String?,
      requesterName:  requesterName,
      requesterPhone: (json['requester'] as Map<String, dynamic>?)?['phone'] as String? ??
                      (json['requesterPhone'] ?? json['RequesterPhone']) as String?,
      assigneeName:   assigneeName,
      categoryName:   categoryName,
      assetName:      (json['assetName'] ?? json['AssetName']) as String?,
    );
  }


  Map<String, dynamic> toJson() => {
    'TicketID': ticketId,
    'RequesterID': requesterId,
    'AssigneeID': assigneeId,
    'CategoryID': categoryId,
    'AssetID': assetId,
    'Subject': subject,
    'Description': description,
    'Status': status,
    'Priority': priority,
    'CreatedAt': createdAt.toIso8601String(),
  };

  Ticket copyWith({
    int? assigneeId,
    String? assigneeName,
    String? status,
    DateTime? finalDeadline,
    String? deadlineStatus,
  }) => Ticket(
    ticketId: ticketId,
    requesterId: requesterId,
    assigneeId: assigneeId ?? this.assigneeId,
    categoryId: categoryId,
    assetId: assetId,
    subject: subject,
    description: description,
    status: status ?? this.status,
    priority: priority,
    createdAt: createdAt,
    proposedDeadline: proposedDeadline,
    finalDeadline:    finalDeadline ?? this.finalDeadline,
    deadlineStatus:   deadlineStatus ?? this.deadlineStatus,
    requesterName:    requesterName,
    requesterPhone:   requesterPhone ?? requesterPhone,
    assigneeName:     assigneeName ?? this.assigneeName,
    categoryName:     categoryName,
    assetName:        assetName,
  );
}
