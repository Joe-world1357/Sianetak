import 'package:flutter_test/flutter_test.dart';
import 'package:sianetak_customer/features/requests/domain/request_models.dart';
import 'package:sianetak_customer/features/technician/domain/technician_models.dart';

final _area = {
  'id': 'a1',
  'slug': 'kima',
  'name': {'ar': 'كيما', 'en': 'Kima'},
  'isSample': true,
};

void main() {
  test('parses request options with no fee and scheduled slots', () {
    final o = RequestOptions.fromJson({
      'description': {'minLength': 10, 'maxLength': 1000},
      'photos': {'max': 5, 'maxBytes': 5242880, 'uploadsAvailable': true},
      'schedule': {
        'asapAvailable': true,
        'slots': [
          {
            'from': '2026-10-25T06:00:00.000Z',
            'to': '2026-10-25T09:00:00.000Z',
          },
        ],
      },
      'fees': {'inspectionFee': null},
      'areas': [_area],
    });
    expect(o.maxPhotos, 5);
    expect(o.inspectionFee, isNull);
    expect(o.slots.single.from, DateTime.utc(2026, 10, 25, 6));
    expect(o.areas.single.name.ar, 'كيما');
  });

  test('parses a request detail with location, photos and timeline', () {
    final d = RequestDetail.fromJson({
      'id': 'r1',
      'reference': 'SN-261025-ABCDE',
      'status': 'submitted',
      'service': {
        'id': 's1',
        'slug': 'leak',
        'name': {'ar': 'تسريب', 'en': 'Leak'},
        'category': {
          'name': {'ar': 'سباكة', 'en': 'Plumbing'},
        },
      },
      'area': _area,
      'schedule': {
        'type': 'scheduled',
        'from': '2026-10-25T06:00:00.000Z',
        'to': '2026-10-25T09:00:00.000Z',
      },
      'photoCount': 1,
      'submittedAt': '2026-10-24T10:00:00.000Z',
      'description': 'الحنفية بتسرب',
      'photos': [
        {'id': 'm1'},
      ],
      'location': {
        'area': _area,
        'details': 'شارع النيل',
        'landmark': null,
        'coordinates': {'latitude': 24.1, 'longitude': 32.9},
      },
      'pricing': {'type': 'inspection_required'},
      'fees': {
        'inspectionFee': {'amountMinor': 5000, 'currency': 'EGP'},
      },
      'timeline': [
        {'status': 'submitted', 'at': '2026-10-24T10:00:00.000Z'},
      ],
    });
    expect(d.summary.reference, 'SN-261025-ABCDE');
    expect(d.summary.status, RequestStatus.submitted);
    expect(d.summary.schedule.type, ScheduleType.scheduled);
    expect(d.photoIds, ['m1']);
    expect(d.coordinates?.latitude, 24.1);
    expect(d.inspectionFee?.amountMinor, 5000);
    expect(d.timeline.single.status, RequestStatus.submitted);
  });

  test('unknown statuses never crash parsing', () {
    expect(parseRequestStatus('matched'), RequestStatus.unknown);
    expect(parseVerificationStatus('banana'), VerificationStatus.unknown);
  });

  test('parses a reviewer view of an application', () {
    final r = ReviewApplication.fromJson({
      'id': 'p1',
      'status': 'rejected',
      'fullName': 'محمود علي',
      'specialties': [
        {
          'id': 'c1',
          'slug': 'plumbing',
          'name': {'ar': 'سباكة', 'en': 'Plumbing'},
        },
      ],
      'serviceAreas': [_area],
      'documents': [
        {
          'id': 'd1',
          'kind': 'identity',
          'contentType': 'application/pdf',
          'byteSize': 10,
        },
      ],
      'submittedAt': '2026-10-24T10:00:00.000Z',
      'decisionReason': 'الصورة غير واضحة',
      'canResubmit': true,
      'applicant': {'phone': '+201012345678', 'accountName': null},
      'history': [
        {
          'action': 'technician_application.submitted',
          'at': '2026-10-24T10:00:00.000Z',
          'reason': null,
        },
        {
          'action': 'technician_application.rejected',
          'at': '2026-10-24T11:00:00.000Z',
          'reason': 'الصورة غير واضحة',
        },
      ],
    });
    expect(r.application.status, VerificationStatus.rejected);
    expect(r.application.documents.single.isImage, isFalse);
    expect(r.application.documents.single.kind, DocumentKind.identity);
    expect(r.applicantPhone, '+201012345678');
    expect(r.history.last.reason, 'الصورة غير واضحة');
  });

  test('an application submission serializes documents with their kinds', () {
    const s = ApplicationSubmission(
      fullName: 'محمود علي',
      specialtyCategoryIds: ['c1'],
      serviceAreaIds: ['a1'],
      documents: [('m1', DocumentKind.qualification)],
    );
    expect(s.toJson(), {
      'fullName': 'محمود علي',
      'specialtyCategoryIds': ['c1'],
      'serviceAreaIds': ['a1'],
      'documents': [
        {'mediaId': 'm1', 'kind': 'qualification'},
      ],
    });
  });
}
