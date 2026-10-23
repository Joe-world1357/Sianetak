import '../../../core/network/api_client.dart';
import '../../requests/domain/request_models.dart';
import '../domain/technician_models.dart';

abstract class TechnicianRepository {
  Future<OwnApplicationState> getOwn();
  Future<TechnicianApplication> submit(ApplicationSubmission submission);
  Future<List<ServiceArea>> serviceAreas();
}

class HttpTechnicianRepository implements TechnicianRepository {
  HttpTechnicianRepository(this._api);

  final ApiClient _api;

  @override
  Future<OwnApplicationState> getOwn() async => OwnApplicationState.fromJson(
    await _api.get('/technician/application', authenticated: true),
  );

  @override
  Future<TechnicianApplication> submit(ApplicationSubmission submission) async {
    final json = await _api.put(
      '/technician/application',
      body: submission.toJson(),
      authenticated: true,
    );
    return TechnicianApplication.fromJson(
      json['application'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ServiceArea>> serviceAreas() async {
    final json = await _api.get('/service-areas');
    return (json['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ServiceArea.fromJson)
        .toList(growable: false);
  }
}
