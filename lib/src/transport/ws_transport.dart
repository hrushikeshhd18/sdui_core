import 'dart:async';
import 'dart:convert';

import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:sdui_core/src/transport/sdui_transport.dart';
import 'package:sdui_core/src/utils/sdui_logger.dart';

/// [SduiTransport] implementation using WebSocket for live SDUI updates.
///
/// Connects once, streams every JSON message as a new layout, and
/// auto-reconnects on disconnect with exponential back-off:
/// ```dart
/// SduiScreen(
///   url: 'wss://api.example.com/layouts/home/live',
///   transport: WebSocketSduiTransport(),
/// )
/// ```
final class WebSocketSduiTransport implements SduiTransport {
  /// Creates a [WebSocketSduiTransport].
  WebSocketSduiTransport({
    this.reconnectDelay = const Duration(seconds: 2),
    this.maxReconnectAttempts = 5,
    this.pingInterval = const Duration(seconds: 30),
  });

  /// Base delay before the first reconnect attempt.
  final Duration reconnectDelay;

  /// Maximum number of reconnect attempts before giving up.
  final int maxReconnectAttempts;

  /// How often to send a ping frame to keep the connection alive.
  final Duration pingInterval;

  WebSocketChannel? _channel;
  Timer? _pingTimer;
  bool _disposed = false;

  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    // For HTTP-style one-shot use, take the first message from the stream.
    return subscribe(url, headers: headers).first;
  }

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) {
    final controller = StreamController<Map<String, Object?>>.broadcast();

    () async {
      var attempts = 0;
      while (!_disposed && attempts <= maxReconnectAttempts) {
        try {
          SduiLogger.network('WS connecting: $url (attempt ${attempts + 1})');
          _channel = WebSocketChannel.connect(Uri.parse(url));
          await _channel!.ready;
          SduiLogger.network('WS connected: $url');

          attempts = 0; // reset on successful connect
          _startPing();

          await for (final msg in _channel!.stream) {
            if (_disposed) break;
            if (msg is String) {
              try {
                final decoded = jsonDecode(msg);
                if (decoded is Map) {
                  controller.add(Map<String, Object?>.from(decoded));
                } else {
                  SduiLogger.warn('WS: received non-object JSON — ignoring');
                }
              } on Exception catch (e) {
                SduiLogger.warn('WS: failed to parse message', error: e);
              }
            }
          }
        } on Exception catch (e, st) {
          SduiLogger.warn('WS error on $url', error: e, stackTrace: st);
        }

        _stopPing();
        if (_disposed) break;
        attempts++;
        if (attempts > maxReconnectAttempts) break;

        final delay = reconnectDelay * (1 << (attempts - 1));
        SduiLogger.network('WS reconnecting in ${delay.inSeconds}s…');
        await Future<void>.delayed(delay);
      }

      if (!controller.isClosed) {
        if (!_disposed) {
          controller.addError(
            SduiNetworkException(
              url: url,
              message:
                  'WebSocket permanently disconnected after $maxReconnectAttempts attempts.',
            ),
          );
        }
        await controller.close();
      }
    }();

    return controller.stream;
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      try {
        _channel?.sink.add('ping');
      } on Exception catch (e) {
        SduiLogger.warn('WS ping failed', error: e);
      }
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    _stopPing();
    await _channel?.sink.close();
    _channel = null;
  }
}
