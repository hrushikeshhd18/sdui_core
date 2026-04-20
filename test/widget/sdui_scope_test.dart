import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  group('SduiScope', () {
    testWidgets('provides registry to descendants via of()', (tester) async {
      final reg = SduiWidgetRegistry()..registerAll(createCoreWidgets());
      late SduiWidgetRegistry resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScope(
            registry: reg,
            child: Builder(
              builder: (ctx) {
                resolved = SduiScope.of(ctx).registry;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(resolved, same(reg));
    });

    testWidgets('maybeOf returns null with no ancestor', (tester) async {
      SduiScope? scope;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              scope = SduiScope.maybeOf(ctx);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(scope, isNull);
    });

    testWidgets('of() throws FlutterError with no ancestor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (ctx) {
              expect(
                () => SduiScope.of(ctx),
                throwsA(isA<FlutterError>()),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('defaults registry when none provided', (tester) async {
      late SduiWidgetRegistry resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: SduiScope(
            child: Builder(
              builder: (ctx) {
                resolved = SduiScope.of(ctx).registry;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved.isRegistered('sdui:text'), isTrue);
    });

    testWidgets('provides actionRegistry to descendants', (tester) async {
      final actions = SduiActionRegistry();
      late SduiActionRegistry resolved;

      await tester.pumpWidget(
        MaterialApp(
          home: SduiScope(
            actionRegistry: actions,
            child: Builder(
              builder: (ctx) {
                resolved = SduiScope.of(ctx).actionRegistry;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(resolved, same(actions));
    });
  });
}
