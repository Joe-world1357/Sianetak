import '../../../local/local_backend.dart';
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

  /// Customer (or admin) cancels before work starts.
  Future<RequestDetail> cancel(String id, String reason);
  Future<RequestDetail> decideQuote(String id, {required bool approve});
  Future<RequestDetail> rate(String id, int stars, {String? comment});

  /// Order-bound chat between the customer and the assigned technician.
  Future<List<ChatMessage>> messages(String id);
  Future<void> sendMessage(String id, String text);
}

class LocalRequestsRepository implements RequestsRepository {
  LocalRequestsRepository(this._backend);

  final LocalBackend _backend;

  List<Map<String, dynamic>> _items(Map<String, dynamic> json) =>
      (json['items'] as List<dynamic>).cast<Map<String, dynamic>>();

  @override
  Future<RequestOptions> options() async =>
      RequestOptions.fromJson(await _backend.requestOptions());

  @override
  Future<List<SavedAddress>> savedAddresses() async =>
      (await _backend.addresses())
          .map(SavedAddress.fromJson)
          .toList(growable: false);

  @override
  Future<void> deleteAddress(String id) => _backend.deleteAddress(id);

  @override
  Future<RequestDetail> submit(
    RequestSubmission submission, {
    required String idempotencyKey,
  }) async => RequestDetail.fromJson(
    await _backend.submitRequest(submission.toJson(), idempotencyKey),
  );

  @override
  Future<RequestPage> list({String? cursor}) async {
    final json = await _backend.listRequests(cursor: cursor);
    return RequestPage(
      items: _items(json).map(RequestSummary.fromJson).toList(growable: false),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  @override
  Future<RequestDetail> get(String id) async =>
      RequestDetail.fromJson(await _backend.getRequest(id));

  @override
  Future<RequestDetail> cancel(String id, String reason) async =>
      RequestDetail.fromJson(await _backend.cancelRequest(id, reason));

  @override
  Future<RequestDetail> decideQuote(String id, {required bool approve}) async =>
      RequestDetail.fromJson(await _backend.decideQuote(id, approve: approve));

  @override
  Future<RequestDetail> rate(String id, int stars, {String? comment}) async =>
      RequestDetail.fromJson(await _backend.rate(id, stars, comment));

  @override
  Future<List<ChatMessage>> messages(String id) async =>
      (await _backend.messages(id))
          .map(ChatMessage.fromJson)
          .toList(growable: false);

  @override
  Future<void> sendMessage(String id, String text) =>
      _backend.sendMessage(id, text);
}
