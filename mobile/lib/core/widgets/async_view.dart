import 'package:flutter/material.dart';

import 'state_views.dart';

/// Loads [load] once and renders loading, error (with retry) or data states.
/// With [refreshOn], reloads quietly (keeping the current data on screen) whenever it fires.
class AsyncView<T> extends StatefulWidget {
  const AsyncView({
    super.key,
    required this.load,
    required this.builder,
    this.refreshOn,
  });

  final Future<T> Function() load;
  final Widget Function(
    BuildContext context,
    T data,
    Future<void> Function() reload,
  )
  builder;
  final Listenable? refreshOn;

  @override
  State<AsyncView<T>> createState() => _AsyncViewState<T>();
}

class _AsyncViewState<T> extends State<AsyncView<T>> {
  late Future<T> _future = widget.load();

  @override
  void initState() {
    super.initState();
    widget.refreshOn?.addListener(_quietReload);
  }

  @override
  void didUpdateWidget(AsyncView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshOn != widget.refreshOn) {
      oldWidget.refreshOn?.removeListener(_quietReload);
      widget.refreshOn?.addListener(_quietReload);
    }
  }

  @override
  void dispose() {
    widget.refreshOn?.removeListener(_quietReload);
    super.dispose();
  }

  void _quietReload() {
    widget.load().then((value) {
      if (!mounted) return;
      setState(() {
        _future = Future.value(value);
      });
    }, onError: (_) {});
  }

  Future<void> _reload() async {
    final future = widget.load();
    setState(() {
      _future = future;
    });
    try {
      await future;
    } catch (_) {
      // Rendered by the error state.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        final waiting = snapshot.connectionState != ConnectionState.done;
        if (waiting && !snapshot.hasData) return const LoadingView();
        if (!waiting && snapshot.hasError) {
          return ErrorView(error: snapshot.error!, onRetry: _reload);
        }
        return widget.builder(context, snapshot.data as T, _reload);
      },
    );
  }
}
