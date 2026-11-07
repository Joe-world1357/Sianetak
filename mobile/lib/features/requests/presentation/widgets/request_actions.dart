import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/app_scope.dart';
import '../../../../core/format/money.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../../core/widgets/ui.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/domain/auth_models.dart';
import '../../../jobs/domain/job_models.dart';
import '../../domain/request_models.dart';

/// The next step(s) the viewer can take on a request. Renders nothing when there are none.
class RequestActions extends StatefulWidget {
  const RequestActions({super.key, required this.detail, required this.role});

  final RequestDetail detail;
  final UserRole role;

  @override
  State<RequestActions> createState() => _RequestActionsState();
}

class _RequestActionsState extends State<RequestActions> {
  bool _busy = false;

  RequestDetail get d => widget.detail;
  String get _id => d.summary.id;

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await action();
      if (done != null) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(done)));
      }
    } catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(messageForError(l10n, e))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = switch (widget.role) {
      UserRole.customer => _customer(context),
      UserRole.technician => _technician(context),
      UserRole.admin => _admin(context),
      UserRole.unknown => const <Widget>[],
    };
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }

  Widget _note(IconData icon, String title, String body, (Color, Color) tone) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconBadge(icon: icon, tone: tone, size: 40),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static const _space = SizedBox(height: AppSpacing.md);

  Widget _cancelButton(AppLocalizations l10n) => TextButton.icon(
    onPressed: _busy ? null : _cancel,
    style: TextButton.styleFrom(
      foregroundColor: Theme.of(context).colorScheme.error,
    ),
    icon: const Icon(Icons.close_rounded),
    label: Text(l10n.cancelRequestButton),
  );

  // --- Customer ---------------------------------------------------------------------------

  List<Widget> _customer(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final status = d.summary.status;
    final requests = AppScope.of(context).requests;
    return [
      if (status == RequestStatus.submitted)
        _note(
          Icons.travel_explore_rounded,
          l10n.customerSearchingTitle,
          l10n.customerSearchingBody,
          AppColors.info,
        ),
      if (status == RequestStatus.unmatched)
        _note(
          Icons.support_agent_rounded,
          l10n.customerUnmatchedTitle,
          l10n.customerUnmatchedBody,
          AppColors.warning,
        ),
      if (status == RequestStatus.assigned ||
          status == RequestStatus.enRoute ||
          status == RequestStatus.arrived)
        _note(
          Icons.how_to_reg_rounded,
          l10n.customerAssignedTitle,
          l10n.customerAssignedBody,
          AppColors.progress,
        ),
      if (status == RequestStatus.quoteRejected)
        _note(
          Icons.hourglass_top_rounded,
          l10n.customerQuoteRejectedTitle,
          l10n.customerQuoteRejectedBody,
          AppColors.warning,
        ),
      if (status == RequestStatus.inProgress)
        _note(
          Icons.handyman_rounded,
          l10n.customerInProgressTitle,
          l10n.customerInProgressBody,
          AppColors.progress,
        ),
      if (status == RequestStatus.quoted && d.quote != null) ...[
        _note(
          Icons.request_quote_rounded,
          l10n.customerQuoteTitle(formatEgp(d.quote!.amountMinor, lang)),
          l10n.customerQuoteBody,
          AppColors.warning,
        ),
        _space,
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _run(
                  () => requests.decideQuote(_id, approve: true),
                  done: l10n.quoteApprovedToast,
                ),
          icon: const Icon(Icons.check_rounded),
          label: Text(l10n.approveQuoteButton),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run(() => requests.decideQuote(_id, approve: false)),
          child: Text(l10n.rejectQuoteButton),
        ),
      ],
      if (status == RequestStatus.completed && d.rating == null) ...[
        _note(
          Icons.task_alt_rounded,
          l10n.customerCompletedTitle,
          l10n.customerCompletedBody,
          AppColors.success,
        ),
        _space,
        FilledButton.icon(
          onPressed: _busy ? null : _rate,
          icon: const Icon(Icons.star_rounded),
          label: Text(l10n.rateButton),
        ),
      ],
      if (status.isCancellable) ...[
        const SizedBox(height: AppSpacing.sm),
        _cancelButton(l10n),
      ],
    ];
  }

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final requests = AppScope.of(context).requests;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CancelSheet(),
    );
    if (reason == null || !mounted) return;
    await _run(
      () => requests.cancel(_id, reason),
      done: l10n.requestCancelledToast,
    );
  }

  Future<void> _rate() async {
    final l10n = AppLocalizations.of(context);
    final requests = AppScope.of(context).requests;
    final result = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _RatingSheet(),
    );
    if (result == null || !mounted) return;
    await _run(
      () => requests.rate(_id, result.$1, comment: result.$2),
      done: l10n.ratingThanks,
    );
  }

  // --- Technician -------------------------------------------------------------------------

  List<Widget> _technician(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final jobs = AppScope.of(context).jobs;
    final status = d.summary.status;
    final offer = d.offer;
    Widget step(IconData icon, String label, JobStep to, String done) =>
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _run(() => jobs.advance(_id, to), done: done),
          icon: Icon(icon),
          label: Text(label),
        );
    if (offer != null && offer.status == OfferStatus.pending) {
      return [
        _OfferCountdown(expiresAt: offer.expiresAt),
        _space,
        FilledButton.icon(
          onPressed: _busy
              ? null
              : () => _run(
                  () => jobs.accept(offer.id),
                  done: l10n.offerAcceptedToast,
                ),
          icon: const Icon(Icons.check_rounded),
          label: Text(l10n.acceptOfferButton),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () async {
                  final navigator = Navigator.of(context);
                  await _run(() => jobs.decline(offer.id));
                  if (navigator.canPop()) navigator.pop();
                },
          child: Text(l10n.declineOfferButton),
        ),
      ];
    }
    return switch (status) {
      RequestStatus.assigned => [
        _note(
          Icons.how_to_reg_rounded,
          l10n.techAssignedTitle,
          l10n.techAssignedBody,
          AppColors.progress,
        ),
        _space,
        step(
          Icons.directions_car_rounded,
          l10n.onMyWayButton,
          JobStep.enRoute,
          l10n.customerNotifiedToast,
        ),
      ],
      RequestStatus.enRoute => [
        step(
          Icons.location_on_rounded,
          l10n.arrivedButton,
          JobStep.arrived,
          l10n.customerNotifiedToast,
        ),
      ],
      RequestStatus.arrived || RequestStatus.quoteRejected => [
        _note(
          Icons.request_quote_rounded,
          status == RequestStatus.arrived
              ? l10n.techQuoteNeededTitle
              : l10n.techQuoteRejectedTitle,
          l10n.techQuoteNeededBody,
          AppColors.warning,
        ),
        _space,
        FilledButton.icon(
          onPressed: _busy ? null : _sendQuote,
          icon: const Icon(Icons.edit_note_rounded),
          label: Text(l10n.sendQuoteButton),
        ),
      ],
      RequestStatus.quoted => [
        _note(
          Icons.hourglass_top_rounded,
          l10n.techAwaitingApprovalTitle,
          l10n.techAwaitingApprovalBody,
          AppColors.warning,
        ),
      ],
      RequestStatus.inProgress => [
        _note(
          Icons.handyman_rounded,
          l10n.techWorkingTitle,
          l10n.techWorkingBody(formatEgp(d.quote?.amountMinor ?? 0, lang)),
          AppColors.progress,
        ),
        _space,
        FilledButton.icon(
          onPressed: _busy ? null : _complete,
          icon: const Icon(Icons.task_alt_rounded),
          label: Text(l10n.completeJobButton),
        ),
      ],
      _ => const <Widget>[],
    };
  }

  Future<void> _sendQuote() async {
    final l10n = AppLocalizations.of(context);
    final jobs = AppScope.of(context).jobs;
    final result = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _QuoteSheet(),
    );
    if (result == null || !mounted) return;
    await _run(
      () => jobs.sendQuote(_id, result.$1, note: result.$2),
      done: l10n.quoteSentToast,
    );
  }

  Future<void> _complete() async {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final jobs = AppScope.of(context).jobs;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.completeJobTitle),
        content: Text(
          l10n.completeJobBody(formatEgp(d.quote?.amountMinor ?? 0, lang)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirmButton),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run(
      () => jobs.advance(_id, JobStep.complete),
      done: l10n.jobCompletedToast,
    );
  }

  // --- Admin ------------------------------------------------------------------------------

  List<Widget> _admin(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final status = d.summary.status;
    return [
      if (status == RequestStatus.submitted ||
          status == RequestStatus.unmatched) ...[
        _note(
          status == RequestStatus.unmatched
              ? Icons.support_agent_rounded
              : Icons.travel_explore_rounded,
          status == RequestStatus.unmatched
              ? l10n.adminUnmatchedTitle
              : l10n.adminSearchingTitle,
          l10n.adminAssignBody,
          status == RequestStatus.unmatched
              ? AppColors.warning
              : AppColors.info,
        ),
        _space,
        FilledButton.icon(
          onPressed: _busy ? null : _assign,
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: Text(l10n.assignTechnicianButton),
        ),
      ],
      if (status.isCancellable) ...[
        const SizedBox(height: AppSpacing.sm),
        _cancelButton(l10n),
      ],
    ];
  }

  Future<void> _assign() async {
    final l10n = AppLocalizations.of(context);
    final admin = AppScope.of(context).admin;
    final technicianId = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => _AssignSheet(requestId: _id),
    );
    if (technicianId == null || !mounted) return;
    await _run(() => admin.assign(_id, technicianId), done: l10n.assignedToast);
  }
}

class _OfferCountdown extends StatefulWidget {
  const _OfferCountdown({required this.expiresAt});

  final DateTime expiresAt;

  @override
  State<_OfferCountdown> createState() => _OfferCountdownState();
}

class _OfferCountdownState extends State<_OfferCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final minutes = widget.expiresAt
        .difference(DateTime.now())
        .inMinutes
        .clamp(0, 999);
    return Row(
      children: [
        const IconBadge(
          icon: Icons.local_offer_rounded,
          tone: AppColors.info,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.offerForYouTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                l10n.offerExpiresIn(minutes),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom-sheet scaffold with a title, consistent padding and keyboard inset.
class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _CancelSheet extends StatefulWidget {
  const _CancelSheet();

  @override
  State<_CancelSheet> createState() => _CancelSheetState();
}

class _CancelSheetState extends State<_CancelSheet> {
  int? _choice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reasons = [
      l10n.cancelReasonChangedMind,
      l10n.cancelReasonFixed,
      l10n.cancelReasonTooLong,
      l10n.cancelReasonOther,
    ];
    return _SheetFrame(
      title: l10n.cancelSheetTitle,
      children: [
        RadioGroup<int>(
          groupValue: _choice,
          onChanged: (v) => setState(() => _choice = v),
          child: Column(
            children: [
              for (final (i, r) in reasons.indexed)
                RadioListTile<int>(
                  value: i,
                  title: Text(r),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: _choice == null
              ? null
              : () => Navigator.pop(context, reasons[_choice!]),
          child: Text(l10n.cancelRequestButton),
        ),
      ],
    );
  }
}

class _RatingSheet extends StatefulWidget {
  const _RatingSheet();

  @override
  State<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends State<_RatingSheet> {
  int _stars = 0;
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetFrame(
      title: l10n.rateSheetTitle,
      children: [
        Center(
          child: StarRating(
            value: _stars.toDouble(),
            size: 36,
            onChanged: (v) => setState(() => _stars = v),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _comment,
          maxLength: 300,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.rateCommentLabel),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: _stars == 0
              ? null
              : () => Navigator.pop(context, (_stars, _comment.text)),
          child: Text(l10n.rateSubmitButton),
        ),
      ],
    );
  }
}

class _QuoteSheet extends StatefulWidget {
  const _QuoteSheet();

  @override
  State<_QuoteSheet> createState() => _QuoteSheetState();
}

class _QuoteSheetState extends State<_QuoteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  static int? _parsePounds(String raw) {
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final western = raw.trim().split('').map((c) {
      final i = eastern.indexOf(c);
      return i >= 0 ? '$i' : c;
    }).join();
    final value = int.tryParse(western);
    return value == null || value <= 0 || value > 100000 ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SheetFrame(
      title: l10n.quoteSheetTitle,
      children: [
        Text(l10n.quoteSheetHint),
        const SizedBox(height: AppSpacing.md),
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: l10n.quoteAmountLabel,
                  suffixText: l10n.currencyEgpShort,
                ),
                validator: (v) => _parsePounds(v ?? '') == null
                    ? l10n.quoteAmountInvalid
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _note,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.quoteNoteLabel),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        FilledButton(
          onPressed: () {
            if (!(_formKey.currentState?.validate() ?? false)) return;
            Navigator.pop(context, (
              _parsePounds(_amount.text)! * 100,
              _note.text,
            ));
          },
          child: Text(l10n.sendQuoteButton),
        ),
      ],
    );
  }
}

class _AssignSheet extends StatelessWidget {
  const _AssignSheet({required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final admin = AppScope.of(context).admin;
    return FutureBuilder<List<PersonRef>>(
      future: admin.assignableTechnicians(requestId),
      builder: (context, snapshot) {
        final items = snapshot.data;
        return _SheetFrame(
          title: l10n.assignSheetTitle,
          children: [
            if (items == null)
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (items.isEmpty)
              Text(l10n.assignNoneEligible)
            else
              for (final t in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const IconBadge(
                    icon: Icons.engineering_rounded,
                    size: 40,
                  ),
                  title: Text(t.name),
                  subtitle: Text(
                    t.rating == null
                        ? l10n.ratingNone
                        : l10n.ratingSummary(
                            t.rating!.toStringAsFixed(1),
                            t.ratingCount,
                          ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, t.id),
                ),
          ],
        );
      },
    );
  }
}
