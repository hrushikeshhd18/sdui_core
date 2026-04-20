import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../helpers/mock_transport.dart';
import '../helpers/test_helpers.dart';

void main() {
  group('End-to-end SDUI pipeline', () {
    testWidgets('parses payload and renders nested tree', (tester) async {
      final transport = MockSduiTransport(kNestedPayload);

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScope(
            registry: SduiWidgetRegistry()..registerAll(createCoreWidgets()),
            child: Scaffold(
              body: SduiScreen(
                url: 'https://test.example.com',
                transport: transport,
                enableCache: false,
                parseInIsolate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Deep'), findsOneWidget);
    });

    testWidgets('action dispatch via onEvent intercept', (tester) async {
      final events = <String>[];
      final payload = <String, Object?>{
        'sdui_version': '1.0',
        'root': <String, Object?>{
          'type': 'sdui:button',
          'id': 'btn1',
          'version': 1,
          'props': <String, Object?>{'label': 'Tap'},
          'actions': <String, Object?>{
            'onTap': <String, Object?>{
              'type': 'dispatch',
              'event': 'my_action',
            },
          },
        },
      };

      final transport = MockSduiTransport(payload);
      final actionRegistry = SduiActionRegistry()
        ..register('my_action', (_, __) async => const SduiActionResult.success());

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScope(
            registry: SduiWidgetRegistry()..registerAll(createCoreWidgets()),
            actionRegistry: actionRegistry,
            child: Scaffold(
              body: SduiScreen(
                url: 'https://test.example.com',
                transport: transport,
                enableCache: false,
                parseInIsolate: false,
                onEvent: (event, _) => events.add(event),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap the button to fire onTap action
      await tester.tap(find.text('Tap'));
      await tester.pump();

      // _fireAction dispatches with action.event ('my_action'), not the gesture key ('onTap')
      expect(events, contains('my_action'));
    });

    testWidgets('SduiWidget renders pre-parsed node directly', (tester) async {
      final node = SduiParser.parse(kTextPayload);

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScope(
            registry: SduiWidgetRegistry()..registerAll(createCoreWidgets()),
            child: Scaffold(body: SduiWidget(node: node)),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Hello sdui_core'), findsOneWidget);
    });

    testWidgets('differ detects update and updatedTree is returned', (tester) async {
      const oldTree = SduiLeafNode(id: 'txt', type: 'sdui:text', version: 1);
      const newTree = SduiLeafNode(id: 'txt', type: 'sdui:text', version: 2);

      final result = SduiDiffer.diff(oldTree, newTree);

      expect(result.hasDiffs, isTrue);
      expect(result.updatedTree, same(newTree));
      expect(result.changedCount, 1);
    });

    testWidgets('grid payload renders four text cells', (tester) async {
      final transport = MockSduiTransport(kGridPayload);

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScope(
            registry: SduiWidgetRegistry()..registerAll(createCoreWidgets()),
            child: Scaffold(
              body: SduiScreen(
                url: 'https://test.example.com',
                transport: transport,
                enableCache: false,
                parseInIsolate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Cell 1'), findsOneWidget);
      expect(find.text('Cell 4'), findsOneWidget);
    });
  });
}
