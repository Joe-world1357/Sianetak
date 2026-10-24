import '../../../local/local_backend.dart';
import '../domain/auth_models.dart';

/// Local accounts: phone number + password, verified against a salted hash on this device.
abstract class AuthRepository {
  /// The account still signed in from the last launch, if its session is valid; [renew]
  /// extends the session (on app launch).
  Future<AppUser?> currentUser({bool renew = false});
  Future<AppUser> register({
    required String name,
    required String phone,
    required String password,
    required AccountType type,
  });
  Future<AppUser> signIn({required String phone, required String password});
  Future<void> signOut();
  Future<AppUser> updateName(String name);
  Future<void> changePassword({required String current, required String next});

  /// True once an administrator exists; until then the first one can be set up.
  Future<bool> hasAdmin();
  Future<AppUser> setupAdmin({
    required String name,
    required String phone,
    required String password,
  });

  /// Admin only: adds another administrator.
  Future<AppUser> createAdmin({
    required String name,
    required String phone,
    required String password,
  });
  Future<bool> onboardingSeen();
  Future<void> markOnboardingSeen();
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._backend);

  final LocalBackend _backend;

  @override
  Future<AppUser?> currentUser({bool renew = false}) async {
    final json = await _backend.currentUser(renew: renew);
    return json == null ? null : AppUser.fromJson(json);
  }

  @override
  Future<AppUser> register({
    required String name,
    required String phone,
    required String password,
    required AccountType type,
  }) async => AppUser.fromJson(
    await _backend.register(
      name: name,
      phone: phone,
      password: password,
      role: type.name,
    ),
  );

  @override
  Future<AppUser> signIn({
    required String phone,
    required String password,
  }) async => AppUser.fromJson(await _backend.signIn(phone, password));

  @override
  Future<void> signOut() => _backend.signOut();

  @override
  Future<AppUser> updateName(String name) async =>
      AppUser.fromJson(await _backend.updateName(name));

  @override
  Future<void> changePassword({
    required String current,
    required String next,
  }) => _backend.changePassword(current, next);

  @override
  Future<bool> hasAdmin() => _backend.hasAdmin();

  @override
  Future<AppUser> setupAdmin({
    required String name,
    required String phone,
    required String password,
  }) async => AppUser.fromJson(
    await _backend.setupAdmin(name: name, phone: phone, password: password),
  );

  @override
  Future<AppUser> createAdmin({
    required String name,
    required String phone,
    required String password,
  }) async => AppUser.fromJson(
    await _backend.createAdmin(name: name, phone: phone, password: password),
  );

  @override
  Future<bool> onboardingSeen() => _backend.onboardingSeen();

  @override
  Future<void> markOnboardingSeen() => _backend.markOnboardingSeen();
}
