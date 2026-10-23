import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/core/network/api_exception.dart';
import 'package:sianetak_customer/features/catalog/domain/catalog_models.dart';
import 'package:sianetak_customer/features/requests/application/request_draft_controller.dart';
import 'package:sianetak_customer/features/requests/domain/request_models.dart';

import '../support/fakes.dart';

ServiceDetail serviceDetail() => ServiceDetail(
  summary: service(),
  description: text('تفاصيل', 'Details'),
  categorySlug: 'plumbing',
  categoryName: text('سباكة', 'Plumbing'),
);

void main() {
  late FakeRequestsRepository requests;
  late FakeMediaRepository media;

  RequestDraftController draft({
    RequestOptions? options,
    List<SavedAddress> saved = const [],
  }) => RequestDraftController(
    service: serviceDetail(),
    requests: requests,
    media: media,
    options: options ?? requests.currentOptions,
    savedAddresses: saved,
  );

  void fillValid(RequestDraftController d) {
    d.description = 'الحنفية بتسرب مياه من امبارح';
    d.areaId = 'area-kima';
    d.details = 'شارع النيل، عمارة 5';
    d.schedule = const RequestSchedule.asap();
  }

  setUp(() {
    requests = FakeRequestsRepository();
    media = FakeMediaRepository();
  });

  test('each step blocks until it is complete', () {
    final d = draft();
    expect(d.next(), DraftIssue.descriptionTooShort);
    expect(d.step, RequestStep.describe);
    d.description = '   قصير   ';
    expect(d.next(), DraftIssue.descriptionTooShort);
    d.description = 'الحنفية بتسرب مياه';
    expect(d.next(), isNull);
    expect(d.step, RequestStep.location);
    expect(d.next(), DraftIssue.areaMissing);
    d.areaId = 'area-kima';
    d.details = 'abc';
    expect(d.next(), DraftIssue.detailsTooShort);
    d.details = 'شارع النيل';
    expect(d.next(), isNull);
    expect(d.next(), DraftIssue.scheduleMissing);
    d.schedule = const RequestSchedule.asap();
    expect(d.next(), isNull);
    expect(d.step, RequestStep.review);
    d.dispose();
  });

  test('a description over the maximum is rejected', () {
    final d = draft()..description = 'أ' * 1001;
    expect(d.descriptionIssue(), DraftIssue.descriptionTooLong);
    d.dispose();
  });

  test(
    'photos upload, can fail and be retried, and block until done',
    () async {
      media.uploadErrors.add(const ApiException(code: 'NETWORK_ERROR'));
      final d = draft();
      fillValid(d);
      expect(d.addPhoto(pickedImage()), AddPhotoResult.added);
      expect(d.photosIssue(), DraftIssue.photosUploading);
      await pumpEventQueue();
      expect(d.photos.single.status, PhotoStatus.failed);
      expect(d.issueFor(RequestStep.review), DraftIssue.photosFailed);

      d.retryPhoto(d.photos.single.localId);
      await pumpEventQueue();
      expect(d.photos.single.status, PhotoStatus.uploaded);
      expect(d.photos.single.mediaId, 'media-1');
      expect(d.issueFor(RequestStep.review), isNull);
      expect(d.buildSubmission().photoIds, ['media-1']);
      d.dispose();
    },
  );

  test('enforces the photo count and size limits from the server', () {
    final d = draft(options: requestOptions(maxPhotos: 1, maxPhotoBytes: 50));
    expect(d.addPhoto(pickedImage(51)), AddPhotoResult.tooLarge);
    expect(d.addPhoto(pickedImage(10)), AddPhotoResult.added);
    expect(d.addPhoto(pickedImage(10)), AddPhotoResult.limitReached);
    d.dispose();
    final off = draft(options: requestOptions(uploadsAvailable: false));
    expect(off.addPhoto(pickedImage()), AddPhotoResult.unavailable);
    off.dispose();
  });

  test('removing an uploaded photo deletes it on the server', () async {
    final d = draft();
    d.addPhoto(pickedImage());
    await pumpEventQueue();
    d.removePhoto(d.photos.single.localId);
    await pumpEventQueue();
    expect(media.removed, ['media-1']);
    expect(d.photos, isEmpty);
    d.dispose();
  });

  test('abandoning a draft removes its uploaded photos', () async {
    final d = draft();
    d.addPhoto(pickedImage());
    await pumpEventQueue();
    d.dispose();
    await pumpEventQueue();
    expect(media.removed, ['media-1']);
  });

  test('a retried submission reuses the idempotency key', () async {
    requests.submitErrors.add(const ApiException(code: 'NETWORK_ERROR'));
    final d = draft();
    fillValid(d);
    expect(await d.submit(), isNull);
    expect(d.submitError, isA<ApiException>());
    final result = await d.submit();
    expect(result, isNotNull);
    expect(requests.submissions, hasLength(2));
    expect(requests.submissions[0].$2, requests.submissions[1].$2);
    expect(requests.created, hasLength(1));
    // Submitted photos are kept when the screen closes.
    d.dispose();
    expect(media.removed, isEmpty);
  });

  test('changing the content after a failure uses a new key', () async {
    requests.submitErrors.add(const ApiException(code: 'NETWORK_ERROR'));
    final d = draft();
    fillValid(d);
    await d.submit();
    d.description = 'وصف مختلف للمشكلة تمامًا';
    await d.submit();
    expect(requests.submissions[0].$2, isNot(requests.submissions[1].$2));
    d.dispose();
  });

  test('an expired slot is cleared and the slot list refreshed', () async {
    final slots = sampleSlots();
    requests.submitErrors.add(
      const ApiException(code: 'INVALID_SCHEDULE', statusCode: 400),
    );
    final d = draft(options: requestOptions(slots: slots));
    fillValid(d);
    d.schedule = RequestSchedule.slot(slots.first);
    requests.currentOptions = requestOptions(slots: [slots.last]);
    expect(await d.submit(), isNull);
    expect(requests.optionsCalls, 1);
    expect(d.schedule, isNull);
    expect(d.options.slots, [slots.last]);
    d.dispose();
  });

  test('a saved address is preselected and sent by id', () {
    final saved = SavedAddress(
      id: 'addr-1',
      area: sampleArea,
      details: 'شارع السوق',
    );
    final d = draft(saved: [saved]);
    expect(d.useNewAddress, isFalse);
    expect(d.locationIssue(), isNull);
    d.description = 'الحنفية بتسرب مياه';
    d.schedule = const RequestSchedule.asap();
    final json = d.buildSubmission().toJson();
    expect(json['addressId'], 'addr-1');
    expect(json.containsKey('address'), isFalse);
    expect(json['schedule'], {'type': 'asap'});
    d.dispose();
  });

  test('a typed address includes coordinates only when captured', () {
    final d = draft();
    fillValid(d);
    expect(
      (d.buildSubmission().toJson()['address'] as Map).containsKey('latitude'),
      isFalse,
    );
    d.point = const GeoPoint(24.09, 32.9);
    final address = d.buildSubmission().toJson()['address'] as Map;
    expect(address['latitude'], 24.09);
    expect(d.buildSubmission().toJson()['saveAddress'], isTrue);
    d.dispose();
  });
}
