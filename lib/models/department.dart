class Department {
  final int deptId;
  final String deptName;

  const Department({required this.deptId, required this.deptName});

  factory Department.fromJson(Map<String, dynamic> json) => Department(
        deptId: json['DeptID'] as int,
        deptName: json['DeptName'] as String,
      );

  Map<String, dynamic> toJson() => {'DeptID': deptId, 'DeptName': deptName};
}
