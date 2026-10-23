import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/format/dates.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/domain/egypt_phone.dart';
import '../domain/request_models.dart';
import 'request_detail_screen.dart';
import 'widgets/request_status_chip.dart';

/// The customer's submitted requests, newest first.
class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final List<RequestSummary> _items = [];
  String? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  Object? _error;
  Object? _moreError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _items.isEmpty && _error == null) _load();
  }

  Future<void> _load() async {
    final requests = AppScope.of(context).requests;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await requests.list();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _cursor = page.nextCursor;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    final requests = AppScope.of(context).requests;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final page = await requests.list(cursor: _cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
      });
    } catch (e) {
      if (mounted) setState(() => _moreError = e);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myRequestsTitle)),
      body: _loading
          ? const LoadingView()
          : _error != null
          ? ErrorView(error: _error!, onRetry: _load)
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        EmptyView(
                          message: l10n.myRequestsEmpty,
                          icon: Icons.assignment_outlined,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: _items.length + 1,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, i) {
                        if (i < _items.length) {
                          return _RequestCard(request: _items[i]);
                        }
                        if (_cursor == null) return const SizedBox.shrink();
                        return Column(
                          children: [
                            if (_moreError != null)
                              Text(messageForError(l10n, _moreError!)),
                            TextButton(
                              onPressed: _loadingMore ? null : _loadMore,
                              child: Text(l10n.loadMoreButton),
                            ),
                          ],
                        );
                      },
                    ),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});

  final RequestSummary request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RequestDetailScreen(requestId: request.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.service.name.resolve(lang),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  RequestStatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '${l10n.requestReferenceLabel}: ${isolateLtr(request.reference)}',
                style: theme.textTheme.bodyMedium,
              ),
              Text(
                '${request.area.name.resolve(lang)} · ${scheduleLabel(l10n, request.schedule, lang)}',
                style: theme.textTheme.bodySmall,
              ),
              Text(
                l10n.submittedOn(formatDateTime(request.submittedAt, lang)),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
