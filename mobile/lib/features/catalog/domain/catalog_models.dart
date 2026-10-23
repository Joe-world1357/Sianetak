/// Catalog models parsed from the backend's `/catalog` API.
library;

class LocalizedText {
  const LocalizedText({required this.ar, required this.en});

  factory LocalizedText.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final ar = map['ar'] as String? ?? '';
    final en = map['en'] as String? ?? '';
    return LocalizedText(ar: ar.isEmpty ? en : ar, en: en.isEmpty ? ar : en);
  }

  final String ar;
  final String en;

  String resolve(String languageCode) => languageCode == 'ar' ? ar : en;
}

enum PricingType { indicative, inspectionRequired }

/// FR-REQ-06: either an approved indicative range, or "price set after inspection".
class PricingGuidance {
  const PricingGuidance.inspectionRequired({this.currency = 'EGP'})
    : type = PricingType.inspectionRequired,
      minMinor = null,
      maxMinor = null;

  const PricingGuidance.indicative({
    required int this.minMinor,
    required int this.maxMinor,
    this.currency = 'EGP',
  }) : type = PricingType.indicative;

  /// Anything unexpected falls back to inspection-required: never show an unverified price.
  factory PricingGuidance.fromJson(Object? json) {
    final map = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    final currency = map['currency'] as String? ?? 'EGP';
    final min = map['minMinor'];
    final max = map['maxMinor'];
    if (map['type'] == 'indicative' &&
        min is int &&
        max is int &&
        min > 0 &&
        max >= min) {
      return PricingGuidance.indicative(
        minMinor: min,
        maxMinor: max,
        currency: currency,
      );
    }
    return PricingGuidance.inspectionRequired(currency: currency);
  }

  final PricingType type;
  final int? minMinor;
  final int? maxMinor;
  final String currency;
}

class ServiceCategory {
  const ServiceCategory({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.iconKey,
    required this.serviceCount,
    required this.isSample,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) =>
      ServiceCategory(
        id: json['id'] as String,
        slug: json['slug'] as String,
        name: LocalizedText.fromJson(json['name']),
        description: json['description'] == null
            ? null
            : LocalizedText.fromJson(json['description']),
        iconKey: json['iconKey'] as String?,
        serviceCount: json['serviceCount'] as int? ?? 0,
        isSample: json['isSample'] as bool? ?? false,
      );

  final String id;
  final String slug;
  final LocalizedText name;
  final LocalizedText? description;
  final String? iconKey;
  final int serviceCount;
  final bool isSample;
}

class ServiceSummary {
  const ServiceSummary({
    required this.id,
    required this.slug,
    required this.name,
    required this.pricing,
    required this.isSample,
  });

  factory ServiceSummary.fromJson(Map<String, dynamic> json) => ServiceSummary(
    id: json['id'] as String,
    slug: json['slug'] as String,
    name: LocalizedText.fromJson(json['name']),
    pricing: PricingGuidance.fromJson(json['pricing']),
    isSample: json['isSample'] as bool? ?? false,
  );

  final String id;
  final String slug;
  final LocalizedText name;
  final PricingGuidance pricing;
  final bool isSample;
}

class CategoryDetail {
  const CategoryDetail({required this.category, required this.services});

  factory CategoryDetail.fromJson(Map<String, dynamic> json) => CategoryDetail(
    category: ServiceCategory.fromJson(json),
    services: (json['services'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ServiceSummary.fromJson)
        .toList(growable: false),
  );

  final ServiceCategory category;
  final List<ServiceSummary> services;
}

class ServiceDetail {
  const ServiceDetail({
    required this.summary,
    this.description,
    required this.categorySlug,
    required this.categoryName,
  });

  factory ServiceDetail.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>? ?? const {};
    return ServiceDetail(
      summary: ServiceSummary.fromJson(json),
      description: json['description'] == null
          ? null
          : LocalizedText.fromJson(json['description']),
      categorySlug: category['slug'] as String? ?? '',
      categoryName: LocalizedText.fromJson(category['name']),
    );
  }

  final ServiceSummary summary;
  final LocalizedText? description;
  final String categorySlug;
  final LocalizedText categoryName;
}
