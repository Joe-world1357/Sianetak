import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/device/image_picker_service.dart';
import '../../../core/device/location_service.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_error_text.dart';
import '../../catalog/domain/catalog_models.dart';
import '../application/request_draft_controller.dart';
import '../domain/request_models.dart';
import 'request_success_screen.dart';
import 'widgets/describe_step.dart';
import 'widgets/draft_issue_text.dart';
import 'widgets/location_step.dart';
import 'widgets/review_step.dart';
import 'widgets/schedule_step.dart';

/// Four-step request flow: problem → address → time → review and send.
class CreateRequestScreen extends StatelessWidget {
  const CreateRequestScreen({super.key, required this.service});

  final ServiceDetail service;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requests = AppScope.of(context).requests;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestFlowTitle)),
      body: AsyncView<(RequestOptions, List<SavedAddress>)>(
        load: () async {
          final results = await (
            requests.options(),
            requests.savedAddresses(),
          ).wait;
          return results;
        },
        builder: (context, data, _) => _RequestFlow(
          service: service,
          options: data.$1,
          savedAddresses: data.$2,
        ),
      ),
    );
  }
}

class _RequestFlow extends StatefulWidget {
  const _RequestFlow({
    required this.service,
    required this.options,
    required this.savedAddresses,
  });

  final ServiceDetail service;
  final RequestOptions options;
  final List<SavedAddress> savedAddresses;

  @override
  State<_RequestFlow> createState() => _RequestFlowState();
}

class _RequestFlowState extends State<_RequestFlow> {
  late final RequestDraftController _draft;
  final _description = TextEditingController();
  final _details = TextEditingController();
  final _landmark = TextEditingController();
  final _label = TextEditingController();
  bool _showErrors = false;
  String? _pickError;
  bool _locating = false;
  LocationFailure? _locationFailure;

  @override
  void initState() {
    super.initState();
    final scope = context.getInheritedWidgetOfExactType<AppScope>()!;
    _draft = RequestDraftController(
      service: widget.service,
      requests: scope.requests,
      media: scope.media,
      options: widget.options,
      savedAddresses: widget.savedAddresses,
    );
  }

  @override
  void dispose() {
    _draft.dispose();
    _description.dispose();
    _details.dispose();
    _landmark.dispose();
    _label.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageOrigin origin) async {
    final l10n = AppLocalizations.of(context);
    final picker = AppScope.of(context).imagePicker;
    setState(() => _pickError = null);
    try {
      final file = await picker.pick(origin);
      if (file == null || !mounted) return;
      final result = _draft.addPhoto(file);
      setState(() {
        _pickError = switch (result) {
          AddPhotoResult.added => null,
          AddPhotoResult.limitReached => l10n.photoLimitReached(
            _draft.options.maxPhotos,
          ),
          AddPhotoResult.tooLarge => l10n.photoTooLarge,
          AddPhotoResult.unavailable => l10n.photoUploadsUnavailable,
        };
      });
    } on ImagePermissionDenied {
      if (mounted) setState(() => _pickError = l10n.photoPermissionDenied);
    } catch (_) {
      if (mounted) setState(() => _pickError = l10n.photoPickFailed);
    }
  }

  Future<void> _useCurrentLocation() async {
    final location = AppScope.of(context).location;
    setState(() {
      _locating = true;
      _locationFailure = null;
    });
    final result = await location.current();
    if (!mounted) return;
    setState(() {
      _locating = false;
      _locationFailure = result.failure;
    });
    if (result.point != null) _draft.update(() => _draft.point = result.point);
  }

  void _next() {
    final issue = _draft.next();
    setState(() => _showErrors = issue != null);
  }

  void _back() {
    setState(() => _showErrors = false);
    _draft.back();
  }

  void _edit(RequestStep step) {
    setState(() => _showErrors = false);
    _draft.goTo(step);
  }

  Future<void> _submit() async {
    final issue = _draft.issueFor(RequestStep.review);
    if (issue != null) {
      setState(() => _showErrors = true);
      return;
    }
    final navigator = Navigator.of(context);
    final detail = await _draft.submit();
    if (detail != null && mounted) {
      navigator.pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => RequestSuccessScreen(request: detail),
        ),
      );
    }
  }

  String _stepTitle(AppLocalizations l10n, RequestStep step) => switch (step) {
    RequestStep.describe => l10n.stepDescribeTitle,
    RequestStep.location => l10n.stepLocationTitle,
    RequestStep.schedule => l10n.stepScheduleTitle,
    RequestStep.review => l10n.stepReviewTitle,
  };

  String? _submitErrorText(AppLocalizations l10n) {
    final error = _draft.submitError;
    if (error == null) return null;
    if (error is ApiException && error.code == ApiException.network) {
      return l10n.submitFailedRetry;
    }
    return messageForError(l10n, error);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _draft,
      builder: (context, _) {
        final step = _draft.step;
        final total = RequestStep.values.length;
        final isReview = step == RequestStep.review;
        final submitError = _submitErrorText(l10n);
        return Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.stepOf(step.index + 1, total),
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ExcludeSemantics(
                    child: LinearProgressIndicator(
                      value: (step.index + 1) / total,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Semantics(
                    header: true,
                    child: Text(
                      _stepTitle(l10n, step),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: switch (step) {
                RequestStep.describe => DescribeStep(
                  draft: _draft,
                  description: _description,
                  showErrors: _showErrors,
                  onPick: _pick,
                  pickError: _pickError,
                ),
                RequestStep.location => LocationStep(
                  draft: _draft,
                  details: _details,
                  landmark: _landmark,
                  label: _label,
                  showErrors: _showErrors,
                  locating: _locating,
                  locationFailure: _locationFailure,
                  onUseCurrentLocation: _useCurrentLocation,
                ),
                RequestStep.schedule => ScheduleStep(
                  draft: _draft,
                  showErrors: _showErrors,
                ),
                RequestStep.review => ReviewStep(draft: _draft, onEdit: _edit),
              },
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Repeated next to the button: the field's own error may be scrolled away.
                    if (_showErrors)
                      if (_draft.issueFor(step) case final DraftIssue issue)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: AuthErrorText(
                            draftIssueMessage(l10n, issue, _draft.options),
                          ),
                        ),
                    if (isReview && submitError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AuthErrorText(submitError),
                      ),
                    Row(
                      children: [
                        if (step.index > 0) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _draft.submitting ? null : _back,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                              ),
                              child: Text(l10n.backButton),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                        ],
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _draft.submitting
                                ? null
                                : (isReview ? _submit : _next),
                            child: Text(
                              isReview
                                  ? (_draft.submitting
                                        ? l10n.submittingLabel
                                        : l10n.submitRequestButton)
                                  : l10n.nextButton,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
