import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  const leaf1 = SduiLeafNode(id: 'a', type: 'sdui:text', version: 1);
  const leaf2 = SduiLeafNode(id: 'b', type: 'sdui:text', version: 1);

  group('SduiDiffer — identical trees', () {
    test('returns hasDiffs false for identical leaf', () {
      final result = SduiDiffer.diff(leaf1, leaf1);
      expect(result.hasDiffs, isFalse);
      expect(result.changedCount, 0);
    });

    test('returns hasDiffs false for identical parent', () {
      const parent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 1,
        children: [leaf1],
      );
      final result = SduiDiffer.diff(parent, parent);
      expect(result.hasDiffs, isFalse);
    });
  });

  group('SduiDiffer — version change', () {
    test('detects updated node when version increments', () {
      const oldNode = SduiLeafNode(id: 'a', type: 'sdui:text', version: 1);
      const newNode = SduiLeafNode(id: 'a', type: 'sdui:text', version: 2);
      final result = SduiDiffer.diff(oldNode, newNode);
      expect(result.hasDiffs, isTrue);
      expect(
        result.diffs
            .any((d) => d.type == SduiDiffType.updated && d.path == 'root'),
        isTrue,
      );
    });

    test('changedCount reflects only changed nodes', () {
      const oldParent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 1,
        children: [leaf1],
      );
      const newParent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 2,
        children: [leaf1],
      );
      final result = SduiDiffer.diff(oldParent, newParent);
      expect(result.changedCount, greaterThanOrEqualTo(1));
    });
  });

  group('SduiDiffer — added and removed children', () {
    test('detects added child', () {
      const oldParent =
          SduiParentNode(id: 'col', type: 'sdui:column', version: 1);
      const newParent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 1,
        children: [leaf1],
      );
      final result = SduiDiffer.diff(oldParent, newParent);
      expect(result.hasDiffs, isTrue);
      expect(
        result.diffs
            .any((d) => d.type == SduiDiffType.added && d.newNode?.id == 'a'),
        isTrue,
      );
    });

    test('detects removed child', () {
      const oldParent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 1,
        children: [leaf1],
      );
      const newParent =
          SduiParentNode(id: 'col', type: 'sdui:column', version: 1);
      final result = SduiDiffer.diff(oldParent, newParent);
      expect(result.hasDiffs, isTrue);
      expect(
        result.diffs.any(
          (d) => d.type == SduiDiffType.removed && d.oldNode?.id == 'a',
        ),
        isTrue,
      );
    });

    test('detects added and removed in same diff', () {
      const oldParent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 1,
        children: [leaf1],
      );
      const newParent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 1,
        children: [leaf2],
      );
      final result = SduiDiffer.diff(oldParent, newParent);
      expect(result.diffs.any((d) => d.type == SduiDiffType.added), isTrue);
      expect(result.diffs.any((d) => d.type == SduiDiffType.removed), isTrue);
    });
  });

  group('SduiDiffer — move detection', () {
    test('detects reordered children as moved', () {
      const oldParent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 1,
        children: [leaf1, leaf2],
      );
      const newParent = SduiParentNode(
        id: 'col',
        type: 'sdui:column',
        version: 1,
        children: [leaf2, leaf1],
      );
      final result = SduiDiffer.diff(oldParent, newParent);
      expect(result.hasDiffs, isTrue);
      expect(result.diffs.any((d) => d.type == SduiDiffType.moved), isTrue);
    });
  });

  group('SduiDiffer — updatedTree', () {
    test('updatedTree is the newTree argument', () {
      const newNode = SduiLeafNode(id: 'a', type: 'sdui:text', version: 2);
      final result = SduiDiffer.diff(leaf1, newNode);
      expect(result.updatedTree, same(newNode));
    });
  });

  group('SduiDiffResult', () {
    test('toString contains hasDiffs and counts', () {
      final result = SduiDiffer.diff(leaf1, leaf1);
      expect(result.toString(), contains('hasDiffs'));
    });

    test('SduiNodeDiff toString contains type and id', () {
      const diff = SduiNodeDiff(
        type: SduiDiffType.updated,
        path: 'root',
        newNode: SduiLeafNode(id: 'n1', type: 'sdui:text'),
      );
      expect(diff.toString(), contains('updated'));
      expect(diff.toString(), contains('n1'));
    });
  });
}
