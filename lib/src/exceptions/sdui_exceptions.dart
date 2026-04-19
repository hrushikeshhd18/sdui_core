/// Base class for all sdui_core exceptions.
abstract class SduiException implements Exception {
  /// Human-readable description of what went wrong.
  final String message;

  /// Creates an [SduiException] with the given [message].
  const SduiException(this.message);

  @override
  String toString() => 'SduiException: $message';
}

/// Thrown when the JSON payload cannot be parsed into a valid node tree.
class SduiParseException extends SduiException {
  /// The `type` field of the node that triggered this error.
  final String nodeType;

  /// The dot-separated path in the tree where parsing failed, e.g. `root/hero/0`.
  final String path;

  /// Creates a [SduiParseException].
  const SduiParseException({
    required this.nodeType,
    required this.path,
    required String message,
  }) : super(message);

  @override
  String toString() =>
      'SduiParseException at "$path" (type: "$nodeType"): $message';
}

/// Thrown when an HTTP request to fetch a JSON layout fails.
class SduiNetworkException extends SduiException {
  /// The URL that was requested.
  final String url;

  /// The HTTP status code returned, or `null` if no response was received.
  final int? statusCode;

  /// Creates a [SduiNetworkException].
  const SduiNetworkException({
    required this.url,
    this.statusCode,
    required String message,
  }) : super(message);

  @override
  String toString() {
    final code = statusCode != null ? ' (HTTP $statusCode)' : '';
    return 'SduiNetworkException$code for "$url": $message';
  }
}

/// Thrown when the payload declares a schema version that this engine does
/// not support.
class SduiVersionException extends SduiException {
  /// The version string found in the payload.
  final String receivedVersion;

  /// The list of schema versions this engine can handle.
  final List<String> supportedVersions;

  /// Creates a [SduiVersionException].
  SduiVersionException({
    required this.receivedVersion,
    required this.supportedVersions,
    String? message,
  }) : super(
          message ??
              'Unsupported sdui_version "$receivedVersion". '
                  'Supported: ${supportedVersions.join(', ')}',
        );

  @override
  String toString() =>
      'SduiVersionException: received "$receivedVersion", '
      'supported: [${supportedVersions.join(', ')}]';
}

/// Thrown when the renderer encounters a node type that has no registered
/// builder and no fallback is configured.
class SduiUnknownWidgetException extends SduiException {
  /// The unregistered widget type string, e.g. `"myapp:banner"`.
  final String type;

  /// The dot-separated path to the node in the tree.
  final String path;

  /// Creates a [SduiUnknownWidgetException].
  const SduiUnknownWidgetException({
    required this.type,
    required this.path,
    String? message,
  }) : super(
          message ??
              'No builder registered for widget type "$type" at path "$path".',
        );

  @override
  String toString() =>
      'SduiUnknownWidgetException: unknown type "$type" at "$path"';
}

/// Thrown when an action handler encounters an error during execution.
class SduiActionException extends SduiException {
  /// The name of the action that failed.
  final String actionName;

  /// Creates a [SduiActionException].
  const SduiActionException({
    required this.actionName,
    required String message,
  }) : super(message);

  @override
  String toString() =>
      'SduiActionException for action "$actionName": $message';
}
