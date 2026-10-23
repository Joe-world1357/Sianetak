import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_scope.dart';
import '../../../core/device/image_picker_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/private_image.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_error_text.dart';
import '../../catalog/domain/catalog_models.dart';
import '../../media/data/media_repository.dart';
import '../../media/domain/media_models.dart';
import '../../requests/domain/request_models.dart';
import '../domain/technician_models.dart';
import 'verification_status_view.dart';

/// Technician onboarding (FR-AUTH-06): shows the current verification status, or the
/// application form when there is no application yet or a rejected one is being corrected.
class TechnicianApplicationScreen extends StatefulWidget {
  const TechnicianApplicationScreen({super.key});

  @override
  State<TechnicianApplicationScreen> createState() =>
      _TechnicianApplicationScreenState();
}

class _LoadedData {
  const _LoadedData(this.state, this.categories, this.areas);

  final OwnApplicationState state;
  final List<ServiceCategory> categories;
  final List<ServiceArea> areas;
}

class _TechnicianApplicationScreenState
    extends State<TechnicianApplicationScreen> {
  _LoadedData? _data;
  Object? _error;
  bool _editing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_data == null && _error == null) _load();
  }

  Future<void> _load() async {
    final scope = AppScope.of(context);
    setState(() => _error = null);
    try {
      final (state, categories, areas) = await (
        scope.technician.getOwn(),
        scope.catalog.listCategories(),
        scope.technician.serviceAreas(),
      ).wait;
      if (mounted) {
        setState(() => _data = _LoadedData(state, categories, areas));
      }
    } on ParallelWaitError<dynamic, dynamic> catch (e) {
      final errors = e.errors as (Object?, Object?, Object?);
      if (mounted) setState(() => _error = errors.$1 ?? errors.$2 ?? errors.$3);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _onSubmitted(TechnicianApplication application) {
    final data = _data!;
    setState(() {
      _editing = false;
      _data = _LoadedData(
        OwnApplicationState(
          application: application,
          requirements: data.state.requirements,
        ),
        data.categories,
        data.areas,
      );
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).applicationSubmittedMessage,
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = _data;
    final application = data?.state.application;
    final showForm = data != null && (application == null || _editing);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          showForm ? l10n.technicianApplyTitle : l10n.applicationStatusTitle,
        ),
      ),
      body: _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : data == null
          ? const LoadingView()
          : showForm
          ? _ApplicationForm(
              categories: data.categories,
              areas: data.areas,
              requirements: data.state.requirements,
              previous: application,
              onSubmitted: _onSubmitted,
            )
          : VerificationStatusView(
              application: application!,
              onResubmit: () => setState(() => _editing = true),
              onRefresh: _load,
            ),
    );
  }
}

class _DocumentDraft {
  _DocumentDraft.picked(this.localId, PickedImage this.file, this.kind)
    : existing = null,
      status = _UploadStatus.uploading;

  _DocumentDraft.existing(this.localId, ApplicationDocument this.existing)
    : file = null,
      kind = existing.kind,
      mediaId = existing.id,
      status = _UploadStatus.uploaded;

  final int localId;
  final PickedImage? file;
  final ApplicationDocument? existing;
  DocumentKind kind;
  String? mediaId;
  _UploadStatus status;
}

enum _UploadStatus { uploading, uploaded, failed }

class _ApplicationForm extends StatefulWidget {
  const _ApplicationForm({
    required this.categories,
    required this.areas,
    required this.requirements,
    required this.previous,
    required this.onSubmitted,
  });

  final List<ServiceCategory> categories;
  final List<ServiceArea> areas;
  final ApplicationRequirements requirements;
  final TechnicianApplication? previous;
  final void Function(TechnicianApplication) onSubmitted;

  @override
  State<_ApplicationForm> createState() => _ApplicationFormState();
}

class _ApplicationFormState extends State<_ApplicationForm> {
  static final _namePattern = RegExp(
    r"^[\p{L}\p{M}][\p{L}\p{M}' .-]*$",
    unicode: true,
  );

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _years;
  late final TextEditingController _bio;
  late final Set<String> _specialties;
  late final Set<String> _areas;
  final List<_DocumentDraft> _documents = [];
  int _nextId = 0;
  bool _showChoiceErrors = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.previous;
    _name = TextEditingController(text: p?.fullName ?? '');
    _years = TextEditingController(
      text: p?.yearsOfExperience?.toString() ?? '',
    );
    _bio = TextEditingController(text: p?.bio ?? '');
    _specialties = {...?p?.specialties.map((s) => s.id)};
    _areas = {...?p?.serviceAreas.map((a) => a.id)};
    for (final d in p?.documents ?? const <ApplicationDocument>[]) {
      _documents.add(_DocumentDraft.existing(_nextId++, d));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _years.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageOrigin origin) async {
    final l10n = AppLocalizations.of(context);
    final scope = AppScope.of(context);
    setState(() => _error = null);
    try {
      final file = await scope.imagePicker.pick(origin);
      if (file == null || !mounted) return;
      final draft = _DocumentDraft.picked(
        _nextId++,
        file,
        DocumentKind.identity,
      );
      setState(() => _documents.add(draft));
      await _upload(draft);
    } on ImagePermissionDenied {
      if (mounted) setState(() => _error = l10n.photoPermissionDenied);
    } catch (_) {
      if (mounted) setState(() => _error = l10n.photoPickFailed);
    }
  }

  Future<void> _upload(_DocumentDraft draft) async {
    final media = AppScope.of(context).media;
    setState(() => draft.status = _UploadStatus.uploading);
    try {
      final uploaded = await media.upload(
        MediaPurpose.technicianDocument,
        draft.file!,
      );
      if (!mounted) return;
      setState(() {
        draft
          ..mediaId = uploaded.id
          ..status = _UploadStatus.uploaded;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        draft.status = _UploadStatus.failed;
        _error = messageForError(AppLocalizations.of(context), e);
      });
    }
  }

  void _remove(_DocumentDraft draft) {
    final media = AppScope.of(context).media;
    setState(() => _documents.remove(draft));
    final id = draft.mediaId;
    // Only never-submitted uploads can be deleted; kept documents just leave the list.
    if (id != null && draft.existing == null) {
      media.remove(id).catchError((_) {});
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final technician = AppScope.of(context).technician;
    setState(() {
      _showChoiceErrors = true;
      _error = null;
    });
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk || _specialties.isEmpty || _areas.isEmpty) return;
    if (_documents.any((d) => d.status != _UploadStatus.uploaded)) {
      setState(() => _error = l10n.photosFailedFix);
      return;
    }
    if (_documents.length < widget.requirements.minDocuments) {
      setState(
        () => _error = l10n.documentsMinHelp(widget.requirements.minDocuments),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final years = _years.text.trim();
      final application = await technician.submit(
        ApplicationSubmission(
          fullName: _name.text.trim(),
          yearsOfExperience: years.isEmpty ? null : int.parse(years),
          bio: _bio.text.trim(),
          specialtyCategoryIds: [
            for (final c in widget.categories)
              if (_specialties.contains(c.id)) c.id,
          ],
          serviceAreaIds: [
            for (final a in widget.areas)
              if (_areas.contains(a.id)) a.id,
          ],
          documents: [for (final d in _documents) (d.mediaId!, d.kind)],
        ),
      );
      if (mounted) widget.onSubmitted(application);
    } catch (e) {
      if (mounted) setState(() => _error = messageForError(l10n, e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final req = widget.requirements;
    final title = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
    );
    final errorStyle = TextStyle(color: theme.colorScheme.error);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.technicianApplyIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppSpacing.md),
          TextFormField(
            controller: _name,
            maxLength: 80,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l10n.fullNameLabel),
            validator: (v) {
              final value = v?.trim() ?? '';
              return value.length < 2 || !_namePattern.hasMatch(value)
                  ? l10n.fullNameInvalid
                  : null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _years,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(labelText: l10n.yearsLabel),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return null;
              final n = int.tryParse(value);
              return n == null || n > 60 ? l10n.yearsInvalid : null;
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _bio,
            minLines: 2,
            maxLines: 5,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: l10n.bioLabel,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(l10n.specialtiesTitle, style: title),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final c in widget.categories)
                FilterChip(
                  label: Text(c.name.resolve(lang)),
                  selected: _specialties.contains(c.id),
                  onSelected: (on) => setState(
                    () =>
                        on ? _specialties.add(c.id) : _specialties.remove(c.id),
                  ),
                ),
            ],
          ),
          if (_showChoiceErrors && _specialties.isEmpty)
            Text(l10n.specialtiesRequired, style: errorStyle),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(l10n.serviceAreasTitle, style: title),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final a in widget.areas)
                FilterChip(
                  label: Text(a.name.resolve(lang)),
                  selected: _areas.contains(a.id),
                  onSelected: (on) => setState(
                    () => on ? _areas.add(a.id) : _areas.remove(a.id),
                  ),
                ),
            ],
          ),
          if (_showChoiceErrors && _areas.isEmpty)
            Text(l10n.serviceAreasRequired, style: errorStyle),
          const SizedBox(height: AppSpacing.md),
          Semantics(
            header: true,
            child: Text(l10n.documentsTitle, style: title),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            req.minDocuments == 0
                ? l10n.documentsOptionalHelp
                : l10n.documentsMinHelp(req.minDocuments),
            style: theme.textTheme.bodySmall,
          ),
          Text(l10n.documentsPrivacy, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          for (final (i, d) in _documents.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.control),
                        child: SizedBox.square(
                          dimension: 64,
                          child: d.file != null
                              ? Image.memory(d.file!.bytes, fit: BoxFit.cover)
                              : d.existing!.isImage
                              ? PrivateImage(
                                  mediaId: d.existing!.id,
                                  semanticLabel: l10n.documentNumber(i + 1),
                                )
                              : const Icon(Icons.picture_as_pdf_outlined),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.documentNumber(i + 1)),
                            DropdownButton<DocumentKind>(
                              value: d.kind,
                              isExpanded: true,
                              items: [
                                for (final k in DocumentKind.values)
                                  DropdownMenuItem(
                                    value: k,
                                    child: Text(documentKindLabel(l10n, k)),
                                  ),
                              ],
                              onChanged: (k) =>
                                  setState(() => d.kind = k ?? d.kind),
                            ),
                            if (d.status == _UploadStatus.uploading)
                              Text(
                                l10n.photoUploading,
                                style: theme.textTheme.bodySmall,
                              ),
                            if (d.status == _UploadStatus.failed)
                              Text(l10n.photoFailed, style: errorStyle),
                          ],
                        ),
                      ),
                      if (d.status == _UploadStatus.failed)
                        IconButton(
                          tooltip: l10n.photoRetry,
                          onPressed: () => _upload(d),
                          icon: const Icon(Icons.refresh),
                        ),
                      IconButton(
                        tooltip: l10n.documentRemove,
                        onPressed: () => _remove(d),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!req.uploadsAvailable)
            Text(l10n.errorMediaUnavailable, style: theme.textTheme.bodySmall)
          else if (_documents.length < req.maxDocuments)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pick(ImageOrigin.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: Text(l10n.addPhotoCamera),
                ),
                OutlinedButton.icon(
                  onPressed: () => _pick(ImageOrigin.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(l10n.addPhotoGallery),
                ),
              ],
            )
          else
            Text(l10n.documentLimitReached, style: theme.textTheme.bodySmall),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            AuthErrorText(_error!),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Text(
              _submitting
                  ? l10n.submittingLabel
                  : widget.previous == null
                  ? l10n.submitApplicationButton
                  : l10n.resubmitApplicationButton,
            ),
          ),
        ],
      ),
    );
  }
}
