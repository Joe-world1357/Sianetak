import '../../../local/local_backend.dart';
import '../../requests/domain/request_models.dart';
import '../domain/job_models.dart';

/// The technician's side of dispatch: offers, assigned jobs, quotes and closeout.
abstract class JobsRepository {
  Future<List<OfferedJob>> offers();
  Future<RequestDetail> accept(String offerId);
  Future<void> decline(String offerId);
  Future<List<RequestSummary>> jobs({required bool active});
  Future<RequestDetail> advance(String requestId, JobStep step);
  Future<RequestDetail> sendQuote(
    String requestId,
    int amountMinor, {
    String? note,
  });
  Future<Earnings> earnings();
}

class LocalJobsRepository implements JobsRepository {
  LocalJobsRepository(this._backend);

  final LocalBackend _backend;

  @override
  Future<List<OfferedJob>> offers() async => (await _backend.offers())
      .map(OfferedJob.fromJson)
      .toList(growable: false);

  @override
  Future<RequestDetail> accept(String offerId) async => RequestDetail.fromJson(
    await _backend.respondToOffer(offerId, accept: true),
  );

  @override
  Future<void> decline(String offerId) =>
      _backend.respondToOffer(offerId, accept: false);

  @override
  Future<List<RequestSummary>> jobs({required bool active}) async =>
      ((await _backend.jobs(active: active))['items'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(RequestSummary.fromJson)
          .toList(growable: false);

  @override
  Future<RequestDetail> advance(String requestId, JobStep step) async =>
      RequestDetail.fromJson(
        await _backend.advanceJob(requestId, switch (step) {
          JobStep.enRoute => 'en_route',
          JobStep.arrived => 'arrived',
          JobStep.complete => 'completed',
        }),
      );

  @override
  Future<RequestDetail> sendQuote(
    String requestId,
    int amountMinor, {
    String? note,
  }) async => RequestDetail.fromJson(
    await _backend.sendQuote(requestId, amountMinor, note),
  );

  @override
  Future<Earnings> earnings() async =>
      Earnings.fromJson(await _backend.earnings());
}
