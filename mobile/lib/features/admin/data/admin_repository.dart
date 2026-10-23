import '../../../core/network/api_client.dart';
import '../../technician/domain/technician_models.dart';

enum ReviewAction { approve, reject, suspend }

/// Technician verification queue (admin only; enforced by the server).
abstract class AdminRepository {
  Future<List<ApplicationSummary>> listApplications(VerificationStatus status);
  Future<ReviewApplication> getApplication(String id);
  Future<ReviewApplication> decide(
    String id,
    ReviewAction action, {
    String? reason,
  });
}

class HttpAdminRepository implements AdminRepository {
  HttpAdminRepository(this._api);

  final ApiClient _api;

  @override
  Future<List<ApplicationSummary>> listApplications(
    VerificationStatus status,
  ) async {
    final json = await _api.get(
      '/admin/technician-applications?status=${verificationStatusParam(status)}&limit=100',
      authenticated: true,
    );
    return (json['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ApplicationSummary.fromJson)
        .toList(growable: false);
  }

  @override
  Future<ReviewApplication> getApplication(String id) async =>
      ReviewApplication.fromJson(
        await _api.get(
          '/admin/technician-applications/${Uri.encodeComponent(id)}',
          authenticated: true,
        ),
      );

  @override
  Future<ReviewApplication> decide(
    String id,
    ReviewAction action, {
    String? reason,
  }) async => ReviewApplication.fromJson(
    await _api.post(
      '/admin/technician-applications/${Uri.encodeComponent(id)}/${action.name}',
      body: switch (action) {
        ReviewAction.approve => {'note': ?reason},
        _ => {'reason': reason},
      },
      authenticated: true,
    ),
  );
}
