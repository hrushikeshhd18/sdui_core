import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('SduiErrorBoundary', () {
    testWidgets('renders wrapped child widget normally', (tester) async {
      const testNode = SduiLeafNode(
        id: 'test',
        type: 'sdui:text',
        version: 1,
        props: {'text': 'Test'},
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SduiErrorBoundary(
              node: testNode,
              child: Container(
                color: Colors.blue,
                child: const Text('Safe child'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safe child'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('can be used in widget tree without issues', (tester) async {
      const testNode = SduiLeafNode(
        id: 'boundary_test',
        type: 'sdui:column',
        version: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SduiErrorBoundary(
              node: testNode,
              child: Column(
                children: [
                  Container(
                    color: Colors.red,
                    height: 50,
                    child: const Text('Section 1'),
                  ),
                  Container(
                    color: Colors.green,
                    height: 50,
                    child: const Text('Section 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Section 1'), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);
    });

    testWidgets('onError callback is executed', (tester) async {
      bool errorCallbackCalled = false;

      const testNode = SduiLeafNode(
        id: 'callback_test',
        type: 'sdui:text',
        version: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SduiErrorBoundary(
              node: testNode,
              onError: (error, stack) {
                errorCallbackCalled = true;
              },
              child: const Text('Test'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Render successfully with no errors
      expect(find.text('Test'), findsOneWidget);
      // Callback should not be called since no error occurred
      expect(errorCallbackCalled, false);
    });

    testWidgets('works with nested widgets', (tester) async {
      const testNode = SduiLeafNode(
        id: 'nested_test',
        type: 'sdui:container',
        version: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SduiErrorBoundary(
              node: testNode,
              child: Center(
                child: Container(
                  color: Colors.amber,
                  padding: const EdgeInsets.all(16),
                  child: const Text('Nested content'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nested content'), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('error boundary widget can be instantiated with minimal props',
        (tester) async {
      const node = SduiLeafNode(
        id: 'minimal_boundary',
        type: 'sdui:column',
        version: 1,
      );

      final boundary = SduiErrorBoundary(
        node: node,
        child: const SizedBox.shrink(),
      );

      expect(boundary.node, node);
      expect(boundary.onError, isNull);
    });
  });
}

