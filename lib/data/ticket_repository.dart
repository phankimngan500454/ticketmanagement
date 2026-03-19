// ignore_for_file: avoid_print
// ============================================================
//  ticket_repository.dart
//  Singleton facade — tổng hợp tất cả sub-repositories
//
//  Toàn bộ màn hình dùng: TicketRepository.instance.xxx()
//  KHÔNG cần thay đổi bất kỳ import nào trong các screen.
//
//  Chi tiết từng nhóm chức năng:
//    lib/data/repository_base.dart         — Cache + Mappers
//    lib/data/auth_repository.dart         — Đăng nhập / Người dùng
//    lib/data/ticket_crud_repository.dart  — Ticket CRUD + Status
//    lib/data/deadline_repository.dart     — Deadline
//    lib/data/comment_repository.dart      — Bình luận / Chat
//    lib/data/attachment_repository.dart   — File đính kèm
//    lib/data/reference_repository.dart    — Category / Asset / Dept / EmContact
// ============================================================

export 'auth_repository.dart';
export 'ticket_crud_repository.dart';
export 'deadline_repository.dart';
export 'comment_repository.dart';
export 'attachment_repository.dart';
export 'reference_repository.dart';

import 'repository_base.dart';
import 'auth_repository.dart';
import 'ticket_crud_repository.dart';
import 'deadline_repository.dart';
import 'comment_repository.dart';
import 'attachment_repository.dart';
import 'reference_repository.dart';

class TicketRepository extends RepositoryBase
    with
        AuthRepository,
        TicketCrudRepository,
        DeadlineRepository,
        CommentRepository,
        AttachmentRepository,
        ReferenceRepository {
  TicketRepository._();
  static final TicketRepository instance = TicketRepository._();
}
