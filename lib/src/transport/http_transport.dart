import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/transport/sdui_transport.dart';
import 'package:sdui_core/src/utils/sdui_logger.dart';

/// [SduiTransport] implementation using HTTP GET requests.
///
/// Supports configurable timeout and retry with exponential back-off:
/// ```dart
/// SduiScreen(
///   url: 'https://api.example.com/layouts/home',
///   transport: HttpSduiTransport(
///     timeout: const Duration(seconds: 15),
///     retryCount: 3,
///   ),
/// )
/// ```
final class HttpSduiTransport implements SduiTransport {
  /// Creates an [HttpSduiTransport].
  ///
  /// If [client] is omitted, a plain [http.Client] is used and will be closed
  /// on [dispose].
  HttpSduiTransport({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
    this.retryCount = 3,
    this.retryDelay = const Duration(milliseconds: 500),
  })  : _client = client ?? http.Client(),
        _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;

  /// Maximum time to wait for a single HTTP response.
  final Duration timeout;

  /// Number of additional attempts on failure (0 = no retry).
  final int retryCount;

  /// Base delay between retries — doubles on each attempt (exponential back-off).
  final Duration retryDelay;

  static const Map<String, String> _defaultHeaders = {
    'Accept': 'application/json',
  };

  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    final merged = {..._defaultHeaders, ...?headers};
    final uri = Uri.parse(url);

    SduiLogger.network('GET $url');

    Object? lastError;
    for (var attempt = 0; attempt <= retryCount; attempt++) {
      try {
        final response = await _client
            .get(uri, headers: merged)
            .timeout(timeout);

        SduiLogger.network('$url → ${response.statusCode}');

        if (response.statusCode != 200) {
          throw SduiNetworkException(
            url: url,
            statusCode: response.statusCode,
            message: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          );
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map) {
          throw SduiNetworkException(
            url: url,
            message: 'Response body is not a JSON object.',
          );
        }
        return Map<String, Object?>.from(decoded);
      } on SduiNetworkException {
        rethrow; // never retry on explicit HTTP error codes
      } on Exception catch (e, st) {
        lastError = e;
        if (attempt < retryCount) {
          final delay = retryDelay * (1 << attempt); // exponential back-off
          SduiLogger.warn(
            'Fetch attempt ${attempt + 1} failed for $url — retrying in ${delay.inMilliseconds}ms',
            error: e,
            stackTrace: st,
          );
          await Future<void>.delayed(delay);
        }
      }
    }

    throw SduiNetworkException(
      url: url,
      message: 'Failed after ${retryCount + 1} attempt(s): $lastError',
    );
  }

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) =>
      // HTTP transport is one-shot — emit a single value then close.
      Stream.fromFuture(fetch(url, headers: headers));

  @override
  Future<void> dispose() async {
    if (_ownsClient) _client.close();
  }
}
