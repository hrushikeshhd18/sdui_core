import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  group('SduiKeyManager.keyFor', () {
    test('returns ValueKey for leaf node without path', () {
      const node = SduiLeafNode(id: 'txt1', type: 'sdui:text', version: 3);
      final key = SduiKeyManager.keyFor(node);
      expect(key, isA<ValueKey<String>>());
      final v = (key).value;
      expect(v, contains('txt1'));
      expect(v, contains('v3'));
    });

    test('key encodes parent path and node id+version', () {
      const node = SduiLeafNode(id: 'btn', type: 'sdui:button', version: 2);
      final key = SduiKeyManager.keyFor(node, parentPath: 'root/header');
      expect(key.value, contains('btn'));
      expect(key.value, contains('v2'));
      expect(key.value, contains('root/header'));
    });

    test('same node at same path produces equal keys', () {
      const node = SduiLeafNode(id: 'x', type: 'sdui:text', version: 1);
      final k1 = SduiKeyManager.keyFor(node, parentPath: 'root');
      final k2 = SduiKeyManager.keyFor(node, parentPath: 'root');
      expect(k1, equals(k2));
    });

    test('same node at different paths produces different keys', () {
      const node = SduiLeafNode(id: 'x', type: 'sdui:text', version: 1);
      final k1 = SduiKeyManager.keyFor(node, parentPath: 'root/a');
      final k2 = SduiKeyManager.keyFor(node, parentPath: 'root/b');
      expect(k1, isNot(equals(k2)));
    });

    test('version change produces different key', () {
      const v1 = SduiLeafNode(id: 'x', type: 'sdui:text', version: 1);
      const v2 = SduiLeafNode(id: 'x', type: 'sdui:text', version: 2);
      final k1 = SduiKeyManager.keyFor(v1, parentPath: 'root');
      final k2 = SduiKeyManager.keyFor(v2, parentPath: 'root');
      expect(k1, isNot(equals(k2)));
    });
  });

  group('SduiKeyManager.shouldRebuild', () {
    test('returns false when versions match', () {
      const n = SduiLeafNode(id: 'a', type: 'sdui:text', version: 1);
      expect(SduiKeyManager.shouldRebuild(n, n), isFalse);
    });

    test('returns true when versions differ', () {
      const old = SduiLeafNode(id: 'a', type: 'sdui:text', version: 1);
      const neo = SduiLeafNode(id: 'a', type: 'sdui:text', version: 2);
      expect(SduiKeyManager.shouldRebuild(old, neo), isTrue);
    });
  });
}
