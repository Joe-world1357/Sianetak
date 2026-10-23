/// Technician application models (own view and reviewer view).
library;

import '../../catalog/domain/catalog_models.dart';
import '../../requests/domain/request_models.dart';

enum VerificationStatus {
  pendingReview,
  approved,
  rejected,
  suspended,
  unknown,
}

VerificationStatus parseVerificationStatus(Object? value) => switch (value) {
  'pending_review' => VerificationStatus.pendingReview,
  'approved' => VerificationStatus.approved,
  'rejected' => VerificationStatus.rejected,
  'suspended' => VerificationStatus.suspended,
  _ => VerificationStatus.unknown,
};

String verificationStatusParam(VerificationStatus status) => switch (status) {
  VerificationStatus.pendingReview => 'pending_review',
  VerificationStatus.approved => 'approved',
  VerificationStatus.rejected => 'rejected',
  VerificationStatus.suspended => 'suspended',
  VerificationStatus.unknown => 'pending_review',
};

/// [Proposed] document categories pending the verification checklist (D-06).
enum DocumentKind { identity, qualification, other }

DocumentKind parseDocumentKind(Object? value) => switch (value) {
  'identity' => DocumentKind.identity,
  'qualification' => DocumentKind.qualification,
  _ => DocumentKind.other,
};

class SpecialtyRef {
  const SpecialtyRef({
    required this.id,
    required this.slug,
    required this.name,
  });

  factory SpecialtyRef.fromJson(Map<String, dynamic> json) => SpecialtyRef(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: LocalizedText.fromJson(json['name']),
  );

  final String id;
  final String slug;
  final LocalizedText name;
}

class ApplicationDocument {
  const ApplicationDocument({
    required this.id,
    required this.kind,
    required this.contentType,
    required this.byteSize,
  });

  factory ApplicationDocument.fromJson(Map<String, dynamic> json) =>
      ApplicationDocument(
        id: json['id'] as String,
        kind: parseDocumentKind(json['kind']),
        contentType: json['contentType'] as String? ?? '',
        byteSize: json['byteSize'] as int? ?? 0,
      );

  final String id;
  final DocumentKind kind;
  final String contentType;
  final int byteSize;

  bool get isImage => contentType.startsWith('image/');
}

class TechnicianApplication {
  const TechnicianApplication({
    required this.id,
    required this.status,
    required this.fullName,
    this.yearsOfExperience,
    this.bio,
    required this.specialties,
    required this.serviceAreas,
    required this.documents,
    required this.submittedAt,
    this.reviewedAt,
    this.decisionReason,
    required this.canResubmit,
    required this.eligibleForWork,
  });

  factory TechnicianApplication.fromJson(Map<String, dynamic> json) =>
      TechnicianApplication(
        id: json['id'] as String,
        status: parseVerificationStatus(json['status']),
        fullName: json['fullName'] as String? ?? '',
        yearsOfExperience: json['yearsOfExperience'] as int?,
        bio: json['bio'] as String?,
        specialties: (json['specialties'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(SpecialtyRef.fromJson)
            .toList(growable: false),
        serviceAreas: (json['serviceAreas'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ServiceArea.fromJson)
            .toList(growable: false),
        documents: (json['documents'] as List<dynamic>? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(ApplicationDocument.fromJson)
            .toList(growable: false),
        submittedAt: DateTime.parse(json['submittedAt'] as String),
        reviewedAt: json['reviewedAt'] == null
            ? null
            : DateTime.parse(json['reviewedAt'] as String),
        decisionReason: json['decisionReason'] as String?,
        canResubmit: json['canResubmit'] as bool? ?? false,
        eligibleForWork: json['eligibleForWork'] as bool? ?? false,
      );

  final String id;
  final VerificationStatus status;
  final String fullName;
  final int? yearsOfExperience;
  final String? bio;
  final List<SpecialtyRef> specialties;
  final List<ServiceArea> serviceAreas;
  final List<ApplicationDocument> documents;
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? decisionReason;
  final bool canResubmit;
  final bool eligibleForWork;
}

class ApplicationRequirements {
  const ApplicationRequirements({
    required this.minDocuments,
    required this.maxDocuments,
    required this.uploadsAvailable,
  });

  factory ApplicationRequirements.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return ApplicationRequirements(
      minDocuments: map['minDocuments'] as int? ?? 0,
      maxDocuments: map['maxDocuments'] as int? ?? 10,
      uploadsAvailable: map['uploadsAvailable'] as bool? ?? false,
    );
  }

  final int minDocuments;
  final int maxDocuments;
  final bool uploadsAvailable;
}

class OwnApplicationState {
  const OwnApplicationState({this.application, required this.requirements});

  factory OwnApplicationState.fromJson(Map<String, dynamic> json) =>
      OwnApplicationState(
        application: json['application'] == null
            ? null
            : TechnicianApplication.fromJson(
                json['application'] as Map<String, dynamic>,
              ),
        requirements: ApplicationRequirements.fromJson(json['requirements']),
      );

  final TechnicianApplication? application;
  final ApplicationRequirements requirements;
}

class ApplicationSubmission {
  const ApplicationSubmission({
    required this.fullName,
    this.yearsOfExperience,
    this.bio,
    required this.specialtyCategoryIds,
    required this.serviceAreaIds,
    required this.documents,
  });

  final String fullName;
  final int? yearsOfExperience;
  final String? bio;
  final List<String> specialtyCategoryIds;
  final List<String> serviceAreaIds;
  final List<(String mediaId, DocumentKind kind)> documents;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
    if (bio != null && bio!.isNotEmpty) 'bio': bio,
    'specialtyCategoryIds': specialtyCategoryIds,
    'serviceAreaIds': serviceAreaIds,
    'documents': [
      for (final (id, kind) in documents) {'mediaId': id, 'kind': kind.name},
    ],
  };
}

/// Reviewer-only fields.
class ReviewApplication {
  const ReviewApplication({
    required this.application,
    required this.applicantPhone,
    this.applicantAccountName,
    required this.history,
  });

  factory ReviewApplication.fromJson(Map<String, dynamic> json) {
    final applicant = json['applicant'] as Map<String, dynamic>? ?? const {};
    return ReviewApplication(
      application: TechnicianApplication.fromJson(json),
      applicantPhone: applicant['phone'] as String? ?? '',
      applicantAccountName: applicant['accountName'] as String?,
      history: (json['history'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (h) => ReviewHistoryEntry(
              action: h['action'] as String? ?? '',
              at: DateTime.parse(h['at'] as String),
              reason: h['reason'] as String?,
            ),
          )
          .toList(growable: false),
    );
  }

  final TechnicianApplication application;
  final String applicantPhone;
  final String? applicantAccountName;
  final List<ReviewHistoryEntry> history;
}

class ReviewHistoryEntry {
  const ReviewHistoryEntry({
    required this.action,
    required this.at,
    this.reason,
  });

  final String action;
  final DateTime at;
  final String? reason;
}

class ApplicationSummary {
  const ApplicationSummary({
    required this.id,
    required this.status,
    required this.fullName,
    required this.specialtyCount,
    required this.areaCount,
    required this.documentCount,
    required this.submittedAt,
  });

  factory ApplicationSummary.fromJson(Map<String, dynamic> json) =>
      ApplicationSummary(
        id: json['id'] as String,
        status: parseVerificationStatus(json['status']),
        fullName: json['fullName'] as String? ?? '',
        specialtyCount: json['specialtyCount'] as int? ?? 0,
        areaCount: json['areaCount'] as int? ?? 0,
        documentCount: json['documentCount'] as int? ?? 0,
        submittedAt: DateTime.parse(json['submittedAt'] as String),
      );

  final String id;
  final VerificationStatus status;
  final String fullName;
  final int specialtyCount;
  final int areaCount;
  final int documentCount;
  final DateTime submittedAt;
}
