import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/sample_badge.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/catalog_models.dart';
import 'price_guidance_text.dart';
import 'service_detail_screen.dart';

/// Services within one category, with pricing guidance per service.
class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key, required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final catalog = AppScope.of(context).catalog;
    return Scaffold(
      appBar: AppBar(title: Text(category.name.resolve(lang))),
      body: AsyncView<CategoryDetail>(
        load: () => catalog.getCategory(category.slug),
        builder: (context, detail, reload) {
          final description = detail.category.description?.resolve(lang);
          return RefreshIndicator(
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                if (description != null && description.isNotEmpty) ...[
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (detail.services.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: EmptyView(message: l10n.emptyServices),
                  )
                else
                  for (final service in detail.services) ...[
                    _ServiceTile(service: service),
                    const SizedBox(height: AppSpacing.sm),
                  ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service});

  final ServiceSummary service;

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsetsDirectional.fromSTEB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        title: Text(
          service.name.resolve(lang),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PriceGuidanceText(pricing: service.pricing),
              if (service.isSample) const SampleBadge(),
            ],
          ),
        ),
        // Chevron points "forward" in both directions.
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                ServiceDetailScreen(slug: service.slug, title: service.name),
          ),
        ),
      ),
    );
  }
}
