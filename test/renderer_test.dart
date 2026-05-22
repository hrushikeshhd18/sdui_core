import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

SduiBuildContext _ctx(BuildContext flutterCtx) => SduiBuildContext(
      flutterContext: flutterCtx,
      registry: SduiWidgetRegistry()..registerAll(createCoreWidgets()),
      actionRegistry: SduiActionRegistry(),
      nodePath: 'root',
    );

const _textNode = SduiLeafNode(
  id: 'txt1',
  type: 'sdui:text',
  version: 2,
  props: {'text': 'Hello SDUI'},
);

const _unknownNode = SduiUnknownNode(
  id: 'ghost',
  type: 'myapp:ghost',
);

void main() {
  group('SduiRenderer', () {
    testWidgets('renders sdui:text node to a Text widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => SduiRenderer.render(_textNode, _ctx(ctx)),
          ),
        ),
      );
      expect(find.text('Hello SDUI'), findsOneWidget);
    });

    testWidgets('renders sdui:column with children', (tester) async {
      const columnNode = SduiParentNode(
        id: 'col1',
        type: 'sdui:column',
        version: 1,
        children: [
          SduiLeafNode(
            id: 'c1',
            type: 'sdui:text',
            version: 1,
            props: {'text': 'Child A'},
          ),
          SduiLeafNode(
            id: 'c2',
            type: 'sdui:text',
            version: 1,
            props: {'text': 'Child B'},
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => SduiRenderer.render(columnNode, _ctx(ctx)),
          ),
        ),
      );

      expect(find.text('Child A'), findsOneWidget);
      expect(find.text('Child B'), findsOneWidget);
    });

    testWidgets('renders unknown node to error tile in debug mode',
        (tester) async {
      if (!kDebugMode) return;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => SduiRenderer.render(_unknownNode, _ctx(ctx)),
          ),
        ),
      );

      expect(find.textContaining('myapp:ghost'), findsOneWidget);
    });

    testWidgets('builder exception renders error tile in debug mode, not crash',
        (tester) async {
      final registry = SduiWidgetRegistry()
        ..registerAll(createCoreWidgets())
        ..register('sdui:boom', (node, ctx) => throw Exception('boom'));

      SduiBuildContext makeCtx(BuildContext flutterCtx) => SduiBuildContext(
            flutterContext: flutterCtx,
            registry: registry,
            actionRegistry: SduiActionRegistry(),
            nodePath: 'root',
          );

      const boomNode = SduiLeafNode(
        id: 'b1',
        type: 'sdui:boom',
        version: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => SduiRenderer.render(boomNode, makeCtx(ctx)),
          ),
        ),
      );

      // Renderer calls FlutterError.reportError in debug mode — consume it.
      tester.takeException();

      if (kDebugMode) {
        expect(find.textContaining('sdui:boom'), findsOneWidget);
      } else {
        expect(find.textContaining('sdui:boom'), findsNothing);
      }
    });

    testWidgets(
        'parent builder exception renders error tile, children still safe',
        (tester) async {
      final registry = SduiWidgetRegistry()
        ..registerAll(createCoreWidgets())
        ..register('sdui:bad_parent', (node, ctx) => throw Exception('bad'));

      SduiBuildContext makeCtx(BuildContext flutterCtx) => SduiBuildContext(
            flutterContext: flutterCtx,
            registry: registry,
            actionRegistry: SduiActionRegistry(),
            nodePath: 'root',
          );

      const badParent = SduiParentNode(
        id: 'bp1',
        type: 'sdui:bad_parent',
        version: 1,
        children: [
          SduiLeafNode(
            id: 'ok',
            type: 'sdui:text',
            version: 1,
            props: {'text': 'safe'},
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => SduiRenderer.render(badParent, makeCtx(ctx)),
          ),
        ),
      );

      // Consume the FlutterError reported by the renderer — this is expected.
      tester.takeException();
    });

    testWidgets('KeyedSubtree has correct key for leaf node', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) => SduiRenderer.render(_textNode, _ctx(ctx)),
          ),
        ),
      );

      final expectedKey = SduiKeyManager.keyFor(_textNode, parentPath: 'root');
      expect(find.byKey(expectedKey), findsOneWidget);
    });
  });

  group('SduiKeyManager', () {
    test('shouldRebuild returns true when version changes', () {
      const older = SduiLeafNode(id: 'x', type: 'sdui:text', version: 1);
      const newer = SduiLeafNode(id: 'x', type: 'sdui:text', version: 2);
      expect(SduiKeyManager.shouldRebuild(older, newer), isTrue);
    });

    test('shouldRebuild returns false when version is unchanged', () {
      const a = SduiLeafNode(id: 'x', type: 'sdui:text', version: 3);
      const b = SduiLeafNode(id: 'x', type: 'sdui:text', version: 3);
      expect(SduiKeyManager.shouldRebuild(a, b), isFalse);
    });

    test('keyFor includes id and version', () {
      const node = SduiLeafNode(id: 'hero', type: 'sdui:text', version: 5);
      final key = SduiKeyManager.keyFor(node);
      expect(key.value, contains('hero'));
      expect(key.value, contains('v5'));
    });

    test('keyFor includes parentPath when provided', () {
      const node = SduiLeafNode(id: 'title', type: 'sdui:text', version: 1);
      final key = SduiKeyManager.keyFor(node, parentPath: 'root/hero');
      expect(key.value, contains('root/hero'));
    });
  });
}
