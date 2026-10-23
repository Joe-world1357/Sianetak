import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/sample_badge.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/sign_in_screen.dart';
import '../domain/catalog_models.dart';
import 'price_guidance_text.dart';

/// Service details with pricing guidance. Requesting requires sign-in (FR-AUTH-03);
/// request submission itself arrives in Sprint 2.
class ServiceDetailScreen extends StatelessWidget {
  const ServiceDetailScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  final String slug;
  final LocalizedText title;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final catalog = AppScope.of(context).catalog;
    return Scaffold(
      appBar: AppBar(title: Text(title.resolve(lang))),
      body: AsyncView<ServiceDetail>(
        load: () => catalog.getService(slug),
        builder: (context, detail, _) => _ServiceDetailBody(detail: detail),
      ),
    );
  }
}

class _ServiceDetailBody extends StatelessWidget {
  const _ServiceDetailBody({required this.detail});

  final ServiceDetail detail;

  Future<void> _onRequest(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final auth = AppScope.of(context).auth;
    if (!auth.isSignedIn) {
      final signedIn = await Navigator.of(context)
          .push<bool>(MaterialPageRoute(builder: (_) => const SignInScreen()));
      if (signedIn != true || !context.mounted) return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.requestComingSoon)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final service = detail.summary;
    final description = detail.description?.resolve(lang);
    final pricing = service.pricing;
    final auth = AppScope.of(context).auth;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                detail.categoryName.resolve(lang),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Semantics(
                header: true,
                child: Text(
                  service.name.resolve(lang),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (service.isSample) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const SampleBadge(),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.sampleDataNotice,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (description != null && description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.aboutServiceTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: AppSpacing.lg),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.pricingTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PriceGuidanceText(
                        pricing: pricing,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        pricing.type == PricingType.indicative
                            ? l10n.priceIndicativeExplanation
                            : l10n.priceInspectionExplanation,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ListenableBuilder(
              listenable: auth,
              builder: (context, _) => FilledButton(
                onPressed: () => _onRequest(context),
                child: Text(
                  auth.isSignedIn
                      ? l10n.requestServiceButton
                      : l10n.signInToRequest,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
