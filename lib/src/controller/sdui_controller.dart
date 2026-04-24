import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'package:sdui_core/src/cache/sdui_cache.dart';
import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/parser/sdui_parser.dart';
import 'package:sdui_core/src/transport/http_transport.dart';
import 'package:sdui_core/src/transport/sdui_transport.dart';
import 'package:sdui_core/src/utils/sdui_logger.dart';

/// The seven lifecycle states of an SDUI screen.
enum SduiScreenState {
  /// Initial load — no data, no cache. Shows the loading builder.
  loading,

  /// Showing stale cached data while a fresh fetch is in flight.
  loadingWithCache,

  /// Fresh data rendered successfully.
  success,

  /// Re-fetching in the background while current data is still visible.
  refreshing,

  /// Fetch failed with no cached fallback. Shows the error builder.
  error,

  /// Fetch failed but stale cache is still visible with an error banner.
  errorWithCache,

  /// Payload parsed successfully but the root node has no children.
  empty,
}

/// Drives the fetch → validate → parse → cache → patch → notify lifecycle
/// for a single SDUI screen.
///
/// [SduiController] is a [ChangeNotifier] so any state-management framework
/// can observe or react to it:
///
/// ```dart
/// // ── Standalone ───────────────────────────────────────
/// final controller = SduiController(url: 'https://api.example.com/home');
/// await controller.load();
/// SduiScreen.controlled(controller: controller)
///
/// // ── With BLoC ─────────────────────────────────────────
/// BlocListener<AuthBloc, AuthState>(
///   listener: (context, state) {
///     controller.patchNode('greeting', {'text': 'Hi ${state.name}'});
///   },
///   child: SduiScreen.controlled(controller: controller),
/// )
///
/// // ── With Provider ─────────────────────────────────────
/// Consumer<CartProvider>(
///   builder: (_, cart, __) {
///     controller.patchNode('cart_badge', {'count': '${cart.count}'});
///     return SduiScreen.controlled(controller: controller);
///   },
/// )
///
/// // ── With Riverpod ─────────────────────────────────────
/// ref.listen(cartProvider, (_, cart) {
///   controller.patchNode('cart_badge', {'count': '${cart.count}'});
/// });
/// ```
final class SduiController extends ChangeNotifier {
  /// Creates a controller for [url].
  ///
  /// Call [load] to start the fetch lifecycle, or attach the controller to a
  /// `SduiScreen.controlled` which will call it automatically.
  SduiController({
    required this.url,
    SduiTransport? transport,
    this.headers,
    this.enableCache = true,
    this.parseInIsolate = true,
    this.refreshInterval,
    this.onLoad,
    this.onError,
    this.onRefresh,
  })  : _transport = transport ?? HttpSduiTransport(),
        _ownsTransport = transport == null;

  /// The URL to fetch the JSON layout from.
  final String url;

  /// HTTP / WebSocket headers forwarded on every request.
  final Map<String, String>? headers;

  /// Whether to serve stale cache instantly while a fresh fetch runs.
  final bool enableCache;

  /// Whether to parse JSON in a background isolate.
  final bool parseInIsolate;

  /// Auto-refresh the layout at this interval. `null` disables auto-refresh.
  final Duration? refreshInterval;

  /// Called after the very first successful render.
  final VoidCallback? onLoad;

  /// Called every time a fetch fails.
  final void Function(SduiException)? onError;

  /// Called each time a manual [refresh] is triggered.
  final VoidCallback? onRefresh;

  // ── Internal state ───────────────────────────────────────────────────────

  final SduiTransport _transport;
  final bool _ownsTransport;

  SduiScreenState _state = SduiScreenState.loading;
  SduiNode? _node;
  SduiException? _error;
  bool _loadStarted = false;
  bool _firstLoadDone = false;
  bool _disposed = false;
  Timer? _refreshTimer;
  final Map<String, Map<String, Object?>> _patches = {};

  // ── Public state ─────────────────────────────────────────────────────────

  /// Current lifecycle state of the screen.
  SduiScreenState get state => _state;

  /// The last successfully parsed node tree.
  ///
  /// `null` before the first successful load.
  SduiNode? get node => _node;

  /// The last exception, or `null` when not in an error state.
  SduiException? get error => _error;

  /// Node tree with all [patchNode] overrides applied.
  ///
  /// This is what `SduiScreen` renders — identical to [node] when no patches
  /// are active.
  SduiNode? get effectiveNode {
    if (_node == null) return null;
    if (_patches.isEmpty) return _node;
    return _applyPatches(_node!);
  }

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Starts the cache-first fetch lifecycle.
  ///
  /// Idempotent — subsequent calls before the first response arrives are
  /// ignored. Call [refresh] to force a re-fetch.
  Future<void> load() async {
    if (_loadStarted || _disposed) return;
    _loadStarted = true;
    await _loadFromCacheThenFetch();
    _scheduleRefresh();
  }

  /// Forces an unconditional re-fetch regardless of cache or current state.
  ///
  /// Transitions to [SduiScreenState.refreshing] while in flight.
  Future<void> refresh() async {
    if (_disposed) return;
    onRefresh?.call();
    await _fetch();
  }

  // ── Optimistic updates ───────────────────────────────────────────────────

  /// Merges [propsOverrides] into the props of the node identified by [nodeId].
  ///
  /// Triggers a synchronous rebuild via [notifyListeners] — no network request.
  /// Multiple patches on the same node accumulate:
  ///
  /// ```dart
  /// // Immediately reflect new cart count before the API responds
  /// controller.patchNode('cart_badge', {'count': '${cart.length}'});
  /// ```
  void patchNode(String nodeId, Map<String, Object?> propsOverrides) {
    if (_disposed) return;
    _patches[nodeId] = {...(_patches[nodeId] ?? {}), ...propsOverrides};
    notifyListeners();
  }

  /// Removes all patches for [nodeId], restoring server-provided props.
  void clearPatch(String nodeId) {
    if (_disposed || !_patches.containsKey(nodeId)) return;
    _patches.remove(nodeId);
    notifyListeners();
  }

  /// Removes every active patch, restoring the full server-provided tree.
  void clearAllPatches() {
    if (_disposed || _patches.isEmpty) return;
    _patches.clear();
    notifyListeners();
  }

  // ── Disposal ─────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    if (_ownsTransport) _transport.dispose();
    super.dispose();
  }

  // ── Private ───────────────────────────────────────────────────────────────

  void _scheduleRefresh() {
    if (refreshInterval == null) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(refreshInterval!, (_) => _fetch());
  }

  Future<void> _loadFromCacheThenFetch() async {
    if (enableCache && SduiCache.isInitialized) {
      try {
        final cached = await SduiCache.instance.get(url);
        if (cached != null && !_disposed) {
          final node = SduiParser.parse(cached);
          _setState(state: SduiScreenState.loadingWithCache, node: node);
        }
      } on Exception catch (_) {
        // Cache failure is non-fatal — fall through to network.
      }
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_disposed) return;

    final isResuming = _state == SduiScreenState.success ||
        _state == SduiScreenState.loadingWithCache ||
        _state == SduiScreenState.errorWithCache;
    if (isResuming) {
      _setState(state: SduiScreenState.refreshing);
    }

    try {
      final map = await _transport.fetch(url, headers: headers);

      if (enableCache) {
        _writeCache(map); // intentionally unawaited
      }

      final node = await _parseNode(map);

      if (!_disposed) {
        final isEmpty = node is SduiParentNode && node.children.isEmpty;
        _setState(
          state: isEmpty ? SduiScreenState.empty : SduiScreenState.success,
          node: node,
          clearError: true,
        );
        if (!_firstLoadDone) {
          _firstLoadDone = true;
          onLoad?.call();
        }
      }
    } on SduiException catch (e, st) {
      SduiLogger.error(
        'SduiController fetch failed for $url',
        error: e,
        stackTrace: st,
      );
      onError?.call(e);
      if (!_disposed) {
        _setState(
          state: _node != null
              ? SduiScreenState.errorWithCache
              : SduiScreenState.error,
          error: e,
        );
      }
    } on Exception catch (e, st) {
      final ex = SduiNetworkException(url: url, message: e.toString());
      SduiLogger.error(
        'SduiController unexpected error',
        error: e,
        stackTrace: st,
      );
      onError?.call(ex);
      if (!_disposed) {
        _setState(
          state: _node != null
              ? SduiScreenState.errorWithCache
              : SduiScreenState.error,
          error: ex,
        );
      }
    }
  }

  Future<SduiNode> _parseNode(Map<String, Object?> map) async {
    if (parseInIsolate) return SduiParser.parseString(jsonEncode(map));
    return SduiParser.parse(map);
  }

  void _setState({
    required SduiScreenState state,
    SduiNode? node,
    SduiException? error,
    bool clearError = false,
  }) {
    var changed = false;
    if (_state != state) {
      _state = state;
      changed = true;
    }
    if (node != null && _node != node) {
      _node = node;
      changed = true;
    }
    if (clearError && _error != null) {
      _error = null;
      changed = true;
    } else if (error != null && _error != error) {
      _error = error;
      changed = true;
    }
    if (changed && !_disposed) notifyListeners();
  }

  SduiNode _applyPatches(SduiNode node) {
    final patch = _patches[node.id];
    final patched =
        patch != null ? node.copyWith(props: {...node.props, ...patch}) : node;
    if (patched is SduiParentNode && patched.children.isNotEmpty) {
      return patched.copyWith(
        children: patched.children.map(_applyPatches).toList(growable: false),
      );
    }
    return patched;
  }

  Future<void> _writeCache(Map<String, Object?> map) async {
    if (!SduiCache.isInitialized) return;
    try {
      await SduiCache.instance.set(url, map);
    } on Exception catch (_) {
      // Ignore cache write failures.
    }
  }
}
