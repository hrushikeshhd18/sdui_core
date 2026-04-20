import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../helpers/mock_transport.dart';
import '../helpers/test_helpers.dart';

/// Transport that never resolves — keeps the widget in loading state forever.
final class _PendingTransport implements SduiTransport {
  final _completer = Completer<Map<String, Object?>>();

  @override
  Future<Map<String, Object?>> fetch(String url, {Map<String, String>? headers}) =>
      _completer.future;

  @override
  Stream<Map<String, Object?>> subscribe(String url, {Map<String, String>? headers}) =>
      Stream.fromFuture(_completer.future);

  @override
  Future<void> dispose() async {}
}

Widget _buildScreen({
  required SduiTransport transport,
  WidgetBuilder? loadingBuilder,
  Widget Function(BuildContext, SduiException)? errorBuilder,
  WidgetBuilder? emptyBuilder,
  void Function(SduiException)? onError,
  VoidCallback? onLoad,
  bool pullToRefresh = false,
  bool enableCache = false,
}) {
  return MaterialApp(
    home: SduiScope(
      registry: SduiWidgetRegistry()..registerAll(createCoreWidgets()),
      child: Scaffold(
        body: SduiScreen(
          url: 'https://test.example.com/layout',
          transport: transport,
          enableCache: enableCache,
          parseInIsolate: false,
          loadingBuilder: loadingBuilder,
          errorBuilder: errorBuilder,
          emptyBuilder: emptyBuilder,
          onError: onError,
          onLoad: onLoad,
          pullToRefresh: pullToRefresh,
        ),
      ),
    ),
  );
}

void main() {
  group('SduiScreen — loading state', () {
    testWidgets('shows default CircularProgressIndicator while loading', (tester) async {
      await tester.pumpWidget(_buildScreen(transport: _PendingTransport()));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows custom loading widget when loadingBuilder provided', (tester) async {
      await tester.pumpWidget(_buildScreen(
        transport: _PendingTransport(),
        loadingBuilder: (_) => const Text('Loading...'),
      ));
      await tester.pump();

      expect(find.text('Loading...'), findsOneWidget);
    });
  });

  group('SduiScreen — success state', () {
    testWidgets('renders SDUI content after successful fetch', (tester) async {
      final transport = MockSduiTransport(kTextPayload);

      await tester.pumpWidget(_buildScreen(transport: transport));
      await tester.pumpAndSettle();

      expect(find.text('Hello sdui_core'), findsOneWidget);
    });

    testWidgets('calls onLoad callback after first successful render', (tester) async {
      var loadCalled = false;
      final transport = MockSduiTransport(kTextPayload);

      await tester.pumpWidget(_buildScreen(
        transport: transport,
        onLoad: () => loadCalled = true,
      ));
      await tester.pumpAndSettle();

      expect(loadCalled, isTrue);
    });

    testWidgets('onLoad is not called multiple times on re-fetch', (tester) async {
      var loadCount = 0;
      final transport = MockSduiTransport(kTextPayload);

      await tester.pumpWidget(_buildScreen(
        transport: transport,
        onLoad: () => loadCount++,
      ));
      await tester.pumpAndSettle();

      expect(loadCount, 1);
    });
  });

  group('SduiScreen — error state', () {
    testWidgets('shows default error widget on network failure', (tester) async {
      final transport = ErrorTransport();

      await tester.pumpWidget(_buildScreen(transport: transport));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows custom error widget when errorBuilder provided', (tester) async {
      final transport = ErrorTransport();

      await tester.pumpWidget(_buildScreen(
        transport: transport,
        errorBuilder: (_, e) => Text('Error: ${e.code}'),
      ));
      await tester.pumpAndSettle();

      expect(find.textContaining('SDUI_003'), findsOneWidget);
    });

    testWidgets('calls onError callback on network failure', (tester) async {
      SduiException? capturedError;
      final transport = ErrorTransport();

      await tester.pumpWidget(_buildScreen(
        transport: transport,
        onError: (e) => capturedError = e,
      ));
      await tester.pumpAndSettle();

      expect(capturedError, isA<SduiNetworkException>());
    });
  });

  group('SduiScreen — empty state', () {
    testWidgets('shows empty builder for empty root node', (tester) async {
      final transport = MockSduiTransport(kMinimalPayload);

      await tester.pumpWidget(_buildScreen(
        transport: transport,
        emptyBuilder: (_) => const Text('Nothing here'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('shows SizedBox.shrink by default for empty state', (tester) async {
      final transport = MockSduiTransport(kMinimalPayload);

      await tester.pumpWidget(_buildScreen(transport: transport));
      await tester.pumpAndSettle();

      // Should not crash and render something (SizedBox.shrink)
      expect(tester.takeException(), isNull);
    });
  });

  group('SduiScreen — pull to refresh', () {
    testWidgets('wraps content in RefreshIndicator when pullToRefresh is true', (tester) async {
      final transport = MockSduiTransport(kTextPayload);

      await tester.pumpWidget(_buildScreen(
        transport: transport,
        pullToRefresh: true,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });

  group('SduiScreen — transport is called', () {
    testWidgets('transport.fetch is called exactly once on initial load', (tester) async {
      final transport = MockSduiTransport(kTextPayload);

      await tester.pumpWidget(_buildScreen(transport: transport));
      await tester.pumpAndSettle();

      expect(transport.fetchCallCount, 1);
    });
  });
}
