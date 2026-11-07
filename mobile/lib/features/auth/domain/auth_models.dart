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
    this.roles = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as String,
    phone: json['phone'] as String,
    name: json['name'] as String?,
    role: _parseRole(json['role']),
    technicianStatus: _parseTechnicianStatus(json['technicianStatus']),
    roles: [
      for (final r in json['roles'] as List<dynamic>? ?? const [])
        if (_parseRole(r) != UserRole.unknown) _parseRole(r),
    ],
  );

  final String id;
  final String phone;
  final String? name;

  /// The role the account is acting in now.
  final UserRole role;

  /// Every role this account can act in. Customer and technician accounts can switch
  /// between the two (one phone number, one account); administrators cannot.
  final List<UserRole> roles;

  bool get canSwitchRole => roles.length > 1;

  /// The other role a multi-role account can switch to, if any.
  UserRole? get otherRole => canSwitchRole
      ? roles.firstWhere((r) => r != role, orElse: () => role)
      : null;

  /// Technician accounts only; null for other roles.
  final TechnicianStatus? technicianStatus;

  /// Technicians take jobs only once an administrator has approved their application.
  bool get canWork =>
      role == UserRole.technician &&
      technicianStatus == TechnicianStatus.approved;
}

/// Which kind of account a person signs up for. Administrators cannot sign up.
enum AccountType { customer, technician }
