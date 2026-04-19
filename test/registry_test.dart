import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Widget _stub(SduiNode _, SduiBuildContext __) => const SizedBox();

void main() {
  late SduiWidgetRegistry registry;

  setUp(() {
    // Use a fresh instance per test by clearing the global singleton.
    registry = SduiWidgetRegistry.instance;
    registry.clear();
  });

  tearDown(() {
    registry.clear();
  });

  group('SduiWidgetRegistry', () {
    test('register stores the builder', () {
      registry.register('sdui:text', _stub);
      expect(registry.isRegistered('sdui:text'), isTrue);
    });

    test('isRegistered returns false for unknown type', () {
      expect(registry.isRegistered('sdui:ghost'), isFalse);
    });

    test('resolve returns the correct builder', () {
      registry.register('sdui:text', _stub);
      final builder = registry.resolve('sdui:text', 'root');
      expect(builder, same(_stub));
    });

    test('resolve returns fallback for unknown type', () {
      registry.setFallback(_stub);
      final builder = registry.resolve('myapp:unknown', 'root');
      expect(builder, same(_stub));
    });

    test('resolve throws SduiUnknownWidgetException if no fallback is set', () {
      expect(
        () => registry.resolve('myapp:missing', 'root/hero'),
        throwsA(isA<SduiUnknownWidgetException>()),
      );
    });

    test('unregister removes the builder', () {
      registry.register('sdui:text', _stub);
      registry.unregister('sdui:text');
      expect(registry.isRegistered('sdui:text'), isFalse);
    });

    test('clear removes all registrations', () {
      registry.register('sdui:text', _stub);
      registry.register('sdui:image', _stub);
      registry.clear();
      expect(registry.registeredTypes, isEmpty);
    });

    test('registeredTypes lists all registered types', () {
      registry.register('sdui:a', _stub);
      registry.register('sdui:b', _stub);
      expect(registry.registeredTypes, containsAll(['sdui:a', 'sdui:b']));
    });

    test('registerAll registers multiple builders at once', () {
      registry.registerAll({'sdui:x': _stub, 'sdui:y': _stub});
      expect(registry.isRegistered('sdui:x'), isTrue);
      expect(registry.isRegistered('sdui:y'), isTrue);
    });
  });
}
