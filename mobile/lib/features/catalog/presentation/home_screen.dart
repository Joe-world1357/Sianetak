import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bar_actions.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/category_icon.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/catalog_models.dart';
import 'category_screen.dart';

/// Guest home: browse service categories (FR-AUTH-02, FR-REQ-01).
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final catalog = AppScope.of(context).catalog;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppMark(size: 32),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                l10n.appTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        actions: const [AppBarActions()],
      ),
      body: AsyncView<List<ServiceCategory>>(
        load: catalog.listCategories,
        builder: (context, categories, reload) {
          if (categories.isEmpty) {
            return RefreshIndicator(
              onRefresh: reload,
              child: ListView(
                children: [
                  const SizedBox(height: 120),
                  EmptyView(message: l10n.emptyCategories),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: reload,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  sliver: SliverToBoxAdapter(child: _Header(l10n: l10n)),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  sliver: SliverGrid.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 240,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          // Tall enough for two lines of text at larger text scales.
                          mainAxisExtent: 148,
                        ),
                    itemCount: categories.length,
                    itemBuilder: (context, i) =>
                        CategoryCard(category: categories[i]),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AppScope.of(context).auth;
    final name = auth.user?.name?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (name != null && name.isNotEmpty)
          Text(
            l10n.homeGreeting(name.split(' ').first),
            style: theme.textTheme.bodyLarge?.copyWith(color: AppColors.muted),
          ),
        Semantics(
          header: true,
          child: Text(
            l10n.homeHeadline,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.homeSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.category});

  final ServiceCategory category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final name = category.name.resolve(lang);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CategoryScreen(category: category),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon: iconForCategory(category.iconKey), size: 48),
              const Spacer(),
              Text(
                name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                l10n.servicesCount(category.serviceCount),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
