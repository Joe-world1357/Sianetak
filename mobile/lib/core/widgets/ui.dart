import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A titled white card used to group related content on detail screens.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    this.title,
    this.icon,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
  });

  final String? title;
  final IconData? icon;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    ExcludeSemantics(
                      child: Icon(icon, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// A small rounded label in one of the [AppColors] status tones.
class TonePill extends StatelessWidget {
  const TonePill({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final (Color, Color) tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tone;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + 2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: 14, color: fg)),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: fg, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Icon, muted label and value on one line.
class InfoRow extends StatelessWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 20, color: AppColors.muted)),
          const SizedBox(width: AppSpacing.sm + 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.muted,
                  ),
                ),
                Text(value, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Round icon on a tinted background.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    this.tone = AppColors.info,
    this.size = 44,
  });

  final IconData icon;
  final (Color, Color) tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = tone;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(size * 0.32),
        ),
        child: Icon(icon, color: fg, size: size * 0.5),
      ),
    );
  }
}

/// Five stars, read-only or tappable.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.value,
    this.size = 18,
    this.onChanged,
    this.semanticLabel,
  });

  final double value;
  final double size;
  final ValueChanged<int>? onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    const gold = Color(0xFFE0A100);
    return Semantics(
      label: semanticLabel,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 1; i <= 5; i++)
            onChanged == null
                ? Icon(
                    value >= i - 0.25
                        ? Icons.star_rounded
                        : value >= i - 0.75
                        ? Icons.star_half_rounded
                        : Icons.star_outline_rounded,
                    size: size,
                    color: gold,
                  )
                : IconButton(
                    tooltip: '$i',
                    iconSize: size,
                    onPressed: () => onChanged!(i),
                    icon: Icon(
                      value >= i
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: gold,
                    ),
                  ),
        ],
      ),
    );
  }
}

/// The app's mark: a rounded tile with the brand gradient.
class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Icon(
        Icons.home_repair_service_rounded,
        color: Colors.white,
        size: size * 0.5,
      ),
    ),
  );
}
