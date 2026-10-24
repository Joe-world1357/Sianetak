enum UserRole { customer, technician, admin, unknown }

UserRole _parseRole(Object? value) => switch (value) {
  'customer' => UserRole.customer,
  'technician' => UserRole.technician,
  'admin' => UserRole.admin,
  _ => UserRole.unknown,
};

/// Where a technician account stands with its application.
enum TechnicianStatus {
  notSubmitted,
  pendingReview,
  approved,
  rejected,
  suspended,
}

TechnicianStatus? _parseTechnicianStatus(Object? value) => switch (value) {
  'not_submitted' => TechnicianStatus.notSubmitted,
  'pending_review' => TechnicianStatus.pendingReview,
  'approved' => TechnicianStatus.approved,
  'rejected' => TechnicianStatus.rejected,
  'suspended' => TechnicianStatus.suspended,
  _ => null,
};

class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    this.name,
    required this.role,
    this.technicianStatus,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    role: _parseRole(json['role']),
    technicianStatus: _parseTechnicianStatus(json['technicianStatus']),
  );

  final String id;
  final String phone;
  final String? name;
  final UserRole role;

  /// Technician accounts only; null for other roles.
  final TechnicianStatus? technicianStatus;

  /// Technicians take jobs only once an administrator has approved their application.
  bool get canWork =>
      role == UserRole.technician &&
      technicianStatus == TechnicianStatus.approved;
}

/// Which kind of account a person signs up for. Administrators cannot sign up.
enum AccountType { customer, technician }
