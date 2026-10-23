import 'package:flutter/material.dart';

import '../../../core/format/money.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/catalog_models.dart';

/// One-line pricing guidance (FR-REQ-06).
class PriceGuidanceText extends StatelessWidget {
  const PriceGuidanceText({super.key, required this.pricing, this.style});

  final PricingGuidance pricing;
  final TextStyle? style;

  static String label(
    AppLocalizations l10n,
    PricingGuidance pricing,
    String lang,
  ) => switch (pricing.type) {
    PricingType.indicative => l10n.priceIndicativeRange(
      formatEgp(pricing.minMinor!, lang),
      formatEgp(pricing.maxMinor!, lang),
    ),
    PricingType.inspectionRequired => l10n.priceInspectionRequired,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Text(
      label(l10n, pricing, lang),
      style:
          style ??
          Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.primary),
    );
  }
}
