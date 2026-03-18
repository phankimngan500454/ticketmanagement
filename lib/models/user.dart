/// Role: 'Admin' | 'IT' | 'Customer'
class User {
  final int userId;
  final String fullName;
  final String phone;
  final String role;
  final DateTime createdAt;
  final int deptId;

  // Thêm để tiện dùng trên UI (join từ Departments)
  final String? deptName;

  const User({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.createdAt,
    required this.deptId,
    this.deptName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    dynamic g(String c, String p) => json[c] ?? json[p];
    final roleId  = g('roleID', 'RoleID') as int?;
    final roleStr = g('role', 'Role') as String?
        ?? (roleId == 1 ? 'Admin' : roleId == 2 ? 'IT' : 'Customer');
    // Backend trả "department" là string, mock dùng "deptName"
    final dept = g('department', 'deptName') as String?;
    return User(
      userId:    g('userID', 'UserID') as int? ?? 0,
      fullName:  g('fullName', 'FullName') as String? ?? '',
      phone:     g('phone', 'Phone') as String? ?? '',
      role:      roleStr,
      createdAt: DateTime.tryParse(g('createdAt', 'CreatedAt') as String? ?? '') ?? DateTime.now(),
      deptId:    g('deptID', 'DeptID') as int? ?? 0,
      deptName:  (dept == 'N/A' || dept == null || dept.isEmpty) ? null : dept,
    );
  }



  Map<String, dynamic> toJson() => {
        'UserID': userId,
        'FullName': fullName,
        'Phone': phone,
        'Role': role,
        'CreatedAt': createdAt.toIso8601String(),
        'DeptID': deptId,
      };
}
