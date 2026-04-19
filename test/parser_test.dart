import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

Map<String, dynamic> _wrap(Map<String, dynamic> node) => {
      'sdui_version': '1.0',
      'root': node,
    };

Map<String, dynamic> _leaf({
  String type = 'sdui:text',
  String id = 'n1',
  int version = 1,
  Map<String, dynamic>? props,
}) =>
    {
      'type': type,
      'id': id,
      'version': version,
      'props': props ?? {},
      'actions': {},
    };

void main() {
  setUpAll(() {
    SduiWidgetRegistry.instance.register(
      'sdui:text',
      (_, __) => throw UnimplementedError('test stub'),
    );
  });

  group('SduiParser.parse', () {
    test('parses valid JSON into a SduiLeafNode', () {
      final node = SduiParser.parse(_wrap(_leaf()));
      expect(node, isA<SduiLeafNode>());
      expect(node.id, 'n1');
      expect(node.type, 'sdui:text');
      expect(node.version, 1);
    });

    test('throws SduiVersionException when sdui_version is missing', () {
      final json = {
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
      final badJson = {
        'sdui_version': '99.0',
        'root': _leaf(),
      };
      expect(
        () => SduiParser.parse(badJson),
        throwsA(isA<SduiVersionException>()),
      );
    });

    test('throws SduiParseException when id is missing', () {
      final badNode = {
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
      final badNode = {
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

    test('produces SduiUnknownNode for unregistered type — no throw', () {
      final json = {
        'sdui_version': '1.0',
        'root': {
          'type': 'myapp:does_not_exist',
          'id': 'unknown_1',
          'version': 1,
          'props': {},
          'actions': {},
        },
      };
      final node = SduiParser.parse(json);
      expect(node, isA<SduiUnknownNode>());
      expect(node.type, 'myapp:does_not_exist');
    });

    test('defaults missing version to 0', () {
      final noVersion = {
        'sdui_version': '1.0',
        'root': {
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
      final json = {
        'sdui_version': '1.0',
        'root': {'type': 'sdui:text', 'id': 'np', 'version': 1, 'actions': {}},
      };
      final node = SduiParser.parse(json);
      expect(node.props, isEmpty);
    });

    test('defaults missing actions to empty map', () {
      final json = {
        'sdui_version': '1.0',
        'root': {'type': 'sdui:text', 'id': 'na', 'version': 1, 'props': {}},
      };
      final node = SduiParser.parse(json);
      expect(node.actions, isEmpty);
    });

    test('parses deeply nested children', () {
      final json = {
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:column',
          'id': 'root',
          'version': 1,
          'props': {},
          'actions': {},
          'children': [
            {
              'type': 'sdui:row',
              'id': 'row1',
              'version': 1,
              'props': {},
              'actions': {},
              'children': [
                {
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

    test('parseAsync returns the same result as parse', () async {
      final map = _wrap(_leaf());
      final jsonStr = jsonEncode(map);
      final sync = SduiParser.parse(map);
      final async = await SduiParser.parseAsync(jsonStr);
      expect(async.id, sync.id);
      expect(async.type, sync.type);
      expect(async.version, sync.version);
    });
  });
}
