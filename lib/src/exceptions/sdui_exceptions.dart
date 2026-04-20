/// Base class for all exceptions thrown by `sdui_core`.
///
/// Every exception carries:
/// - [code]    — a machine-readable identifier for programmatic handling.
/// - [message] — a human-readable description of what went wrong.
/// - [hint]    — an actionable suggestion for how to fix the issue.
sealed class SduiException implements Exception {
  /// Creates an [SduiException].
  const SduiException({
    required this.code,
    required this.message,
    required this.hint,
  });

  /// Machine-readable error code, e.g. `'SDUI_001'`.
  final String code;

  /// Human-readable description of what went wrong.
  final String message;

  /// Actionable hint for resolving the issue.
  final String hint;

  @override
  String toString() => '[$code] $message\nHint: $hint';
}

// ---------------------------------------------------------------------------

/// Thrown when a node's JSON cannot be parsed into a valid [SduiNode].
final class SduiParseException extends SduiException {
  /// Creates a [SduiParseException].
  SduiParseException({
    required this.path,
    required String message,
    this.receivedValue,
    String code = 'SDUI_001',
  }) : super(
          code: code,
          message: message,
          hint: 'Inspect the JSON payload at path "$path".'
              '${receivedValue != null ? ' Received: $receivedValue' : ''}',
        );

  /// The dot-separated path in the node tree where parsing failed.
  final String path;

  /// The value that was actually received (for debugging).
  final Object? receivedValue;

  @override
  String toString() => '[$code] Parse error at "$path": $message\nHint: $hint';
}

// ---------------------------------------------------------------------------

/// Thrown when the payload declares an unsupported `sdui_version`.
final class SduiVersionException extends SduiException {
  /// Creates a [SduiVersionException].
  SduiVersionException({
    required this.receivedVersion,
    required this.supportedVersions,
  }) : super(
          code: 'SDUI_002',
          message: 'Unsupported schema version: "$receivedVersion"',
          hint: 'The server is sending version "$receivedVersion" but this '
              'client supports: ${supportedVersions.join(', ')}. '
              'Update sdui_core or the server schema.',
        );

  /// The version string found in the payload.
  final String receivedVersion;

  /// The versions this engine can handle.
  final List<String> supportedVersions;
}

// ---------------------------------------------------------------------------

/// Thrown when an HTTP request to fetch a layout fails.
final class SduiNetworkException extends SduiException {
  /// Creates a [SduiNetworkException].
  SduiNetworkException({
    required this.url,
    this.statusCode,
    required String message,
  }) : super(
          code: 'SDUI_003',
          message: message,
          hint: 'Check network connectivity and the server at "$url".'
              '${statusCode != null ? ' HTTP status: $statusCode.' : ''}',
        );

  /// The URL that was requested.
  final String url;

  /// The HTTP status code returned, or `null` if no response was received.
  final int? statusCode;

  @override
  String toString() {
    final code = statusCode != null ? ' (HTTP $statusCode)' : '';
    return '[SDUI_003] Network error$code for "$url": $message\nHint: $hint';
  }
}

// ---------------------------------------------------------------------------

/// Thrown when the renderer encounters a node type with no registered builder
/// and no fallback is configured.
final class SduiUnknownWidgetException extends SduiException {
  /// Creates a [SduiUnknownWidgetException].
  SduiUnknownWidgetException({
    required this.type,
    required this.path,
    String? message,
  }) : super(
          code: 'SDUI_004',
          message:
              message ?? 'No builder registered for widget type "$type".',
          hint: 'Register a builder: '
              'SduiWidgetRegistry.defaults.register("$type", myBuilder);\n'
              'Or set a fallback: registry.setFallback(myFallbackBuilder).',
        );

  /// The unregistered widget type string.
  final String type;

  /// The dot-separated path to the offending node.
  final String path;

  @override
  String toString() =>
      '[SDUI_004] Unknown widget "$type" at "$path"\nHint: $hint';
}

// ---------------------------------------------------------------------------

/// Thrown when an action handler encounters an error during execution.
final class SduiActionException extends SduiException {
  /// Creates a [SduiActionException].
  SduiActionException({
    required this.actionName,
    required String message,
  }) : super(
          code: 'SDUI_005',
          message: message,
          hint: 'Register a handler: '
              'SduiActionRegistry.defaults.register("$actionName", myHandler);',
        );

  /// The event name that failed.
  final String actionName;

  @override
  String toString() =>
      '[SDUI_005] Action error for "$actionName": $message\nHint: $hint';
}

// ---------------------------------------------------------------------------

/// Thrown when a cache operation fails (e.g. serialization error).
final class SduiCacheException extends SduiException {
  /// Creates a [SduiCacheException].
  const SduiCacheException({
    required String message,
    this.url,
  }) : super(
          code: 'SDUI_006',
          message: message,
          hint: 'Ensure SduiCache.init() was awaited before use. '
              'Call SduiCache.instance.clear() to reset corrupted entries.',
        );

  /// The URL whose cache entry caused the error, if applicable.
  final String? url;
}
