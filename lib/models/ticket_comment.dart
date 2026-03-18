class TicketComment {
  final int commentId;
  final int ticketId;
  final int userId;
  final String commentText;
  final DateTime createdAt;

  // Join field
  final String? authorName;
  final String? authorRole; // 'Admin' | 'IT' | 'Customer'

  const TicketComment({
    required this.commentId,
    required this.ticketId,
    required this.userId,
    required this.commentText,
    required this.createdAt,
    this.authorName,
    this.authorRole,
  });

  factory TicketComment.fromJson(Map<String, dynamic> json) {
    dynamic g(String c, String p) => json[c] ?? json[p];
    return TicketComment(
      commentId:   g('commentID', 'CommentID') as int? ?? 0,
      ticketId:    g('ticketID', 'TicketID') as int? ?? 0,
      userId:      g('userID', 'UserID') as int? ?? 0,
      commentText: g('commentText', 'CommentText') as String? ?? '',
      createdAt:   DateTime.tryParse(g('createdAt', 'CreatedAt') as String? ?? '') ?? DateTime.now(),
      // Backend trả fullName hoặc username, không có AuthorName
      authorName:  g('fullName', 'AuthorName') as String?
                   ?? g('username', 'Username') as String?,
      authorRole:  g('authorRole', 'AuthorRole') as String?,
    );
  }


  Map<String, dynamic> toJson() => {
        'CommentID': commentId,
        'TicketID': ticketId,
        'UserID': userId,
        'CommentText': commentText,
        'CreatedAt': createdAt.toIso8601String(),
      };
}
