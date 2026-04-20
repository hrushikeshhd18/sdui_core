import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:sdui_core/src/cache/sdui_cache.dart';
import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/parser/sdui_parser.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/renderer/sdui_renderer.dart';
import 'package:sdui_core/src/transport/http_transport.dart';
import 'package:sdui_core/src/transport/sdui_transport.dart';
import 'package:sdui_core/src/utils/sdui_logger.dart';
import 'package:sdui_core/src/widgets/sdui_scope.dart';

/// The 7 lifecycle states of [SduiScreen].
enum SduiScreenState {
  /// Initial load — no data, no cache. Shows [SduiScreen.loadingBuilder].
  loading,

  /// Initial load — showing stale cache while fresh data arrives.
  loadingWithCache,

  /// Successfully rendered. Shows the SDUI tree.
  success,

  /// Re-fetching in the background while still showing current data.
  refreshing,

  /// Fetch failed — no cache available. Shows [SduiScreen.errorBuilder].
  error,

  /// Fetch failed — showing stale cache with an error banner.
  errorWithCache,

  /// Payload loaded but the root node has no children.
  empty,
}

/// Renders a server-driven UI screen from a JSON payload.
///
/// **Minimum usage — 1 line:**
/// ```dart
/// SduiScreen(url: 'https://api.example.com/layouts/home')
/// ```
///
/// **With live WebSocket updates:**
/// ```dart
/// SduiScreen(
///   url: 'wss://api.example.com/layouts/home/live',
///   transport: WebSocketSduiTransport(),
/// )
/// ```
///
/// **With auth headers and cache disabled:**
/// ```dart
/// SduiScreen(
///   url: 'https://api.example.com/layouts/cart',
///   headers: {'Authorization': 'Bearer $token'},
///   enableCache: false,
/// )
/// ```
class SduiScreen extends StatefulWidget {
  /// Creates an [SduiScreen].
  const SduiScreen({
    super.key,
    required this.url,
    this.transport,
    this.headers,
    this.refreshInterval,
    this.enableCache = true,
    this.parseInIsolate = true,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onEvent,
    this.onLoad,
    this.onError,
    this.onRefresh,
    this.pullToRefresh = false,
    this.scrollController,
    this.physics,
  });

  /// The URL of the JSON layout to render. For WebSocket, use `wss://`.
  final String url;

  /// Transport implementation. Defaults to [HttpSduiTransport].
  final SduiTransport? transport;

  /// HTTP headers added to every request (e.g. auth tokens).
  final Map<String, String>? headers;

  /// Auto-refresh the layout at this interval.
  final Duration? refreshInterval;

  /// Whether to use stale-while-revalidate caching. Default `true`.
  final bool enableCache;

  /// Whether to parse JSON in a background isolate. Default `true`.
  final bool parseInIsolate;

  /// Replaces the default [CircularProgressIndicator] while loading.
  final WidgetBuilder? loadingBuilder;

  /// Replaces the default error card when an exception is thrown.
  final Widget Function(BuildContext, SduiException)? errorBuilder;

  /// Shown when the root node has no children.
  final WidgetBuilder? emptyBuilder;

  /// Called whenever any SDUI action fires, regardless of handler registration.
  ///
  /// Useful for analytics.
  final void Function(String event, Map<String, Object?> payload)? onEvent;

  /// Called after the first successful render.
  final VoidCallback? onLoad;

  /// Called every time a network error occurs.
  final void Function(SduiException)? onError;

  /// Called when pull-to-refresh triggers a manual reload.
  final VoidCallback? onRefresh;

  /// Whether to wrap the content in a [RefreshIndicator].
  final bool pullToRefresh;

  /// Optional [ScrollController] passed to the underlying scroll view.
  final ScrollController? scrollController;

  /// Optional [ScrollPhysics] for the underlying scroll view.
  final ScrollPhysics? physics;

  @override
  State<SduiScreen> createState() => _SduiScreenState();
}

class _SduiScreenState extends State<SduiScreen> {
  SduiNode? _node;
  SduiException? _error;
  SduiScreenState _state = SduiScreenState.loading;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, Object?>>? _subscription;
  late SduiTransport _transport;
  bool _firstLoadDone = false;

  @override
  void initState() {
    super.initState();
    _transport = widget.transport ?? HttpSduiTransport();
    _start();
    _scheduleRefresh();
  }

  @override
  void didUpdateWidget(SduiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _cancel();
      _transport = widget.transport ?? HttpSduiTransport();
      _firstLoadDone = false;
      _start();
    }
    if (oldWidget.refreshInterval != widget.refreshInterval) {
      _refreshTimer?.cancel();
      _scheduleRefresh();
    }
  }

  @override
  void dispose() {
    _cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _cancel() {
    _subscription?.cancel();
    _subscription = null;
    _transport.dispose();
  }

  void _scheduleRefresh() {
    if (widget.refreshInterval == null) return;
    _refreshTimer = Timer.periodic(widget.refreshInterval!, (_) => _fetch());
  }

  void _start() {
    // Try cache first.
    _loadFromCacheThenFetch();
  }

  Future<void> _loadFromCacheThenFetch() async {
    if (widget.enableCache) {
      try {
        final cached = await SduiCache.instance.get(widget.url);
        if (cached != null && mounted) {
          final node = _parseMap(cached);
          setState(() {
            _node = node;
            _state = SduiScreenState.loadingWithCache;
          });
        }
      } on Exception {
        // Cache failure is non-fatal — fall through to network.
      }
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    if (!mounted) return;

    if (_state == SduiScreenState.success ||
        _state == SduiScreenState.loadingWithCache ||
        _state == SduiScreenState.errorWithCache) {
      if (mounted) setState(() => _state = SduiScreenState.refreshing);
    }

    try {
      final map = await _transport.fetch(
        widget.url,
        headers: widget.headers,
      );

      if (widget.enableCache) {
        unawaited(SduiCache.instance.set(widget.url, map));
      }

      final node = await _parseNode(map);

      if (mounted) {
        setState(() {
          _node = node;
          _error = null;
          _state =
              _isEmpty(node) ? SduiScreenState.empty : SduiScreenState.success;
        });

        if (!_firstLoadDone) {
          _firstLoadDone = true;
          widget.onLoad?.call();
        }
      }
    } on SduiException catch (e, st) {
      SduiLogger.error(
        'SduiScreen fetch failed for ${widget.url}',
        error: e,
        stackTrace: st,
      );
      widget.onError?.call(e);
      if (mounted) {
        setState(() {
          _error = e;
          _state = _node != null
              ? SduiScreenState.errorWithCache
              : SduiScreenState.error;
        });
      }
    } on Exception catch (e, st) {
      final ex = SduiNetworkException(url: widget.url, message: e.toString());
      SduiLogger.error('SduiScreen unexpected error', error: e, stackTrace: st);
      widget.onError?.call(ex);
      if (mounted) {
        setState(() {
          _error = ex;
          _state = _node != null
              ? SduiScreenState.errorWithCache
              : SduiScreenState.error;
        });
      }
    }
  }

  SduiNode _parseMap(Map<String, Object?> map) => SduiParser.parse(map);

  Future<SduiNode> _parseNode(Map<String, Object?> map) async {
    if (widget.parseInIsolate) {
      return SduiParser.parseString(jsonEncode(map));
    }
    return SduiParser.parse(map);
  }

  bool _isEmpty(SduiNode node) =>
      node is SduiParentNode && node.children.isEmpty;

  Future<void> _handleRefresh() async {
    widget.onRefresh?.call();
    await _fetch();
  }

  @override
  Widget build(BuildContext context) => switch (_state) {
        SduiScreenState.loading => widget.loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator.adaptive()),
        SduiScreenState.error => widget.errorBuilder?.call(context, _error!) ??
            _DefaultErrorWidget(error: _error!),
        SduiScreenState.empty =>
          widget.emptyBuilder?.call(context) ?? const SizedBox.shrink(),
        _ => _buildContent(context),
      };

  Widget _buildContent(BuildContext context) {
    final scope = SduiScope.maybeOf(context);
    final registry = scope?.registry ?? SduiWidgetRegistry.defaults;
    final actionRegistry = scope?.actionRegistry ?? SduiActionRegistry.defaults;

    final wrappedRegistry = actionRegistry.withEventInterceptor(widget.onEvent);

    final sdCtx = SduiBuildContext(
      flutterContext: context,
      registry: registry,
      actionRegistry: wrappedRegistry,
      nodePath: 'root',
    );

    Widget content = RepaintBoundary(
      child: SduiRenderer.render(_node!, sdCtx),
    );

    if (_state == SduiScreenState.errorWithCache && _error != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StaleErrorBanner(error: _error!),
          Expanded(child: content),
        ],
      );
    }

    if (widget.pullToRefresh) {
      content = RefreshIndicator.adaptive(
        onRefresh: _handleRefresh,
        child: content,
      );
    }

    return content;
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.error});
  final SduiException error;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                error.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '[${error.code}]',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
}

class _StaleErrorBanner extends StatelessWidget {
  const _StaleErrorBanner({required this.error});
  final SduiException error;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.orange.shade100,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Showing cached content — refresh failed.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
}

// Avoids lint for unawaited futures we deliberately don't need to await.
void unawaited(Future<void> future) {}
