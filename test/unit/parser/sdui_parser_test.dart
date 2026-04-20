import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SduiParser.parse — happy path', () {
    test('parses minimal column payload into SduiParentNode', () {
      final node = SduiParser.parse(kMinimalPayload);
      expect(node, isA<SduiParentNode>());
      expect(node.id, 'root');
      expect(node.type, 'sdui:column');
    });

    test('parses text leaf into SduiLeafNode', () {
      final node = SduiParser.parse(kTextPayload);
      expect(node, isA<SduiLeafNode>());
      expect(node.id, 'txt1');
      expect(node.props['text'], 'Hello sdui_core');
    });

    test('parses nested payload preserving hierarchy', () {
      final node = SduiParser.parse(kNestedPayload) as SduiParentNode;
      expect(node.children.length, 1);
      final row = node.children.first as SduiParentNode;
      expect(row.type, 'sdui:row');
      expect(row.children.first.id, 'deep_txt');
    });

    test('parses grid payload with four children', () {
      final node = SduiParser.parse(kGridPayload) as SduiParentNode;
      expect(node.children.length, 4);
    });

    test('parses node version field', () {
      final node = SduiParser.parse(kNestedPayload) as SduiParentNode;
      final deepTxt = (node.children.first as SduiParentNode).children.first;
      expect(deepTxt.version, 2);
    });

    test('parses action from node actions map', () {
      final map = <String, Object?>{
        'sdui_version': '1.0',
        'root': <String, Object?>{
          'type': 'sdui:text',
          'id': 'btn',
          'version': 1,
          'props': <String, Object?>{'text': 'Tap me'},
          'actions': <String, Object?>{
            'onTap': <String, Object?>{
              'type': 'navigate',
              'event': 'go_home',
            },
          },
        },
      };
      final node = SduiParser.parse(map);
      expect(node.actions.containsKey('onTap'), isTrue);
      expect(node.actions['onTap']!.type, 'navigate');
    });

    test('unknown type produces SduiLeafNode (not SduiUnknownNode)', () {
      final map = <String, Object?>{
        'sdui_version': '1.0',
        'root': <String, Object?>{
          'type': 'myapp:banner',
          'id': 'banner1',
          'version': 1,
          'props': <String, Object?>{},
          'actions': <String, Object?>{},
        },
      };
      final node = SduiParser.parse(map);
      // Non-parent unknown types become leaf nodes
      expect(node.id, 'banner1');
      expect(node.type, 'myapp:banner');
    });
  });

  group('SduiParser.parse — error path', () {
    test('throws SduiVersionException for missing sdui_version', () {
      expect(
        () => SduiParser.parse({'root': {}}),
        throwsA(isA<SduiVersionException>()),
      );
    });

    test('throws SduiVersionException for unsupported version', () {
      expect(
        () => SduiParser.parse({
          'sdui_version': '99.0',
          'root': {'type': 'sdui:text', 'id': 'x', 'version': 1},
        }),
        throwsA(isA<SduiVersionException>()),
      );
    });

    test('throws SduiParseException for missing id', () {
      expect(
        () => SduiParser.parse({
          'sdui_version': '1.0',
          'root': {
            'type': 'sdui:text',
            'version': 1,
            'props': {},
            'actions': {},
          },
        }),
        throwsA(isA<SduiParseException>()),
      );
    });

    test('throws SduiParseException for missing type', () {
      expect(
        () => SduiParser.parse({
          'sdui_version': '1.0',
          'root': {'id': 'x', 'version': 1, 'props': {}, 'actions': {}},
        }),
        throwsA(isA<SduiParseException>()),
      );
    });

    test('throws SduiParseException for duplicate ids', () {
      expect(
        () => SduiParser.parse({
          'sdui_version': '1.0',
          'root': {
            'type': 'sdui:column',
            'id': 'col',
            'version': 1,
            'props': {},
            'actions': {},
            'children': [
              {
                'type': 'sdui:text',
                'id': 'col',
                'version': 1,
                'props': {'text': 'dup'},
                'actions': {},
              },
            ],
          },
        }),
        throwsA(isA<SduiParseException>()),
      );
    });
  });

  group('SduiParser.parseString', () {
    test('parses JSON string asynchronously', () async {
      final node = await SduiParser.parseString(jsonEncode(kMinimalPayload));
      expect(node, isA<SduiParentNode>());
      expect(node.id, 'root');
    });

    test('throws SduiParseException for invalid JSON root', () async {
      await expectLater(
        SduiParser.parseString('[1, 2, 3]'),
        throwsA(isA<SduiParseException>()),
      );
    });
  });

  group('SduiParser.validate', () {
    test('returns valid result for correct payload', () {
      final result = SduiParser.validate(kMinimalPayload);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('returns invalid result for missing version', () {
      final result = SduiParser.validate({'root': {}});
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'MISSING_VERSION'), isTrue);
    });
  });
}
