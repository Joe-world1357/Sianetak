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

class OtpChallenge {
  const OtpChallenge({
    required this.challengeId,
    required this.phone,
    required this.codeLength,
    required this.resendAfterSeconds,
    required this.expiresAt,
    this.devCode,
  });

  factory OtpChallenge.fromJson(String phone, Map<String, dynamic> json) =>
      OtpChallenge(
        challengeId: json['challengeId'] as String,
        phone: phone,
        codeLength: json['codeLength'] as int? ?? 6,
        resendAfterSeconds: json['resendAfterSeconds'] as int? ?? 60,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        devCode: json['devCode'] as String?,
      );

  final String challengeId;

  /// E.164 phone the code was sent to.
  final String phone;
  final int codeLength;
  final int resendAfterSeconds;
  final DateTime expiresAt;

  /// Only returned by a development backend using the OTP stub; never by production.
  final String? devCode;
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  );

  final String accessToken;
  final String refreshToken;
  final AppUser user;
}
