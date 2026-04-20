import 'package:sdui_core/sdui_core.dart' show HttpSduiTransport, SduiNetworkException, WebSocketSduiTransport;

/// Abstract transport layer for fetching SDUI payloads.
///
/// Swap the default [HttpSduiTransport] for [WebSocketSduiTransport],
/// a mock in tests, or a custom gRPC implementation:
/// ```dart
/// SduiScreen(
///   url: 'wss://api.example.com/home/live',
///   transport: WebSocketSduiTransport(),
/// )
/// ```
abstract interface class SduiTransport {
  /// Fetches a UI payload once and returns it as a decoded JSON map.
  ///
  /// Throws [SduiNetworkException] on HTTP/network failure.
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  });

  /// Returns a stream of UI payloads for live-update transports (WebSocket).
  ///
  /// HTTP transports emit a single item then close.
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  });

  /// Cancels any active subscriptions and releases underlying resources.
  Future<void> dispose();
}
