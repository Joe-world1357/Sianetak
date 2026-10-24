import 'package:flutter/material.dart';

import '../../../core/app_scope.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../domain/request_models.dart';
import 'widgets/request_card.dart';

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

  Listenable? _changes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loading && _items.isEmpty && _error == null) _load();
    final changes = AppScope.of(context).changes;
    if (changes != _changes) {
      _changes?.removeListener(_refresh);
      _changes = changes..addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _changes?.removeListener(_refresh);
    super.dispose();
  }

  /// Picks up changes made elsewhere (a technician accepting, a status update).
  Future<void> _refresh() async {
    try {
      final page = await AppScope.of(context).requests.list();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _cursor = page.nextCursor;
      });
    } catch (_) {
      // Keep what is on screen; pull-to-refresh shows errors.
    }
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
                          return RequestCard(request: _items[i]);
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
