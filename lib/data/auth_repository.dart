// ignore_for_file: avoid_print
// ============================================================
//  auth_repository.dart
//  Đăng nhập / đăng ký / quản lý người dùng
// ============================================================
import 'repository_base.dart';
import '../models/user.dart';
import '../models/department.dart';
import '../services/sp_client.dart';
import 'package:shared_preferences/shared_preferences.dart';


mixin AuthRepository on RepositoryBase {
  // ── Đăng nhập ───────────────────────────────────────────────
  Future<User?> login(String username, String password) async {
    try {
      final u = await client.auth.login(username, password);
      if (u == null) return null;
      userCache = [];
      deptCache = []; // reset để load lại departments mới nhất
      // Load departments trước để mapUser join được deptName
      final depts = await client.reference.getDepartments();
      deptCache = depts.map((d) => Department(deptId: d.id ?? 0, deptName: d.name)).toList();
      
      // Save credentials for auto-login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_username', username);
      await prefs.setString('saved_password', password);

      currentUser = mapUser(u);
      return currentUser;
    } catch (e) {
      print('[Auth] login error: $e');
      rethrow; // Ném lại để UI phân biệt "lỗi mạng" vs "sai mật khẩu"
    }
  }

  // ── Auto Login (khi mở app hoặc F5 trang web) ────────────────
  Future<User?> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('saved_username');
    final password = prefs.getString('saved_password');
    if (username != null && password != null) {
      return await login(username, password);
    }
    return null;
  }


  // ── Đăng xuất (xóa cache) ───────────────────────────────────
  Future<void> logout() async {
    userCache = [];
    categoryCache = [];
    assetCache = [];
    currentUser = null;
    
    // Xóa session F5
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_username');
    await prefs.remove('saved_password');
  }

  // ── Đăng ký tài khoản mới (Admin only) ──────────────────────
  Future<User?> register({
    required String username,
    required String password,
    required String fullName,
    String? phone,
    required int roleId,
    int? deptId,
  }) async {
    final u = await client.auth.register(
        username, password, fullName, phone, roleId, deptId);
    if (u == null) return null;
    userCache = [];
    return mapUser(u);
  }

  // ── Lấy danh sách người dùng ────────────────────────────────
  Future<List<User>> getUsers() async {
    final us = await client.auth.getUsers();
    userCache = us.map(mapUser).toList();
    return userCache;
  }

  Future<List<User>> getITStaff() async {
    final staff = await client.auth.getITStaff();
    final mapped = staff.map(mapUser).toList();
    for (final u in mapped) {
      if (!userCache.any((c) => c.userId == u.userId)) userCache.add(u);
    }
    return mapped;
  }

  // ── Cập nhật thông tin người dùng (Admin only) ───────────────
  Future<User> updateUser({
    required int userId,
    required String fullName,
    String? phone,
    required int roleId,
    int? deptId,
  }) async {
    final u = await client.auth.updateUser(userId, fullName, phone, roleId, deptId);
    if (u == null) throw Exception('User not found');
    userCache = [];
    return mapUser(u);
  }

  // ── Đặt lại mật khẩu (Admin only) ───────────────────────────
  Future<bool> resetPassword(int userId, String newPassword) async {
    return client.auth.resetPassword(userId, newPassword);
  }

  // ── Xóa tài khoản (Admin only) ──────────────────────────────
  Future<bool> deleteUser(int userId) async {
    userCache = [];
    return client.auth.deleteUser(userId);
  }

  // ── Cập nhật FCM token thiết bị (cho push notification) ────────
  Future<void> updateFcmToken(int userId, String token) async {
    try {
      await client.auth.updateFcmToken(userId, token);
    } catch (_) {/* safe to ignore */}
  }
}
