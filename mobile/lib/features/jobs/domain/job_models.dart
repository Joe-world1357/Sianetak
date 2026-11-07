import '../../requests/domain/request_models.dart';

/// A request offered to the signed-in technician, with its acceptance deadline.
class OfferedJob {
  const OfferedJob({required this.request, required this.offer});

  factory OfferedJob.fromJson(Map<String, dynamic> json) => OfferedJob(
    request: RequestSummary.fromJson(json),
    offer: JobOffer.fromJson(json['offer'])!,
  );

  final RequestSummary request;
  final JobOffer offer;
}

/// Closeout totals for the technician's ledger.
class Earnings {
  const Earnings({
    required this.jobs,
    required this.collectedMinor,
    required this.commissionMinor,
    this.rating,
    required this.ratingCount,
  });

  factory Earnings.fromJson(Map<String, dynamic> json) => Earnings(
    jobs: json['jobs'] as int,
    collectedMinor: json['collectedMinor'] as int,
    commissionMinor: json['commissionMinor'] as int,
    rating: (json['rating'] as num?)?.toDouble(),
    ratingCount: json['ratingCount'] as int? ?? 0,
  );

  final int jobs;
  final int collectedMinor;
  final int commissionMinor;
  final double? rating;
  final int ratingCount;

  int get netMinor => collectedMinor - commissionMinor;
}

enum JobStep { enRoute, arrived, complete }
