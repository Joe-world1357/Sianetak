/// Request, address and form-configuration models parsed from the backend API.
library;

import '../../catalog/domain/catalog_models.dart';

class ServiceArea {
  const ServiceArea({required this.id, required this.slug, required this.name});

  factory ServiceArea.fromJson(Map<String, dynamic> json) => ServiceArea(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: LocalizedText.fromJson(json['name']),
  );

  final String id;
  final String slug;
  final LocalizedText name;
}

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  static GeoPoint? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final lat = json['latitude'];
    final lng = json['longitude'];
    if (lat is! num || lng is! num) return null;
    return GeoPoint(lat.toDouble(), lng.toDouble());
  }

  final double latitude;
  final double longitude;
}

class SavedAddress {
  const SavedAddress({
    required this.id,
    this.label,
    required this.area,
    required this.details,
    this.landmark,
    this.location,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: json['id'] as String,
    label: json['label'] as String?,
    area: ServiceArea.fromJson(json['area'] as Map<String, dynamic>),
    details: json['details'] as String,
    landmark: json['landmark'] as String?,
    location: GeoPoint.fromJson(json['location']),
  );

  final String id;
  final String? label;
  final ServiceArea area;
  final String details;
  final String? landmark;
  final GeoPoint? location;
}

/// A typed address. Coordinates are optional and only set from the device's location.
class AddressInput {
  const AddressInput({
    required this.areaId,
    required this.details,
    this.landmark,
    this.label,
    this.location,
  });

  final String areaId;
  final String details;
  final String? landmark;
  final String? label;
  final GeoPoint? location;

  Map<String, dynamic> toJson() => {
    'areaId': areaId,
    'details': details,
    if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
    if (label != null && label!.isNotEmpty) 'label': label,
    if (location != null) ...{
      'latitude': location!.latitude,
      'longitude': location!.longitude,
    },
  };
}

class TimeSlot {
  const TimeSlot({required this.from, required this.to});

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    from: DateTime.parse(json['from'] as String),
    to: DateTime.parse(json['to'] as String),
  );

  final DateTime from;
  final DateTime to;

  @override
  bool operator ==(Object other) =>
      other is TimeSlot && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

class Money {
  const Money({required this.amountMinor, this.currency = 'EGP'});

  static Money? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final amount = json['amountMinor'];
    if (amount is! int) return null;
    return Money(
      amountMinor: amount,
      currency: json['currency'] as String? ?? 'EGP',
    );
  }

  final int amountMinor;
  final String currency;
}

/// Server-provided form rules (GET /requests/options).
class RequestOptions {
  const RequestOptions({
    required this.descriptionMinLength,
    required this.descriptionMaxLength,
    required this.maxPhotos,
    required this.maxPhotoBytes,
    required this.uploadsAvailable,
    required this.asapAvailable,
    required this.slots,
    required this.inspectionFee,
    required this.areas,
  });

  factory RequestOptions.fromJson(Map<String, dynamic> json) {
    final description = json['description'] as Map<String, dynamic>? ?? {};
    final photos = json['photos'] as Map<String, dynamic>? ?? {};
    final schedule = json['schedule'] as Map<String, dynamic>? ?? {};
    final fees = json['fees'] as Map<String, dynamic>? ?? {};
    return RequestOptions(
      descriptionMinLength: description['minLength'] as int? ?? 10,
      descriptionMaxLength: description['maxLength'] as int? ?? 1000,
      maxPhotos: photos['max'] as int? ?? 0,
      maxPhotoBytes: photos['maxBytes'] as int? ?? 0,
      uploadsAvailable: photos['uploadsAvailable'] as bool? ?? false,
      asapAvailable: schedule['asapAvailable'] as bool? ?? true,
      slots: (schedule['slots'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(TimeSlot.fromJson)
          .toList(growable: false),
      inspectionFee: Money.fromJson(fees['inspectionFee']),
      areas: (json['areas'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(ServiceArea.fromJson)
          .toList(growable: false),
    );
  }

  final int descriptionMinLength;
  final int descriptionMaxLength;
  final int maxPhotos;
  final int maxPhotoBytes;
  final bool uploadsAvailable;
  final bool asapAvailable;
  final List<TimeSlot> slots;

  /// Null while no inspection fee is approved (open decision D-02).
  final Money? inspectionFee;
  final List<ServiceArea> areas;
}

/// Service journey: submitted (offers out) → assigned → en route → arrived → quoted →
/// in progress (only after the customer approves the quote) → completed. A request can be
/// cancelled before work starts; with no taker it waits for operations as `unmatched`.
enum RequestStatus {
  submitted,
  unmatched,
  assigned,
  enRoute,
  arrived,
  quoted,
  quoteRejected,
  inProgress,
  completed,
  cancelled,
  unknown;

  bool get isFinal => this == completed || this == cancelled;

  /// The customer may cancel until work has started.
  bool get isCancellable => switch (this) {
    submitted || unmatched || assigned || enRoute || arrived => true,
    quoted || quoteRejected => true,
    _ => false,
  };

  /// A technician is attached and the two parties can chat.
  bool get hasTechnician =>
      this != submitted && this != unmatched && this != unknown;
}

const _statusWire = {
  RequestStatus.submitted: 'submitted',
  RequestStatus.unmatched: 'unmatched',
  RequestStatus.assigned: 'assigned',
  RequestStatus.enRoute: 'en_route',
  RequestStatus.arrived: 'arrived',
  RequestStatus.quoted: 'quoted',
  RequestStatus.quoteRejected: 'quote_rejected',
  RequestStatus.inProgress: 'in_progress',
  RequestStatus.completed: 'completed',
  RequestStatus.cancelled: 'cancelled',
};

RequestStatus parseRequestStatus(Object? value) => _statusWire.entries
    .firstWhere(
      (e) => e.value == value,
      orElse: () => const MapEntry(RequestStatus.unknown, ''),
    )
    .key;

String requestStatusWire(RequestStatus status) => _statusWire[status] ?? '';

enum ScheduleType { asap, scheduled }

class RequestSchedule {
  const RequestSchedule.asap() : type = ScheduleType.asap, slot = null;
  const RequestSchedule.slot(TimeSlot this.slot)
    : type = ScheduleType.scheduled;

  factory RequestSchedule.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    if (map['type'] == 'scheduled' &&
        map['from'] is String &&
        map['to'] is String) {
      return RequestSchedule.slot(TimeSlot.fromJson(map));
    }
    return const RequestSchedule.asap();
  }

  final ScheduleType type;
  final TimeSlot? slot;

  Map<String, dynamic> toJson() => type == ScheduleType.asap
      ? {'type': 'asap'}
      : {
          'type': 'scheduled',
          'from': slot!.from.toUtc().toIso8601String(),
          'to': slot!.to.toUtc().toIso8601String(),
        };
}

class RequestServiceRef {
  const RequestServiceRef({
    required this.id,
    required this.slug,
    required this.name,
    required this.categoryName,
  });

  factory RequestServiceRef.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>? ?? const {};
    return RequestServiceRef(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: LocalizedText.fromJson(json['name']),
      categoryName: LocalizedText.fromJson(category['name']),
    );
  }

  final String id;
  final String slug;
  final LocalizedText name;
  final LocalizedText categoryName;
}

class RequestSummary {
  const RequestSummary({
    required this.id,
    required this.reference,
    required this.status,
    required this.service,
    required this.area,
    required this.schedule,
    required this.photoCount,
    required this.submittedAt,
  });

  factory RequestSummary.fromJson(Map<String, dynamic> json) => RequestSummary(
    id: json['id'] as String,
    reference: json['reference'] as String,
    status: parseRequestStatus(json['status']),
    service: RequestServiceRef.fromJson(
      json['service'] as Map<String, dynamic>,
    ),
    area: ServiceArea.fromJson(json['area'] as Map<String, dynamic>),
    schedule: RequestSchedule.fromJson(json['schedule']),
    photoCount: json['photoCount'] as int? ?? 0,
    submittedAt: DateTime.parse(json['submittedAt'] as String),
  );

  final String id;
  final String reference;
  final RequestStatus status;
  final RequestServiceRef service;
  final ServiceArea area;
  final RequestSchedule schedule;
  final int photoCount;
  final DateTime submittedAt;
}

class RequestPage {
  const RequestPage({required this.items, this.nextCursor});

  final List<RequestSummary> items;
  final String? nextCursor;
}

class RequestTimelineEntry {
  const RequestTimelineEntry({
    required this.status,
    required this.at,
    this.note,
  });

  final RequestStatus status;
  final DateTime at;
  final String? note;
}

/// The other party on a request, as far as the viewer may see them.
class PersonRef {
  const PersonRef({
    required this.id,
    required this.name,
    required this.phone,
    this.rating,
    this.ratingCount = 0,
  });

  factory PersonRef.fromJson(Map<String, dynamic> json) => PersonRef(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    phone: json['phone'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble(),
    ratingCount: json['ratingCount'] as int? ?? 0,
  );

  final String id;
  final String name;
  final String phone;

  /// Average stars for a technician; null until rated.
  final double? rating;
  final int ratingCount;
}

enum QuoteStatus { pending, approved, rejected }

/// The technician's price after inspection; work starts only once it is approved.
class Quote {
  const Quote({
    required this.amountMinor,
    this.note,
    required this.status,
    required this.at,
  });

  static Quote? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return Quote(
      amountMinor: json['amountMinor'] as int,
      note: json['note'] as String?,
      status: switch (json['status']) {
        'approved' => QuoteStatus.approved,
        'rejected' => QuoteStatus.rejected,
        _ => QuoteStatus.pending,
      },
      at: DateTime.parse(json['at'] as String),
    );
  }

  final int amountMinor;
  final String? note;
  final QuoteStatus status;
  final DateTime at;
}

/// Cash collected at closeout, with the platform commission owed by the technician.
class PaymentRecord {
  const PaymentRecord({
    required this.amountMinor,
    required this.commissionMinor,
    required this.at,
  });

  static PaymentRecord? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return PaymentRecord(
      amountMinor: json['amountMinor'] as int,
      commissionMinor: json['commissionMinor'] as int? ?? 0,
      at: DateTime.parse(json['at'] as String),
    );
  }

  final int amountMinor;
  final int commissionMinor;
  final DateTime at;
}

class RequestRating {
  const RequestRating({required this.stars, this.comment, required this.at});

  static RequestRating? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return RequestRating(
      stars: json['stars'] as int,
      comment: json['comment'] as String?,
      at: DateTime.parse(json['at'] as String),
    );
  }

  final int stars;
  final String? comment;
  final DateTime at;
}

enum OfferStatus { pending, accepted, declined, expired, taken }

/// A dispatch offer, as the receiving technician sees it.
class JobOffer {
  const JobOffer({
    required this.id,
    required this.status,
    required this.expiresAt,
  });

  static JobOffer? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    return JobOffer(
      id: json['id'] as String,
      status: OfferStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => OfferStatus.expired,
      ),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final String id;
  final OfferStatus status;
  final DateTime expiresAt;
}

class RequestDetail {
  const RequestDetail({
    required this.summary,
    required this.description,
    required this.photoIds,
    required this.areaName,
    required this.addressDetails,
    this.landmark,
    this.coordinates,
    required this.pricing,
    this.inspectionFee,
    required this.timeline,
    this.customer,
    this.technician,
    this.quote,
    this.payment,
    this.rating,
    this.cancelReason,
    this.offer,
  });

  factory RequestDetail.fromJson(Map<String, dynamic> json) {
    final location = json['location'] as Map<String, dynamic>? ?? const {};
    final fees = json['fees'] as Map<String, dynamic>? ?? const {};
    return RequestDetail(
      summary: RequestSummary.fromJson(json),
      description: json['description'] as String? ?? '',
      photoIds: (json['photos'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map((p) => p['id'] as String)
          .toList(growable: false),
      areaName: ServiceArea.fromJson(location['area'] as Map<String, dynamic>)
          .name,
      addressDetails: location['details'] as String? ?? '',
      landmark: location['landmark'] as String?,
      coordinates: GeoPoint.fromJson(location['coordinates']),
      pricing: PricingGuidance.fromJson(json['pricing']),
      inspectionFee: Money.fromJson(fees['inspectionFee']),
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (e) => RequestTimelineEntry(
              status: parseRequestStatus(e['status']),
              at: DateTime.parse(e['at'] as String),
              note: e['note'] as String?,
            ),
          )
          .toList(growable: false),
      customer: json['customer'] == null
          ? null
          : PersonRef.fromJson(json['customer'] as Map<String, dynamic>),
      technician: json['technician'] == null
          ? null
          : PersonRef.fromJson(json['technician'] as Map<String, dynamic>),
      quote: Quote.fromJson(json['quote']),
      payment: PaymentRecord.fromJson(json['payment']),
      rating: RequestRating.fromJson(json['rating']),
      cancelReason: json['cancelReason'] as String?,
      offer: JobOffer.fromJson(json['offer']),
    );
  }

  final RequestSummary summary;
  final String description;
  final List<String> photoIds;
  final LocalizedText areaName;
  final String addressDetails;
  final String? landmark;
  final GeoPoint? coordinates;
  final PricingGuidance pricing;
  final Money? inspectionFee;
  final List<RequestTimelineEntry> timeline;

  /// Shown to the assigned technician and to admins.
  final PersonRef? customer;
  final PersonRef? technician;
  final Quote? quote;
  final PaymentRecord? payment;
  final RequestRating? rating;
  final String? cancelReason;

  /// Set when the viewer is a technician holding an offer for this request.
  final JobOffer? offer;
}

/// Everything sent to POST /requests.
class RequestSubmission {
  const RequestSubmission({
    required this.serviceId,
    required this.description,
    required this.photoIds,
    this.addressId,
    this.address,
    this.saveAddress = false,
    required this.schedule,
  });

  final String serviceId;
  final String description;
  final List<String> photoIds;
  final String? addressId;
  final AddressInput? address;
  final bool saveAddress;
  final RequestSchedule schedule;

  Map<String, dynamic> toJson() => {
    'serviceId': serviceId,
    'description': description,
    if (photoIds.isNotEmpty) 'photoIds': photoIds,
    if (addressId != null) 'addressId': addressId,
    if (address != null) 'address': address!.toJson(),
    if (address != null && saveAddress) 'saveAddress': true,
    'schedule': schedule.toJson(),
  };
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.at,
    required this.mine,
    required this.senderRole,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    text: json['text'] as String,
    at: DateTime.parse(json['at'] as String),
    mine: json['mine'] as bool? ?? false,
    senderRole: json['senderRole'] as String? ?? '',
  );

  final String id;
  final String text;
  final DateTime at;
  final bool mine;

  /// `customer` or `technician`; lets an admin reader tell the two apart.
  final String senderRole;
}
