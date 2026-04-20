import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Map<String, Object?> _wrap(Map<String, Object?> node) => {
      'sdui_version': '1.0',
      'root': node,
    };

Map<String, Object?> _leaf({
  String type = 'sdui:text',
  String id = 'n1',
  int version = 1,
  Map<String, Object?>? props,
}) =>
    {
      'type': type,
      'id': id,
      'version': version,
      'props': props ?? {},
      'actions': {},
    };

void main() {
  group('SduiParser.parse', () {
    test('parses valid JSON into a SduiLeafNode', () {
      final node = SduiParser.parse(_wrap(_leaf()));
      expect(node, isA<SduiLeafNode>());
      expect(node.id, 'n1');
      expect(node.type, 'sdui:text');
      expect(node.version, 1);
    });

    test('throws SduiVersionException when sdui_version is missing', () {
      final json = <String, Object?>{
        'type': 'sdui:text',
        'id': 'n1',
        'version': 1,
        'props': {},
        'actions': {},
      };
      expect(
        () => SduiParser.parse(json),
        throwsA(isA<SduiVersionException>()),
      );
    });

    test('throws SduiVersionException for unsupported sdui_version', () {
      final badJson = <String, Object?>{
        'sdui_version': '99.0',
        'root': _leaf(),
      };
      expect(
        () => SduiParser.parse(badJson),
        throwsA(isA<SduiVersionException>()),
      );
    });

    test('throws SduiParseException when id is missing', () {
      final badNode = <String, Object?>{
        'type': 'sdui:text',
        'version': 1,
        'props': {},
        'actions': {},
      };
      expect(
        () => SduiParser.parse({'sdui_version': '1.0', 'root': badNode}),
        throwsA(isA<SduiParseException>()),
      );
    });

    test('throws SduiParseException when type is missing', () {
      final badNode = <String, Object?>{
        'id': 'n1',
        'version': 1,
        'props': {},
        'actions': {},
      };
      expect(
        () => SduiParser.parse({'sdui_version': '1.0', 'root': badNode}),
        throwsA(isA<SduiParseException>()),
      );
    });

    test('produces leaf node for unregistered non-parent type', () {
      final json = <String, Object?>{
        'sdui_version': '1.0',
        'root': <String, Object?>{
          'type': 'myapp:does_not_exist',
          'id': 'unknown_1',
          'version': 1,
          'props': {},
          'actions': {},
        },
      };
      final node = SduiParser.parse(json);
      expect(node.type, 'myapp:does_not_exist');
    });

    test('defaults missing version to 0', () {
      final noVersion = <String, Object?>{
        'sdui_version': '1.0',
        'root': <String, Object?>{
          'type': 'sdui:text',
          'id': 'nv',
          'props': {},
          'actions': {},
        },
      };
      final node = SduiParser.parse(noVersion);
      expect(node.version, 0);
    });

    test('defaults missing props to empty map', () {
      final json = <String, Object?>{
        'sdui_version': '1.0',
        'root': <String, Object?>{'type': 'sdui:text', 'id': 'np', 'version': 1, 'actions': {}},
      };
      final node = SduiParser.parse(json);
      expect(node.props, isEmpty);
    });

    test('defaults missing actions to empty map', () {
      final json = <String, Object?>{
        'sdui_version': '1.0',
        'root': <String, Object?>{'type': 'sdui:text', 'id': 'na', 'version': 1, 'props': {}},
      };
      final node = SduiParser.parse(json);
      expect(node.actions, isEmpty);
    });

    test('parses deeply nested children', () {
      final json = <String, Object?>{
        'sdui_version': '1.0',
        'root': <String, Object?>{
          'type': 'sdui:column',
          'id': 'root',
          'version': 1,
          'props': {},
          'actions': {},
          'children': <Object?>[
            <String, Object?>{
              'type': 'sdui:row',
              'id': 'row1',
              'version': 1,
              'props': {},
              'actions': {},
              'children': <Object?>[
                <String, Object?>{
                  'type': 'sdui:text',
                  'id': 'leaf1',
                  'version': 1,
                  'props': {'text': 'deep'},
                  'actions': {},
                },
              ],
            },
          ],
        },
      };
      final node = SduiParser.parse(json) as SduiParentNode;
      expect(node.children, hasLength(1));
      final row = node.children.first as SduiParentNode;
      expect(row.type, 'sdui:row');
      expect(row.children.first.id, 'leaf1');
    });

    test('parseString returns the same result as parse', () async {
      final map = _wrap(_leaf());
      final jsonStr = jsonEncode(map);
      final sync = SduiParser.parse(map);
      final async = await SduiParser.parseString(jsonStr);
      expect(async.id, sync.id);
      expect(async.type, sync.type);
      expect(async.version, sync.version);
    });
  });
}
