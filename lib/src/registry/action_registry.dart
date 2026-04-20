import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sdui_core/sdui_core.dart' show SduiScope, SduiScreen;
import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/models/sdui_action.dart';
import 'package:sdui_core/src/utils/sdui_logger.dart';
import 'package:url_launcher/url_launcher.dart';

/// Context passed to every [SduiActionHandler] and [SduiActionMiddleware].
@immutable
final class SduiActionContext {
  /// Creates a [SduiActionContext].
  const SduiActionContext({
    required this.flutterContext,
    required this.nodeProps,
    required this.nodePath,
  });

  /// The ambient Flutter [BuildContext] at the time the action fired.
  final BuildContext flutterContext;

  /// The `props` map of the node that triggered the action.
  final Map<String, Object?> nodeProps;

  /// Dot-separated path of the triggering node.
  final String nodePath;
}

/// Return value from an [SduiActionHandler].
@immutable
final class SduiActionResult {
  const SduiActionResult._({
    required this.isSuccess,
    this.data,
    this.message,
    this.error,
  });

  /// Creates a successful result, optionally carrying [data].
  const SduiActionResult.success({Object? data})
      : this._(isSuccess: true, data: data);

  /// Creates a failure result with a required [message].
  const SduiActionResult.failure({required String message, Object? error})
      : this._(isSuccess: false, message: message, error: error);

  /// Whether the action completed without error.
  final bool isSuccess;

  /// Optional data returned by the handler.
  final Object? data;

  /// Failure description (only set when [isSuccess] is `false`).
  final String? message;

  /// The underlying error object (only set on failure).
  final Object? error;
}

/// An async function that handles a dispatched [SduiAction].
typedef SduiActionHandler = Future<SduiActionResult> Function(
  SduiAction action,
  SduiActionContext ctx,
);

/// Middleware that intercepts every action before it reaches the handler.
///
/// Call [next] to proceed to the next middleware or the final handler.
/// Return a result directly to short-circuit.
typedef SduiActionMiddleware = Future<SduiActionResult> Function(
  SduiAction action,
  SduiActionContext ctx,
  Future<SduiActionResult> Function() next,
);

/// Registry that maps event names to [SduiActionHandler] functions.
///
/// Each instance is fully isolated — create per-test instances:
/// ```dart
/// final reg = SduiActionRegistry()
///   ..register('add_to_cart', myHandler);
/// ```
///
/// The five built-in action types ([SduiActionType]) are handled automatically
/// without registration. Custom events are layered on top.
final class SduiActionRegistry {
  /// Creates an empty registry.
  SduiActionRegistry({this.onUnhandled});

  /// Called when a dispatched event has no registered handler.
  ///
  /// Useful for logging unknown events in production.
  final void Function(String eventName)? onUnhandled;

  /// The shared default registry used by [SduiScope].
  static final SduiActionRegistry defaults = SduiActionRegistry();

  final Map<String, SduiActionHandler> _handlers = {};
  final List<SduiActionMiddleware> _middlewares = [];

  // Debounce: track last-fired timestamp per event.
  final Map<String, DateTime> _lastFired = {};

  /// Registers [handler] for [eventName].
  ///
  /// Overwrites any previously registered handler for the same name.
  void register(String eventName, SduiActionHandler handler) {
    _handlers[eventName] = handler;
  }

  /// Appends [middleware] to the execution chain.
  ///
  /// Middlewares run in registration order before the final handler.
  void addMiddleware(SduiActionMiddleware middleware) {
    _middlewares.add(middleware);
  }

  /// Returns `true` if a handler is registered for [eventName].
  bool hasHandler(String eventName) => _handlers.containsKey(eventName);

  /// Removes the handler for [eventName].
  void unregister(String eventName) => _handlers.remove(eventName);

  /// Removes all handlers, middlewares, and debounce state.
  void clear() {
    _handlers.clear();
    _middlewares.clear();
    _lastFired.clear();
  }

  /// Returns a new registry that fires [onEvent] before every dispatch,
  /// then delegates to this registry. Used by [SduiScreen] for analytics.
  SduiActionRegistry withEventInterceptor(
    void Function(String, Map<String, Object?>)? onEvent,
  ) =>
      onEvent == null
          ? this
          : _InterceptedRegistry(delegate: this, onEvent: onEvent);

  /// Dispatches [action] through the middleware chain and then to the handler.
  ///
  /// Built-in [SduiActionType] values are handled automatically.
  /// Unhandled custom events call [onUnhandled] (if set) and throw
  /// [SduiActionException].
  Future<SduiActionResult> dispatch(
    String eventName,
    SduiAction action,
    SduiActionContext ctx,
  ) async {
    // Debounce check.
    if (action.debounceMs != null) {
      final last = _lastFired[eventName];
      if (last != null) {
        final elapsed = DateTime.now().difference(last).inMilliseconds;
        if (elapsed < action.debounceMs!) {
          SduiLogger.action(
            'Debounced "$eventName" (${elapsed}ms < ${action.debounceMs}ms)',
          );
          return const SduiActionResult.success();
        }
      }
      _lastFired[eventName] = DateTime.now();
    }

    SduiLogger.action('Dispatch "$eventName" via ${action.type}');

    // Build the middleware-wrapped execution.
    Future<SduiActionResult> execute() => _executeBuiltIn(action, ctx);

    final chain =
        _middlewares.reversed.fold<Future<SduiActionResult> Function()>(
      execute,
      (next, mw) => () => mw(action, ctx, next),
    );

    return chain();
  }

  Future<SduiActionResult> _executeBuiltIn(
    SduiAction action,
    SduiActionContext ctx,
  ) async {
    switch (action.type) {
      case SduiActionType.navigate:
        final route = action.payload['route'] as String? ?? action.event;
        Navigator.of(ctx.flutterContext).pushNamed(route);
        return const SduiActionResult.success();

      case SduiActionType.openUrl:
        final raw = action.payload['url'] as String? ?? action.event;
        final uri = Uri.tryParse(raw);
        if (uri != null) {
          await launchUrl(uri);
          return const SduiActionResult.success();
        }
        return SduiActionResult.failure(
          message: 'Invalid URL: "$raw"',
        );

      case SduiActionType.copyToClipboard:
        final text = action.payload['text'] as String? ??
            ctx.nodeProps['text'] as String? ??
            '';
        await Clipboard.setData(ClipboardData(text: text));
        return const SduiActionResult.success();

      case SduiActionType.showSnackbar:
        final msg = action.payload['message'] as String? ?? '';
        if (ctx.flutterContext.mounted) {
          ScaffoldMessenger.of(ctx.flutterContext).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
        return const SduiActionResult.success();

      case SduiActionType.showBottomSheet:
      case SduiActionType.dismissBottomSheet:
      case SduiActionType.showDialog:
      case SduiActionType.refresh:
        // These are handled by SduiScreen via the onEvent callback.
        // Fall through to custom dispatch so host app can intercept.
        break;

      default:
        break;
    }

    // Custom dispatch.
    final handler = _handlers[action.event];
    if (handler == null) {
      onUnhandled?.call(action.event);
      throw SduiActionException(
        actionName: action.event,
        message: 'No handler registered for event "${action.event}".',
      );
    }
    return handler(action, ctx);
  }
}

// ---------------------------------------------------------------------------
// Private interceptor — lives in the same library to extend the final class.
// ---------------------------------------------------------------------------

final class _InterceptedRegistry extends SduiActionRegistry {
  _InterceptedRegistry({
    required SduiActionRegistry delegate,
    required this.onEvent,
  }) : _delegate = delegate;

  final SduiActionRegistry _delegate;
  final void Function(String, Map<String, Object?>) onEvent;

  @override
  Future<SduiActionResult> dispatch(
    String eventName,
    SduiAction action,
    SduiActionContext ctx,
  ) async {
    onEvent(eventName, action.payload);
    return _delegate.dispatch(eventName, action, ctx);
  }
}
