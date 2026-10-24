import '../../../local/local_backend.dart';
import '../../requests/domain/request_models.dart';
import '../domain/technician_models.dart';

abstract class TechnicianRepository {
  Future<OwnApplicationState> getOwn();
  Future<TechnicianApplication> submit(ApplicationSubmission submission);
  Future<List<ServiceArea>> serviceAreas();
}

class LocalTechnicianRepository implements TechnicianRepository {
  LocalTechnicianRepository(this._backend);

  final LocalBackend _backend;

  @override
  Future<OwnApplicationState> getOwn() async =>
      OwnApplicationState.fromJson(await _backend.ownApplication());

  @override
  Future<TechnicianApplication> submit(ApplicationSubmission submission) async {
    final json = await _backend.submitApplication(submission.toJson());
    return TechnicianApplication.fromJson(
      json['application'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ServiceArea>> serviceAreas() async => (await _backend.areas())
      .map(ServiceArea.fromJson)
      .toList(growable: false);
}
