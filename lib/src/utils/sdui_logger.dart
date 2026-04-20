import 'package:flutter/foundation.dart';

/// Structured debug logger for `sdui_core`.
///
/// All output is suppressed in release builds — zero overhead in production.
/// Enable/disable at runtime in debug builds via [SduiLogger.enabled].
///
/// ```dart
/// // Silence during tests:
/// SduiLogger.enabled = false;
/// ```
abstract final class SduiLogger {
  /// Whether logging is active. Defaults to `true` in debug mode.
  static bool enabled = kDebugMode;

  /// Log tag prepended to every message.
  static String tag = 'SDUI';

  /// Logs a network-layer event (fetch, retry, WebSocket connect).
  static void network(String message, {Object? data}) =>
      _log('NET', message, data: data);

  /// Logs a parser event (version check, node construction).
  static void parse(String message, {Object? data}) =>
      _log('PARSE', message, data: data);

  /// Logs a render event (node → widget mapping).
  static void render(String message, {Object? data}) =>
      _log('RENDER', message, data: data);

  /// Logs an action event (dispatch, debounce, middleware).
  static void action(String message, {Object? data}) =>
      _log('ACTION', message, data: data);

  /// Logs a cache event (hit, miss, invalidation).
  static void cache(String message, {Object? data}) =>
      _log('CACHE', message, data: data);

  /// Logs a non-fatal warning with optional [error] and [stackTrace].
  static void warn(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode || !enabled) return;
    debugPrint('[$tag:WARN] $message');
    if (error != null) debugPrint('  error: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
    }
  }

  /// Logs a fatal error with optional [error] and [stackTrace].
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode || !enabled) return;
    debugPrint('[$tag:ERROR] $message');
    if (error != null) debugPrint('  error: $error');
    if (stackTrace != null) {
      debugPrintStack(stackTrace: stackTrace, maxFrames: 10);
    }
  }

  static void _log(String category, String message, {Object? data}) {
    if (!kDebugMode || !enabled) return;
    debugPrint('[$tag:$category] $message');
    if (data != null) debugPrint('  data: $data');
  }
}
