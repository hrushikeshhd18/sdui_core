import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('sdui:text', () {
    testWidgets('renders text from props', (tester) async {
      final node = SduiLeafNode(
        id: 't1',
        type: 'sdui:text',
        version: 1,
        props: const {'text': 'Hello World'},
      );
      await pumpSduiWidget(tester, node);
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('renders empty when text prop missing', (tester) async {
      final node = SduiLeafNode(
        id: 't2',
        type: 'sdui:text',
        version: 1,
        props: const {},
      );
      await pumpSduiWidget(tester, node);
      expect(tester.takeException(), isNull);
    });
  });

  group('sdui:image', () {
    testWidgets('renders image widget', (tester) async {
      final node = SduiLeafNode(
        id: 'img1',
        type: 'sdui:image',
        version: 1,
        props: const {'url': 'https://example.com/img.png'},
      );
      await pumpSduiWidget(tester, node);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('sdui:button', () {
    testWidgets('renders button with label', (tester) async {
      final node = SduiLeafNode(
        id: 'btn1',
        type: 'sdui:button',
        version: 1,
        props: const {'label': 'Click me'},
      );
      await pumpSduiWidget(tester, node);
      expect(find.text('Click me'), findsOneWidget);
    });
  });

  group('sdui:icon', () {
    testWidgets('renders Icon widget', (tester) async {
      final node = SduiLeafNode(
        id: 'ico1',
        type: 'sdui:icon',
        version: 1,
        props: const {'name': 'home'},
      );
      await pumpSduiWidget(tester, node);
      expect(find.byType(Icon), findsOneWidget);
    });
  });

  group('sdui:divider', () {
    testWidgets('renders Divider', (tester) async {
      final node = const SduiLeafNode(id: 'div1', type: 'sdui:divider', version: 1);
      await pumpSduiWidget(tester, node);
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('sdui:spacer', () {
    testWidgets('renders Spacer inside Flex', (tester) async {
      final node = SduiParentNode(
        id: 'col1',
        type: 'sdui:column',
        version: 1,
        children: [
          const SduiLeafNode(id: 'sp1', type: 'sdui:spacer', version: 1),
        ],
      );
      await pumpSduiWidget(tester, node);
      expect(find.byType(Spacer), findsOneWidget);
    });
  });

  group('sdui:column and sdui:row', () {
    testWidgets('sdui:column renders children vertically', (tester) async {
      final node = SduiParentNode(
        id: 'col1',
        type: 'sdui:column',
        version: 1,
        children: [
          SduiLeafNode(
            id: 'c1',
            type: 'sdui:text',
            version: 1,
            props: const {'text': 'Item 1'},
          ),
          SduiLeafNode(
            id: 'c2',
            type: 'sdui:text',
            version: 1,
            props: const {'text': 'Item 2'},
          ),
        ],
      );
      await pumpSduiWidget(tester, node);
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('sdui:row renders children', (tester) async {
      final node = SduiParentNode(
        id: 'row1',
        type: 'sdui:row',
        version: 1,
        children: [
          SduiLeafNode(
            id: 'r1',
            type: 'sdui:text',
            version: 1,
            props: const {'text': 'Left'},
          ),
          SduiLeafNode(
            id: 'r2',
            type: 'sdui:text',
            version: 1,
            props: const {'text': 'Right'},
          ),
        ],
      );
      await pumpSduiWidget(tester, node);
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });
  });

  group('sdui:container', () {
    testWidgets('renders container with child', (tester) async {
      final node = SduiParentNode(
        id: 'cnt1',
        type: 'sdui:container',
        version: 1,
        props: const {'color': '#FF0000'},
        children: [
          SduiLeafNode(
            id: 'inner',
            type: 'sdui:text',
            version: 1,
            props: const {'text': 'Inside'},
          ),
        ],
      );
      await pumpSduiWidget(tester, node);
      expect(find.text('Inside'), findsOneWidget);
    });
  });

  group('sdui:padding', () {
    testWidgets('renders padded child', (tester) async {
      final node = SduiParentNode(
        id: 'pad1',
        type: 'sdui:padding',
        version: 1,
        props: const {'all': 16.0},
        children: [
          SduiLeafNode(
            id: 'padchild',
            type: 'sdui:text',
            version: 1,
            props: const {'text': 'Padded'},
          ),
        ],
      );
      await pumpSduiWidget(tester, node);
      expect(find.text('Padded'), findsOneWidget);
      expect(find.byType(Padding), findsWidgets);
    });
  });

  group('Unknown type', () {
    testWidgets('does not crash in release-like mode', (tester) async {
      final reg = SduiWidgetRegistry()
        ..registerAll(createCoreWidgets())
        ..setFallback((node, ctx) => Text('Unknown: ${node.type}'));

      final node = SduiLeafNode(
        id: 'unk1',
        type: 'myapp:custom_widget',
        version: 1,
        props: const {},
      );
      await pumpSduiWidget(tester, node, registry: reg);
      expect(find.textContaining('myapp:custom_widget'), findsOneWidget);
    });
  });
}
