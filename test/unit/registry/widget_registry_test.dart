import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Widget _stubBuilder(SduiNode node, SduiBuildContext ctx) =>
    const SizedBox.shrink();

void main() {
  group('SduiWidgetRegistry — basic registration', () {
    test('register and resolve exact type', () {
      final reg = SduiWidgetRegistry()..register('myapp:banner', _stubBuilder);
      final builder = reg.resolve('myapp:banner', nodePath: 'root');
      expect(builder, same(_stubBuilder));
    });

    test('isRegistered returns true for registered type', () {
      final reg = SduiWidgetRegistry()..register('sdui:text', _stubBuilder);
      expect(reg.isRegistered('sdui:text'), isTrue);
    });

    test('isRegistered returns false for unknown type', () {
      final reg = SduiWidgetRegistry();
      expect(reg.isRegistered('sdui:text'), isFalse);
    });

    test('registerAll adds all entries', () {
      final reg = SduiWidgetRegistry()
        ..registerAll({
          'a:one': _stubBuilder,
          'a:two': _stubBuilder,
        });
      expect(reg.isRegistered('a:one'), isTrue);
      expect(reg.isRegistered('a:two'), isTrue);
    });

    test('register overwrites previous builder for same type', () {
      Widget newBuilder(SduiNode n, SduiBuildContext c) => const SizedBox();
      final reg = SduiWidgetRegistry()
        ..register('myapp:x', _stubBuilder)
        ..register('myapp:x', newBuilder);
      expect(reg.resolve('myapp:x', nodePath: 'root'), same(newBuilder));
    });

    test('unregister removes the builder', () {
      final reg = SduiWidgetRegistry()
        ..register('myapp:x', _stubBuilder)
        ..unregister('myapp:x');
      expect(reg.isRegistered('myapp:x'), isFalse);
    });

    test('clear removes all builders', () {
      final reg = SduiWidgetRegistry()
        ..register('a:x', _stubBuilder)
        ..register('a:y', _stubBuilder)
        ..clear();
      expect(reg.registeredTypes, isEmpty);
    });
  });

  group('SduiWidgetRegistry — namespace wildcard', () {
    test('wildcard matches unknown type in namespace', () {
      final reg = SduiWidgetRegistry()
        ..registerNamespaceWildcard('myapp', _stubBuilder);
      final builder = reg.resolve('myapp:anything', nodePath: 'root');
      expect(builder, same(_stubBuilder));
    });

    test('exact match takes precedence over wildcard', () {
      Widget exact(SduiNode n, SduiBuildContext c) => const Text('exact');
      final reg = SduiWidgetRegistry()
        ..registerNamespaceWildcard('myapp', _stubBuilder)
        ..register('myapp:specific', exact);
      expect(reg.resolve('myapp:specific', nodePath: 'root'), same(exact));
    });
  });

  group('SduiWidgetRegistry — fallback', () {
    test('fallback is used when no exact or wildcard match', () {
      final reg = SduiWidgetRegistry()..setFallback(_stubBuilder);
      final builder = reg.resolve('unknown:type', nodePath: 'root');
      expect(builder, same(_stubBuilder));
    });

    test('throws SduiUnknownWidgetException with no fallback', () {
      final reg = SduiWidgetRegistry();
      expect(
        () => reg.resolve('unknown:type', nodePath: 'root'),
        throwsA(isA<SduiUnknownWidgetException>()),
      );
    });
  });

  group('SduiWidgetRegistry — debug helpers', () {
    test('registeredTypes lists all types', () {
      final reg = SduiWidgetRegistry()
        ..register('a:x', _stubBuilder)
        ..register('b:y', _stubBuilder);
      expect(reg.registeredTypes, containsAll(['a:x', 'b:y']));
    });

    test('debugDescription includes namespace and counts', () {
      final reg = SduiWidgetRegistry()
        ..register('sdui:text', _stubBuilder)
        ..register('sdui:image', _stubBuilder);
      expect(reg.debugDescription, contains('sdui'));
      expect(reg.debugDescription, contains('2'));
    });
  });

  group('SduiWidgetRegistry — defaults', () {
    test('a registry pre-loaded with createCoreWidgets has sdui:text', () {
      final reg = SduiWidgetRegistry()..registerAll(createCoreWidgets());
      expect(reg.isRegistered('sdui:text'), isTrue);
      expect(reg.isRegistered('sdui:column'), isTrue);
    });

    test('two registries built from createCoreWidgets are independent', () {
      final reg1 = SduiWidgetRegistry()..registerAll(createCoreWidgets());
      final reg2 = SduiWidgetRegistry()..registerAll(createCoreWidgets());
      reg1.clear();
      expect(reg2.isRegistered('sdui:text'), isTrue);
    });
  });

  group('SduiBuildContext', () {
    testWidgets('childWidgets returns empty list for unknown id', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (ctx) {
            final sdCtx = SduiBuildContext(
              flutterContext: ctx,
              registry: SduiWidgetRegistry(),
              actionRegistry: SduiActionRegistry(),
              nodePath: 'root',
            );
            const node = SduiLeafNode(id: 'x', type: 'sdui:text');
            expect(sdCtx.childWidgets(node), isEmpty);
            return const SizedBox.shrink();
          },
        ),
      );
    });

    testWidgets('withChildren stores and retrieves children', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (ctx) {
            final sdCtx = SduiBuildContext(
              flutterContext: ctx,
              registry: SduiWidgetRegistry(),
              actionRegistry: SduiActionRegistry(),
              nodePath: 'root',
            );
            final widgets = [const SizedBox(), const SizedBox()];
            final updated = sdCtx.withChildren('col', widgets);
            const node = SduiParentNode(id: 'col', type: 'sdui:column');
            expect(updated.childWidgets(node).length, 2);
            return const SizedBox.shrink();
          },
        ),
      );
    });
  });
}
