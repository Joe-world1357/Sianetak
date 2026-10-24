import '../../../demo/demo_backend.dart';
import '../../requests/domain/request_models.dart';
import '../../technician/domain/technician_models.dart';

enum ReviewAction { approve, reject, suspend }

/// Operations snapshot for the admin dashboard.
class AdminOverview {
  const AdminOverview({
    required this.statusCounts,
    required this.pendingApplications,
    required this.approvedTechnicians,
    required this.commissionMinor,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) => AdminOverview(
    statusCounts: {
      for (final e in (json['statusCounts'] as Map<String, dynamic>).entries)
        parseRequestStatus(e.key): e.value as int,
    },
    pendingApplications: json['pendingApplications'] as int,
    approvedTechnicians: json['approvedTechnicians'] as int,
    commissionMinor: json['commissionMinor'] as int,
  );

  final Map<RequestStatus, int> statusCounts;
  final int pendingApplications;
  final int approvedTechnicians;
  final int commissionMinor;

  int count(Iterable<RequestStatus> statuses) =>
      statuses.fold(0, (sum, s) => sum + (statusCounts[s] ?? 0));
}

/// Technician verification and order operations (admin only; enforced by the data layer).
abstract class AdminRepository {
  Future<List<ApplicationSummary>> listApplications(VerificationStatus status);
  Future<ReviewApplication> getApplication(String id);
  Future<ReviewApplication> decide(
    String id,
    ReviewAction action, {
    String? reason,
  });

  Future<AdminOverview> overview();

  /// All requests in [statuses] (every request when empty), newest first.
  Future<List<RequestSummary>> requests(Set<RequestStatus> statuses);
  Future<List<PersonRef>> assignableTechnicians(String requestId);
  Future<RequestDetail> assign(String requestId, String technicianId);
}

class LocalAdminRepository implements AdminRepository {
  LocalAdminRepository(this._backend);

  final DemoBackend _backend;

  @override
  Future<List<ApplicationSummary>> listApplications(
    VerificationStatus status,
  ) async =>
      (await _backend.listApplications(verificationStatusParam(status)))
          .map(ApplicationSummary.fromJson)
          .toList(growable: false);

  @override
  Future<ReviewApplication> getApplication(String id) async =>
      ReviewApplication.fromJson(await _backend.getApplication(id));

  @override
  Future<ReviewApplication> decide(
    String id,
    ReviewAction action, {
    String? reason,
  }) async => ReviewApplication.fromJson(
    await _backend.decideApplication(id, action.name, reason),
  );

  @override
  Future<AdminOverview> overview() async =>
      AdminOverview.fromJson(await _backend.adminOverview());

  @override
  Future<List<RequestSummary>> requests(Set<RequestStatus> statuses) async =>
      (await _backend.adminRequests({
        for (final s in statuses) requestStatusWire(s),
      })).map(RequestSummary.fromJson).toList(growable: false);

  @override
  Future<List<PersonRef>> assignableTechnicians(String requestId) async =>
      (await _backend.assignableTechnicians(requestId))
          .map(PersonRef.fromJson)
          .toList(growable: false);

  @override
  Future<RequestDetail> assign(String requestId, String technicianId) async =>
      RequestDetail.fromJson(await _backend.assign(requestId, technicianId));
}
