import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  group('SduiLeafNode', () {
    const node = SduiLeafNode(id: 'n1', type: 'sdui:text', version: 2);

    test('equality is id+type+version only', () {
      const same = SduiLeafNode(id: 'n1', type: 'sdui:text', version: 2);
      const diffVersion = SduiLeafNode(id: 'n1', type: 'sdui:text', version: 3);
      expect(node, equals(same));
      expect(node, isNot(equals(diffVersion)));
    });

    test('hashCode matches equality', () {
      const same = SduiLeafNode(id: 'n1', type: 'sdui:text', version: 2);
      expect(node.hashCode, same.hashCode);
    });

    test('copyWith replaces only specified fields', () {
      final copy = node.copyWith(version: 5, props: {'text': 'Hi'});
      expect(copy.id, 'n1');
      expect(copy.type, 'sdui:text');
      expect(copy.version, 5);
      expect(copy.props['text'], 'Hi');
    });

    test('copyWith with no args returns equivalent node', () {
      final copy = node.copyWith();
      expect(copy, equals(node));
    });

    test('toString contains id and type', () {
      expect(node.toString(), contains('n1'));
      expect(node.toString(), contains('sdui:text'));
    });
  });

  group('SduiParentNode', () {
    const child = SduiLeafNode(id: 'child1', type: 'sdui:text');
    const parent = SduiParentNode(
      id: 'p1',
      type: 'sdui:column',
      version: 1,
      children: [child],
    );

    test('equality checks id+type+version+children.length', () {
      const same = SduiParentNode(
        id: 'p1',
        type: 'sdui:column',
        version: 1,
        children: [child],
      );
      expect(parent, equals(same));
    });

    test('different children count produces inequality', () {
      const noChildren = SduiParentNode(
        id: 'p1',
        type: 'sdui:column',
        version: 1,
      );
      expect(parent, isNot(equals(noChildren)));
    });

    test('hashCode is stable', () {
      const same = SduiParentNode(
        id: 'p1',
        type: 'sdui:column',
        version: 1,
        children: [child],
      );
      expect(parent.hashCode, same.hashCode);
    });

    test('copyWith replaces children', () {
      const newChild = SduiLeafNode(id: 'child2', type: 'sdui:image');
      final copy = parent.copyWith(children: [newChild]);
      expect(copy.children.length, 1);
      expect(copy.children.first.id, 'child2');
    });

    test('copyWith preserves children when null', () {
      final copy = parent.copyWith(version: 99);
      expect(copy.children.length, 1);
      expect(copy.version, 99);
    });

    test('toString contains children count', () {
      expect(parent.toString(), contains('children: 1'));
    });
  });

  group('SduiUnknownNode', () {
    const node = SduiUnknownNode(id: 'u1', type: 'custom:thing');

    test('equality uses id+type', () {
      const same = SduiUnknownNode(id: 'u1', type: 'custom:thing');
      expect(node, equals(same));
    });

    test('different type produces inequality', () {
      const other = SduiUnknownNode(id: 'u1', type: 'custom:other');
      expect(node, isNot(equals(other)));
    });

    test('copyWith updates fields', () {
      final copy = node.copyWith(id: 'u2');
      expect(copy.id, 'u2');
      expect(copy.type, 'custom:thing');
    });
  });

  group('SduiNode sealed exhaustiveness', () {
    test('switch on all subtypes compiles without default', () {
      const SduiNode n = SduiLeafNode(id: 'x', type: 'sdui:text');
      final label = switch (n) {
        SduiLeafNode() => 'leaf',
        SduiParentNode() => 'parent',
        SduiUnknownNode() => 'unknown',
      };
      expect(label, 'leaf');
    });
  });
}
