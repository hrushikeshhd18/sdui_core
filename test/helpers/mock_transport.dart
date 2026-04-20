import 'dart:async';

import 'package:sdui_core/sdui_core.dart';

/// A transport that returns a fixed payload immediately.
final class MockSduiTransport implements SduiTransport {
  MockSduiTransport(this._payload);

  final Map<String, Object?> _payload;
  int fetchCallCount = 0;

  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    fetchCallCount++;
    return _payload;
  }

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) =>
      Stream.value(_payload);

  @override
  Future<void> dispose() async {}
}

/// A transport that fails [failCount] times then succeeds.
final class FailThenSucceedTransport implements SduiTransport {
  FailThenSucceedTransport({
    required this.failCount,
    required Map<String, Object?> payload,
  }) : _payload = payload;

  final int failCount;
  final Map<String, Object?> _payload;
  int _attempts = 0;

  int get attempts => _attempts;

  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    _attempts++;
    if (_attempts <= failCount) {
      throw SduiNetworkException(
        url: url,
        message: 'Simulated failure #$_attempts',
      );
    }
    return _payload;
  }

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) =>
      Stream.fromFuture(fetch(url, headers: headers));

  @override
  Future<void> dispose() async {}
}

/// A transport that waits [delay] before returning a payload.
final class SlowTransport implements SduiTransport {
  SlowTransport({required this.delay, required Map<String, Object?> payload})
      : _payload = payload;

  final Duration delay;
  final Map<String, Object?> _payload;

  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    await Future<void>.delayed(delay);
    return _payload;
  }

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) =>
      Stream.fromFuture(fetch(url, headers: headers));

  @override
  Future<void> dispose() async {}
}

/// A transport that emits multiple payloads over time (WebSocket simulation).
final class StreamTransport implements SduiTransport {
  StreamTransport(this._payloads);

  final List<Map<String, Object?>> _payloads;

  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async =>
      _payloads.first;

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) =>
      Stream.fromIterable(_payloads);

  @override
  Future<void> dispose() async {}
}

/// A transport that always throws.
final class ErrorTransport implements SduiTransport {
  ErrorTransport({String url = 'https://test.example.com'}) : _url = url;

  final String _url;

  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    throw SduiNetworkException(url: _url, message: 'Simulated error');
  }

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) =>
      Stream.error(SduiNetworkException(url: _url, message: 'Simulated error'));

  @override
  Future<void> dispose() async {}
}
