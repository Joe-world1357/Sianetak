enum UserRole { customer, technician, admin, unknown }

UserRole _parseRole(Object? value) => switch (value) {
  'customer' => UserRole.customer,
  'technician' => UserRole.technician,
  'admin' => UserRole.admin,
  _ => UserRole.unknown,
};

class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    role: _parseRole(json['role']),
  );

  final String id;
  final String phone;
  final String? name;
  final UserRole role;
}
