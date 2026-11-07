import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/ui.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../requests/presentation/request_detail_screen.dart';
import '../../requests/presentation/widgets/request_card.dart';
import '../domain/job_models.dart';

/// Incoming dispatch offers for the signed-in technician (FR-MAT).
class OffersScreen extends StatelessWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.offersTitle)),
      body: Column(
        children: [
          const _AvailabilityCard(),
          Expanded(child: _offerList(l10n, scope)),
        ],
      ),
    );
  }

  Widget _offerList(AppLocalizations l10n, AppScope scope) =>
      AsyncView<List<OfferedJob>>(
        load: scope.jobs.offers,
        refreshOn: scope.changes,
        builder: (context, offers, reload) => RefreshIndicator(
          onRefresh: reload,
          child: offers.isEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 120),
                    EmptyView(
                      message: l10n.offersEmpty,
                      icon: Icons.local_offer_outlined,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: offers.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm + 4),
                  itemBuilder: (context, i) => i == 0
                      ? Text(
                          l10n.offersIntro,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        )
                      : _OfferCard(job: offers[i - 1]),
                ),
        ),
      );
}

/// The technician's "available for new jobs" switch. Turning it off hands back pending
/// offers; accepted jobs are not affected.
class _AvailabilityCard extends StatefulWidget {
  const _AvailabilityCard();

  @override
  State<_AvailabilityCard> createState() => _AvailabilityCardState();
}

class _AvailabilityCardState extends State<_AvailabilityCard> {
  bool? _available;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_available == null) _load();
  }

  Future<void> _load() async {
    try {
      final value = await AppScope.of(context).jobs.availability();
      if (mounted) setState(() => _available = value);
    } catch (_) {
      // Leave the switch hidden; offers below still show any error.
    }
  }

  Future<void> _set(bool value) async {
    final l10n = AppLocalizations.of(context);
    final jobs = AppScope.of(context).jobs;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final saved = await jobs.setAvailability(value);
      if (mounted) setState(() => _available = saved);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(messageForError(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _available;
    if (available == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        0,
      ),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: SwitchListTile(
          value: available,
          onChanged: _busy ? null : _set,
          secondary: Icon(
            available ? Icons.toggle_on_rounded : Icons.toggle_off_outlined,
            color: available ? AppColors.success.$1 : AppColors.muted,
          ),
          title: Text(
            l10n.availabilityTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            available ? l10n.availabilityOnNote : l10n.availabilityOffNote,
          ),
        ),
      ),
    );
  }
}

class _OfferCard extends StatefulWidget {
  const _OfferCard({required this.job});

  final OfferedJob job;

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    final l10n = AppLocalizations.of(context);
    final jobs = AppScope.of(context).jobs;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      if (accept) {
        final detail = await jobs.accept(widget.job.offer.id);
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.offerAcceptedToast)),
        );
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => RequestDetailScreen(requestId: detail.summary.id),
          ),
        );
      } else {
        await jobs.decline(widget.job.offer.id);
      }
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(messageForError(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final minutes = widget.job.offer.expiresAt
        .difference(DateTime.now())
        .inMinutes
        .clamp(0, 999);
    return RequestCard(
      request: widget.job.request,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TonePill(
              label: l10n.offerExpiresIn(minutes),
              tone: minutes < 5 ? AppColors.danger : AppColors.warning,
              icon: Icons.timer_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy ? null : () => _respond(false),
                  child: Text(l10n.declineOfferButton),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: _busy ? null : () => _respond(true),
                  child: Text(l10n.acceptOfferButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
