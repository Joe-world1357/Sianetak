import '../../../demo/demo_backend.dart';
import '../domain/auth_models.dart';

/// Demo sign-in: pick one of the seeded accounts. No phone verification in the standalone demo.
abstract class AuthRepository {
  Future<List<AppUser>> demoAccounts();
  Future<AppUser> signInAs(String userId);

  /// The account still signed in from the last launch, if any.
  Future<AppUser?> currentUser();
  Future<void> signOut();
  Future<AppUser> updateName(String name);
}

class LocalAuthRepository implements AuthRepository {
  LocalAuthRepository(this._backend);

  final DemoBackend _backend;

  @override
  Future<List<AppUser>> demoAccounts() async => (await _backend.demoAccounts())
      .map(AppUser.fromJson)
      .toList(growable: false);

  @override
  Future<AppUser> signInAs(String userId) async =>
      AppUser.fromJson(await _backend.signIn(userId));

  @override
  Future<AppUser?> currentUser() async {
    final json = await _backend.currentUser();
    return json == null ? null : AppUser.fromJson(json);
  }

  @override
  Future<void> signOut() => _backend.signOut();

  @override
  Future<AppUser> updateName(String name) async =>
      AppUser.fromJson(await _backend.updateName(name));
}
