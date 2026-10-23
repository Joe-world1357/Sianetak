import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/request_models.dart';

abstract class RequestsRepository {
  Future<RequestOptions> options();
  Future<List<SavedAddress>> savedAddresses();
  Future<void> deleteAddress(String id);

  /// [idempotencyKey] must stay the same when retrying the same submission.
  Future<RequestDetail> submit(
    RequestSubmission submission, {
    required String idempotencyKey,
  });
  Future<RequestPage> list({String? cursor});
  Future<RequestDetail> get(String id);
}

class HttpRequestsRepository implements RequestsRepository {
  HttpRequestsRepository(this._api);

  final ApiClient _api;

  List<Map<String, dynamic>> _items(Map<String, dynamic> json) {
    final items = json['items'];
    if (items is! List) {
      throw const ApiException(code: ApiException.badResponse);
    }
    return items.cast<Map<String, dynamic>>();
  }

  @override
  Future<RequestOptions> options() async =>
      RequestOptions.fromJson(await _api.get('/requests/options'));

  @override
  Future<List<SavedAddress>> savedAddresses() async =>
      _items(await _api.get('/me/addresses', authenticated: true))
          .map(SavedAddress.fromJson)
          .toList(growable: false);

  @override
  Future<void> deleteAddress(String id) => _api.delete(
    '/me/addresses/${Uri.encodeComponent(id)}',
    authenticated: true,
  );

  @override
  Future<RequestDetail> submit(
    RequestSubmission submission, {
    required String idempotencyKey,
  }) async => RequestDetail.fromJson(
    await _api.post(
      '/requests',
      body: submission.toJson(),
      headers: {'Idempotency-Key': idempotencyKey},
      authenticated: true,
    ),
  );

  @override
  Future<RequestPage> list({String? cursor}) async {
    final query = cursor == null
        ? ''
        : '?cursor=${Uri.encodeQueryComponent(cursor)}';
    final json = await _api.get('/requests$query', authenticated: true);
    return RequestPage(
      items: _items(json).map(RequestSummary.fromJson).toList(growable: false),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  @override
  Future<RequestDetail> get(String id) async => RequestDetail.fromJson(
    await _api.get('/requests/${Uri.encodeComponent(id)}', authenticated: true),
  );
}
