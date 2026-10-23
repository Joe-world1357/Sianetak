import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/format/dates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/private_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/egypt_phone.dart';
import '../../technician/domain/technician_models.dart';
import '../../technician/presentation/verification_status_view.dart';
import '../data/admin_repository.dart';

const _filters = [
  VerificationStatus.pendingReview,
  VerificationStatus.approved,
  VerificationStatus.rejected,
  VerificationStatus.suspended,
];

/// Admin-only queue of technician applications, filtered by status. Access is enforced by the
/// server; this screen is only reachable from an admin profile.
class AdminApplicationsScreen extends StatefulWidget {
  const AdminApplicationsScreen({super.key});

  @override
  State<AdminApplicationsScreen> createState() =>
      _AdminApplicationsScreenState();
}

class _AdminApplicationsScreenState extends State<AdminApplicationsScreen> {
  VerificationStatus _status = VerificationStatus.pendingReview;
  Future<List<ApplicationSummary>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).admin.listApplications(_status);
  }

  Future<void> _reload() {
    final future = AppScope.of(context).admin.listApplications(_status);
    setState(() {
      _future = future;
    });
    return future.then((_) {}, onError: (_) {});
  }

  void _select(VerificationStatus status) {
    _status = status;
    _reload();
  }

  Future<void> _open(ApplicationSummary summary) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminApplicationDetailScreen(applicationId: summary.id),
      ),
    );
    if (changed == true && mounted) await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.adminApplicationsTitle)),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                for (final s in _filters)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xs,
                    ),
                    child: ChoiceChip(
                      label: Text(verificationStatusLabel(l10n, s)),
                      selected: _status == s,
                      onSelected: (_) => _select(s),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ApplicationSummary>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const LoadingView();
                }
                if (snapshot.hasError) {
                  return ErrorView(error: snapshot.error!, onRetry: _reload);
                }
                final items = snapshot.data ?? const [];
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _reload,
                    child: ListView(
                      children: [
                        const SizedBox(height: AppSpacing.xl),
                        EmptyView(message: l10n.adminApplicationsEmpty),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final a = items[i];
                      return ListTile(
                        leading: Icon(verificationStatusIcon(a.status)),
                        title: Text(a.fullName),
                        subtitle: Text(
                          '${l10n.adminApplicationMeta(a.specialtyCount, a.areaCount, a.documentCount)}\n'
                          '${l10n.submittedOn(formatDateTime(a.submittedAt, lang))}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _open(a),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// One application with the applicant's contact details, documents and review history, plus the
/// decision actions valid for its current status.
class AdminApplicationDetailScreen extends StatefulWidget {
  const AdminApplicationDetailScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  State<AdminApplicationDetailScreen> createState() =>
      _AdminApplicationDetailScreenState();
}

class _AdminApplicationDetailScreenState
    extends State<AdminApplicationDetailScreen> {
  Future<ReviewApplication>? _future;
  bool _busy = false;
  bool _changed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).admin.getApplication(widget.applicationId);
  }

  void _reload() {
    setState(() {
      _future = AppScope.of(context).admin.getApplication(widget.applicationId);
    });
  }

  Future<void> _decide(ReviewAction action) async {
    final l10n = AppLocalizations.of(context);
    final admin = AppScope.of(context).admin;
    final messenger = ScaffoldMessenger.of(context);
    final input = await showDialog<_DecisionInput>(
      context: context,
      builder: (_) => _DecisionDialog(action: action),
    );
    if (input == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final updated = await admin.decide(
        widget.applicationId,
        action,
        reason: input.text,
      );
      if (!mounted) return;
      _changed = true;
      setState(() {
        _future = Future.value(updated);
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.adminDecisionSaved)));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(messageForError(l10n, e))));
      _reload();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.adminApplicationsTitle)),
        body: FutureBuilder<ReviewApplication>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingView();
            }
            if (snapshot.hasError) {
              return ErrorView(error: snapshot.error!, onRetry: _reload);
            }
            return _DetailBody(
              review: snapshot.data!,
              busy: _busy,
              onDecide: _decide,
            );
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.review,
    required this.busy,
    required this.onDecide,
  });

  final ReviewApplication review;
  final bool busy;
  final void Function(ReviewAction action) onDecide;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final a = review.application;

    final actions = <Widget>[
      if (a.status == VerificationStatus.pendingReview) ...[
        FilledButton(
          onPressed: busy ? null : () => onDecide(ReviewAction.approve),
          child: Text(l10n.adminApproveButton),
        ),
        OutlinedButton(
          onPressed: busy ? null : () => onDecide(ReviewAction.reject),
          child: Text(l10n.adminRejectButton),
        ),
      ],
      if (a.status == VerificationStatus.approved)
        OutlinedButton(
          onPressed: busy ? null : () => onDecide(ReviewAction.suspend),
          child: Text(l10n.adminSuspendButton),
        ),
      if (a.status == VerificationStatus.suspended)
        FilledButton(
          onPressed: busy ? null : () => onDecide(ReviewAction.approve),
          child: Text(l10n.adminReinstateButton),
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            Icon(verificationStatusIcon(a.status)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              verificationStatusLabel(l10n, a.status),
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(a.fullName, style: theme.textTheme.titleLarge),
        Text(
          '${l10n.adminApplicantPhone}: '
          '${isolateLtr(displayLocalPhone(review.applicantPhone))}',
        ),
        if (a.yearsOfExperience != null)
          Text(l10n.yearsValue(a.yearsOfExperience!)),
        if (a.bio != null && a.bio!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(a.bio!),
        ],
        Text(l10n.submittedOn(formatDateTime(a.submittedAt, lang))),
        if (a.decisionReason != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(l10n.decisionReasonLabel, style: theme.textTheme.labelLarge),
          Text(a.decisionReason!),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(l10n.specialtiesTitle, style: theme.textTheme.labelLarge),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final s in a.specialties)
              Chip(label: Text(s.name.resolve(lang))),
          ],
        ),
        Text(l10n.serviceAreasTitle, style: theme.textTheme.labelLarge),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            for (final area in a.serviceAreas)
              Chip(label: Text(area.name.resolve(lang))),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(l10n.documentsTitle, style: theme.textTheme.labelLarge),
        if (a.documents.isEmpty) Text(l10n.documentsNone),
        for (final (i, d) in a.documents.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${l10n.documentNumber(i + 1)} · ${documentKindLabel(l10n, d.kind)}',
                ),
                const SizedBox(height: AppSpacing.xs),
                if (d.isImage)
                  SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PrivateImage(
                        mediaId: d.id,
                        semanticLabel: l10n.documentNumber(i + 1),
                        fit: BoxFit.contain,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.picture_as_pdf_outlined),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(child: Text(l10n.pdfDocumentLabel)),
                    ],
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(l10n.adminHistoryTitle, style: theme.textTheme.labelLarge),
        for (final h in review.history)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(_historyLabel(l10n, h.action)),
            subtitle: Text([formatDateTime(h.at, lang), ?h.reason].join('\n')),
          ),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: actions,
          ),
        ],
      ],
    );
  }
}

String _historyLabel(AppLocalizations l10n, String action) =>
    switch (action.split('.').last) {
      'submitted' => l10n.historySubmitted,
      'resubmitted' => l10n.historyResubmitted,
      'approved' => l10n.historyApproved,
      'rejected' => l10n.historyRejected,
      'suspended' => l10n.historySuspended,
      _ => action,
    };

class _DecisionInput {
  const _DecisionInput(this.text);

  final String? text;
}

/// Confirms a decision. Reject and suspend require a reason the applicant will see; approve takes
/// an optional internal note.
class _DecisionDialog extends StatefulWidget {
  const _DecisionDialog({required this.action});

  final ReviewAction action;

  @override
  State<_DecisionDialog> createState() => _DecisionDialogState();
}

class _DecisionDialogState extends State<_DecisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _text = TextEditingController();

  bool get _reasonRequired => widget.action != ReviewAction.approve;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final value = _text.text.trim();
    Navigator.of(context).pop(_DecisionInput(value.isEmpty ? null : value));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, confirm) = switch (widget.action) {
      ReviewAction.approve => (l10n.adminApproveTitle, l10n.adminApproveButton),
      ReviewAction.reject => (l10n.adminRejectTitle, l10n.adminRejectButton),
      ReviewAction.suspend => (l10n.adminSuspendTitle, l10n.adminSuspendButton),
    };
    return AlertDialog(
      title: Text(title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_reasonRequired) Text(l10n.adminApproveBody),
            TextFormField(
              controller: _text,
              maxLength: 500,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: _reasonRequired
                    ? l10n.adminReasonLabel
                    : l10n.adminNoteLabel,
              ),
              validator: (v) {
                final t = (v ?? '').trim();
                if (_reasonRequired && t.length < 3) {
                  return l10n.adminReasonRequired;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _submit, child: Text(confirm)),
      ],
    );
  }
}
