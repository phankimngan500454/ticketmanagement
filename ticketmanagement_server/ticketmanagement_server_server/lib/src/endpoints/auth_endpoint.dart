import 'package:serverpod/serverpod.dart';
import 'package:bcrypt/bcrypt.dart';
import '../generated/protocol.dart';

/// Handles authentication: login, register, and user queries.
/// Access via `client.auth` on the Flutter client.
class AuthEndpoint extends Endpoint {
  /// Login with username + password. Returns AppUser on success.
  Future<AppUser?> login(
    Session session,
    String username,
    String password,
  ) async {
    final user = await AppUser.db.findFirstRow(
      session,
      where: (t) => t.username.equals(username),
    );
    if (user == null) return null;
    final valid = BCrypt.checkpw(password, user.passwordHash);
    if (!valid) return null;
    return user;
  }

  /// Get all users.
  Future<List<AppUser>> getUsers(Session session) async {
    return AppUser.db.find(session);
  }

  /// Get IT staff (roleId == 2).
  Future<List<AppUser>> getITStaff(Session session) async {
    return AppUser.db.find(
      session,
      where: (t) => t.roleId.equals(2),
    );
  }

  /// Register a new user.
  Future<AppUser?> register(
    Session session,
    String username,
    String password,
    String fullName,
    String? phone,
    int roleId,
    int? deptId,
    String? permissions,
  ) async {
    final existing = await AppUser.db.findFirstRow(
      session,
      where: (t) => t.username.equals(username),
    );
    if (existing != null) return null; // Username already taken

    final hash = BCrypt.hashpw(password, BCrypt.gensalt());
    final user = AppUser(
      username: username,
      passwordHash: hash,
      fullName: fullName,
      phone: phone,
      roleId: roleId,
      createdAt: DateTime.now().toUtc(),
      deptId: deptId,
      permissions: permissions,
    );
    return AppUser.db.insertRow(session, user);
  }

  /// Admin: update user profile (fullName, phone, roleId, deptId).
  Future<AppUser?> updateUser(
    Session session,
    int userId,
    String fullName,
    String? phone,
    int roleId,
    int? deptId,
    String? permissions,
  ) async {
    final user = await AppUser.db.findById(session, userId);
    if (user == null) return null;
    return AppUser.db.updateRow(
      session,
      user.copyWith(fullName: fullName, phone: phone, roleId: roleId, deptId: deptId, permissions: permissions),
    );
  }

  /// Admin: reset a user's password.
  Future<bool> resetPassword(Session session, int userId, String newPassword) async {
    final user = await AppUser.db.findById(session, userId);
    if (user == null) return false;
    final hash = BCrypt.hashpw(newPassword, BCrypt.gensalt());
    await AppUser.db.updateRow(session, user.copyWith(passwordHash: hash));
    return true;
  }

  /// Admin: delete a user account.
  Future<bool> deleteUser(Session session, int userId) async {
    final user = await AppUser.db.findById(session, userId);
    if (user == null) return false;
    await AppUser.db.deleteRow(session, user);
    return true;
  }

  /// Store the device's FCM token for push notifications.
  /// Called by the Flutter app after Firebase initializes.
  Future<void> updateFcmToken(Session session, int userId, String token) async {
    final user = await AppUser.db.findById(session, userId);
    if (user == null) return;
    await AppUser.db.updateRow(session, user.copyWith(fcmToken: token));
  }
}
