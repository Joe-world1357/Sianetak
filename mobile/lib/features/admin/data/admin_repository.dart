import '../../../local/local_backend.dart';
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
    this.openProblems = 0,
  });

  factory AdminOverview.fromJson(Map<String, dynamic> json) => AdminOverview(
    statusCounts: {
      for (final e in (json['statusCounts'] as Map<String, dynamic>).entries)
        parseRequestStatus(e.key): e.value as int,
    },
    pendingApplications: json['pendingApplications'] as int,
    approvedTechnicians: json['approvedTechnicians'] as int,
    commissionMinor: json['commissionMinor'] as int,
    openProblems: json['openProblems'] as int? ?? 0,
  );

  final Map<RequestStatus, int> statusCounts;
  final int pendingApplications;
  final int approvedTechnicians;
  final int commissionMinor;

  /// Completed requests whose customer reported a problem not yet resolved.
  final int openProblems;

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

  /// All requests in [statuses] (every request when empty), newest first; only those with
  /// an open problem report when [openProblems] is set.
  Future<List<RequestSummary>> requests(
    Set<RequestStatus> statuses, {
    bool openProblems = false,
  });
  Future<RequestDetail> resolveProblem(String requestId, String resolution);
  Future<List<PersonRef>> assignableTechnicians(String requestId);
  Future<RequestDetail> assign(String requestId, String technicianId);
}

class LocalAdminRepository implements AdminRepository {
  LocalAdminRepository(this._backend);

  final LocalBackend _backend;

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
  Future<List<RequestSummary>> requests(
    Set<RequestStatus> statuses, {
    bool openProblems = false,
  }) async => (await _backend.adminRequests(
    {for (final s in statuses) requestStatusWire(s)},
    openProblems: openProblems,
  )).map(RequestSummary.fromJson).toList(growable: false);

  @override
  Future<RequestDetail> resolveProblem(
    String requestId,
    String resolution,
  ) async => RequestDetail.fromJson(
    await _backend.resolveProblem(requestId, resolution),
  );

  @override
  Future<List<PersonRef>> assignableTechnicians(String requestId) async =>
      (await _backend.assignableTechnicians(requestId))
          .map(PersonRef.fromJson)
          .toList(growable: false);

  @override
  Future<RequestDetail> assign(String requestId, String technicianId) async =>
      RequestDetail.fromJson(await _backend.assign(requestId, technicianId));
}
