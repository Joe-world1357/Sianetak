import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/request_models.dart';

/// Where a request is in the service journey, as a segmented bar.
class JourneyProgress extends StatelessWidget {
  const JourneyProgress({super.key, required this.status, this.onDark = false});

  final RequestStatus status;
  final bool onDark;

  static const steps = 7;

  static int stepOf(RequestStatus status) => switch (status) {
    RequestStatus.submitted || RequestStatus.unmatched => 1,
    RequestStatus.assigned => 2,
    RequestStatus.enRoute => 3,
    RequestStatus.arrived => 4,
    RequestStatus.quoted || RequestStatus.quoteRejected => 5,
    RequestStatus.inProgress => 6,
    RequestStatus.completed => 7,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final step = stepOf(status);
    final done = onDark ? Colors.white : AppColors.primary;
    final todo = onDark ? Colors.white.withValues(alpha: 0.25) : AppColors.line;
    return Semantics(
      label: l10n.journeyStep(step, steps),
      child: ExcludeSemantics(
        child: Row(
          children: [
            for (var i = 1; i <= steps; i++) ...[
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  decoration: BoxDecoration(
                    color: i <= step ? done : todo,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              if (i < steps) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}
