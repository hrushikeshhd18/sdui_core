import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

SduiActionContext _fakeCtx(BuildContext ctx) => SduiActionContext(
      flutterContext: ctx,
      nodeProps: const {},
      nodePath: 'root',
    );

void main() {
  group('SduiActionRegistry — registration', () {
    testWidgets('registered handler is called on dispatch', (tester) async {
      var called = false;
      final reg = SduiActionRegistry()
        ..register('my_event', (action, ctx) async {
          called = true;
          return const SduiActionResult.success();
        });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              reg.dispatch(
                'my_event',
                const SduiAction(type: 'dispatch', event: 'my_event'),
                _fakeCtx(ctx),
              );
              return const Scaffold();
            },
          ),
        ),
      );
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('throws SduiActionException for unregistered event', (tester) async {
      final reg = SduiActionRegistry();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              expectLater(
                reg.dispatch(
                  'missing',
                  const SduiAction(type: 'dispatch', event: 'missing'),
                  _fakeCtx(ctx),
                ),
                throwsA(isA<SduiActionException>()),
              );
              return const Scaffold();
            },
          ),
        ),
      );
    });

    testWidgets('onUnhandled callback fires for unknown events', (tester) async {
      String? capturedEvent;
      final reg = SduiActionRegistry(onUnhandled: (e) => capturedEvent = e);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              reg
                  .dispatch(
                    'unknown_event',
                    const SduiAction(type: 'dispatch', event: 'unknown_event'),
                    _fakeCtx(ctx),
                  )
                  .ignore();
              return const Scaffold();
            },
          ),
        ),
      );
      await tester.pump();
      expect(capturedEvent, 'unknown_event');
    });

    test('hasHandler returns true for registered events', () {
      final reg = SduiActionRegistry()
        ..register('buy_now', (_, __) async => const SduiActionResult.success());
      expect(reg.hasHandler('buy_now'), isTrue);
      expect(reg.hasHandler('unknown'), isFalse);
    });

    test('unregister removes handler', () {
      final reg = SduiActionRegistry()
        ..register('ev', (_, __) async => const SduiActionResult.success())
        ..unregister('ev');
      expect(reg.hasHandler('ev'), isFalse);
    });

    test('clear removes all handlers', () {
      final reg = SduiActionRegistry()
        ..register('a', (_, __) async => const SduiActionResult.success())
        ..register('b', (_, __) async => const SduiActionResult.success())
        ..clear();
      expect(reg.hasHandler('a'), isFalse);
    });
  });

  group('SduiActionRegistry — middleware', () {
    testWidgets('middleware runs before handler', (tester) async {
      final log = <String>[];
      final reg = SduiActionRegistry()
        ..addMiddleware((action, ctx, next) async {
          log.add('middleware');
          return next();
        })
        ..register('ev', (_, __) async {
          log.add('handler');
          return const SduiActionResult.success();
        });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              reg.dispatch(
                'ev',
                const SduiAction(type: 'dispatch', event: 'ev'),
                _fakeCtx(ctx),
              );
              return const Scaffold();
            },
          ),
        ),
      );
      await tester.pump();
      expect(log, ['middleware', 'handler']);
    });

    testWidgets('middleware can short-circuit handler', (tester) async {
      var handlerCalled = false;
      final reg = SduiActionRegistry()
        ..addMiddleware((action, ctx, next) async =>
            const SduiActionResult.failure(message: 'blocked'),)
        ..register('ev', (_, __) async {
          handlerCalled = true;
          return const SduiActionResult.success();
        });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              reg.dispatch(
                'ev',
                const SduiAction(type: 'dispatch', event: 'ev'),
                _fakeCtx(ctx),
              );
              return const Scaffold();
            },
          ),
        ),
      );
      await tester.pump();
      expect(handlerCalled, isFalse);
    });
  });

  group('SduiActionRegistry — debounce', () {
    testWidgets('debounce prevents second immediate dispatch', (tester) async {
      var callCount = 0;
      final reg = SduiActionRegistry()
        ..register('ev', (_, __) async {
          callCount++;
          return const SduiActionResult.success();
        });

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              const action = SduiAction(
                type: 'dispatch',
                event: 'ev',
                debounceMs: 500,
              );
              reg.dispatch('ev', action, _fakeCtx(ctx));
              reg.dispatch('ev', action, _fakeCtx(ctx));
              return const Scaffold();
            },
          ),
        ),
      );
      await tester.pump();
      expect(callCount, 1);
    });
  });

  group('SduiActionResult', () {
    test('success result has isSuccess true', () {
      const r = SduiActionResult.success(data: 42);
      expect(r.isSuccess, isTrue);
      expect(r.data, 42);
    });

    test('failure result has isSuccess false', () {
      const r = SduiActionResult.failure(message: 'oops', error: 'err');
      expect(r.isSuccess, isFalse);
      expect(r.message, 'oops');
      expect(r.error, 'err');
    });
  });
}
