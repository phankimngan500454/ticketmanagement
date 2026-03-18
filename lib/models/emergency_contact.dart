class EmergencyContact {
  final int? id;
  final int? userId;       // linked IT staff user (optional)
  final String name;
  final String phoneNumber;
  final String? description;
  final int sortOrder;

  const EmergencyContact({
    this.id,
    this.userId,
    required this.name,
    required this.phoneNumber,
    this.description,
    this.sortOrder = 0,
  });

  factory EmergencyContact.fromSp(dynamic sp) => EmergencyContact(
        id: sp.id as int?,
        userId: sp.userId as int?,
        name: sp.name as String,
        phoneNumber: sp.phoneNumber as String,
        description: sp.description as String?,
        sortOrder: sp.sortOrder as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'phoneNumber': phoneNumber,
        'description': description,
        'sortOrder': sortOrder,
      };
}
