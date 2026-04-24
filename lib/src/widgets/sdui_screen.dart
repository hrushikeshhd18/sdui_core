import 'package:flutter/material.dart';

import 'package:sdui_core/src/controller/sdui_controller.dart';
import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/renderer/sdui_renderer.dart';
import 'package:sdui_core/src/transport/sdui_transport.dart';
import 'package:sdui_core/src/widgets/sdui_scope.dart';

export 'package:sdui_core/src/controller/sdui_controller.dart'
    show SduiScreenState;

/// Renders a server-driven UI screen from a JSON payload.
///
/// **Minimum usage — 1 line:**
/// ```dart
/// SduiScreen(url: 'https://api.example.com/layouts/home')
/// ```
///
/// **Controlled by an external [SduiController] (recommended for state
/// management integration):**
/// ```dart
/// final controller = SduiController(url: 'https://api.example.com/home');
///
/// // BLoC example:
/// BlocListener<CartBloc, CartState>(
///   listener: (_, state) =>
///       controller.patchNode('cart_badge', {'count': '${state.count}'}),
///   child: SduiScreen.controlled(controller: controller),
/// )
/// ```
///
/// **With live WebSocket updates:**
/// ```dart
/// SduiScreen(
///   url: 'wss://api.example.com/layouts/home/live',
///   transport: WebSocketSduiTransport(),
/// )
/// ```
class SduiScreen extends StatefulWidget {
  /// Standard constructor — [SduiScreen] manages its own [SduiController].
  ///
  /// All parameters are identical to previous versions of the package.
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
  }) : controller = null;

  /// Controlled constructor — an external [SduiController] drives the screen.
  ///
  /// Use this when you need to integrate with Bloc, Provider, Riverpod or any
  /// other state-management framework:
  ///
  /// ```dart
  /// // Create once (e.g. in initState or a provider)
  /// final controller = SduiController(
  ///   url: 'https://api.example.com/layouts/home',
  ///   headers: {'Authorization': 'Bearer $token'},
  /// );
  ///
  /// // Drive from BLoC
  /// BlocListener<AuthBloc, AuthState>(
  ///   listener: (context, state) => state.isLoggedIn
  ///       ? controller.refresh()
  ///       : null,
  ///   child: SduiScreen.controlled(controller: controller),
  /// )
  /// ```
  SduiScreen.controlled({
    super.key,
    required this.controller,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.onEvent,
    this.pullToRefresh = false,
    this.scrollController,
    this.physics,
  })  : url = controller!.url,
        transport = null,
        headers = null,
        refreshInterval = null,
        enableCache = true,
        parseInIsolate = true,
        onLoad = null,
        onError = null,
        onRefresh = null;

  /// The URL of the JSON layout to render (for WebSocket use `wss://`).
  final String url;

  /// Optional external controller.
  ///
  /// When set, the screen is a pure view: it renders the controller's state
  /// and does not own the fetch lifecycle.
  final SduiController? controller;

  // ── Transport / fetch params (ignored when [controller] is set) ──────────

  /// Transport implementation. Defaults to `HttpSduiTransport`.
  final SduiTransport? transport;

  /// HTTP headers added to every request (e.g. auth tokens).
  final Map<String, String>? headers;

  /// Auto-refresh the layout at this interval.
  final Duration? refreshInterval;

  /// Whether to use stale-while-revalidate caching. Default `true`.
  final bool enableCache;

  /// Whether to parse JSON in a background isolate. Default `true`.
  final bool parseInIsolate;

  // ── View params (always applied) ─────────────────────────────────────────

  /// Replaces the default [CircularProgressIndicator] while loading.
  final WidgetBuilder? loadingBuilder;

  /// Replaces the default error card when an exception is thrown.
  final Widget Function(BuildContext, SduiException)? errorBuilder;

  /// Shown when the root node has no children.
  final WidgetBuilder? emptyBuilder;

  /// Fires for every action dispatched anywhere in the tree — use for
  /// analytics.
  final void Function(String event, Map<String, Object?> payload)? onEvent;

  /// Called after the first successful render.
  final VoidCallback? onLoad;

  /// Called every time a network error occurs.
  final void Function(SduiException)? onError;

  /// Called when a pull-to-refresh triggers a manual reload.
  final VoidCallback? onRefresh;

  /// Whether to wrap the content in a [RefreshIndicator].
  final bool pullToRefresh;

  /// Optional [ScrollController] for the underlying scroll view.
  final ScrollController? scrollController;

  /// Optional [ScrollPhysics] for the underlying scroll view.
  final ScrollPhysics? physics;

  @override
  State<SduiScreen> createState() => _SduiScreenState();
}

class _SduiScreenState extends State<SduiScreen> {
  // When the controller is external we do NOT own its lifecycle.
  late SduiController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _attachController();
    _controller.load();
  }

  @override
  void didUpdateWidget(SduiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final urlChanged = oldWidget.url != widget.url;
    final controllerChanged = oldWidget.controller != widget.controller;

    if (controllerChanged || (urlChanged && widget.controller == null)) {
      _detachController();
      _attachController();
      _controller.load();
    }
  }

  @override
  void dispose() {
    _detachController();
    super.dispose();
  }

  void _attachController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
    } else {
      _controller = SduiController(
        url: widget.url,
        transport: widget.transport,
        headers: widget.headers,
        enableCache: widget.enableCache,
        parseInIsolate: widget.parseInIsolate,
        refreshInterval: widget.refreshInterval,
        onLoad: widget.onLoad,
        onError: widget.onError,
        onRefresh: widget.onRefresh,
      );
      _ownsController = true;
    }
    _controller.addListener(_onControllerUpdate);
  }

  void _detachController() {
    _controller.removeListener(_onControllerUpdate);
    if (_ownsController) _controller.dispose();
  }

  void _onControllerUpdate() => mounted ? setState(() {}) : null;

  @override
  Widget build(BuildContext context) => switch (_controller.state) {
        SduiScreenState.loading => widget.loadingBuilder?.call(context) ??
            const Center(child: CircularProgressIndicator.adaptive()),
        SduiScreenState.error =>
          widget.errorBuilder?.call(context, _controller.error!) ??
              _DefaultErrorWidget(error: _controller.error!),
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
      navigatorKey: scope?.navigatorKey,
    );

    Widget content = RepaintBoundary(
      child: SduiRenderer.render(_controller.effectiveNode!, sdCtx),
    );

    if (_controller.state == SduiScreenState.errorWithCache &&
        _controller.error != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StaleErrorBanner(error: _controller.error!),
          Expanded(child: content),
        ],
      );
    }

    if (widget.pullToRefresh) {
      content = RefreshIndicator.adaptive(
        onRefresh: _controller.refresh,
        child: content,
      );
    }

    return content;
  }
}

// ── Default error widget ─────────────────────────────────────────────────────

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
