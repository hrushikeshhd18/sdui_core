import 'package:meta/meta.dart';

import 'package:sdui_core/src/models/sdui_node.dart';

/// The kind of change a [SduiNodeDiff] describes.
enum SduiDiffType {
  /// Node exists in both trees and is identical.
  unchanged,

  /// Node exists in both trees but its [SduiNode.version] increased.
  updated,

  /// Node exists in the new tree but not in the old tree.
  added,

  /// Node existed in the old tree but is absent from the new tree.
  removed,

  /// Node exists in both trees but at a different position among its siblings.
  moved,
}

/// Describes a single node-level change between two trees.
@immutable
final class SduiNodeDiff {
  /// Creates a [SduiNodeDiff].
  const SduiNodeDiff({
    required this.type,
    required this.path,
    this.oldNode,
    this.newNode,
  });

  /// The kind of change.
  final SduiDiffType type;

  /// Dot-separated path in the tree, e.g. `"root/hero/title"`.
  final String path;

  /// The node as it appeared in the old tree (null for [SduiDiffType.added]).
  final SduiNode? oldNode;

  /// The node as it appears in the new tree (null for [SduiDiffType.removed]).
  final SduiNode? newNode;

  @override
  String toString() =>
      'SduiNodeDiff(${type.name}, path: $path, id: ${(newNode ?? oldNode)?.id})';
}

/// The complete diff between two [SduiNode] trees.
@immutable
final class SduiDiffResult {
  /// Creates a [SduiDiffResult].
  const SduiDiffResult({
    required this.hasDiffs,
    required this.diffs,
    required this.updatedTree,
  });

  /// `true` when at least one node changed.
  final bool hasDiffs;

  /// All node-level changes, including [SduiDiffType.unchanged] nodes.
  final List<SduiNodeDiff> diffs;

  /// The authoritative new tree (same as the `newTree` argument to [SduiDiffer.diff]).
  final SduiNode updatedTree;

  /// The number of nodes that actually changed (added, removed, updated, moved).
  int get changedCount =>
      diffs.where((d) => d.type != SduiDiffType.unchanged).length;

  @override
  String toString() =>
      'SduiDiffResult(hasDiffs: $hasDiffs, changed: $changedCount/${diffs.length})';
}

/// Compares two [SduiNode] trees and returns a minimal change set.
///
/// Nodes are matched by [SduiNode.id], not by position — so reordering
/// children is detected as [SduiDiffType.moved] rather than as a sequence
/// of add/remove pairs.
///
/// ```dart
/// final result = SduiDiffer.diff(oldTree, newTree);
/// if (result.hasDiffs) {
///   setState(() => _node = result.updatedTree);
/// }
/// ```
abstract final class SduiDiffer {
  /// Diffs [oldTree] against [newTree] and returns the change set.
  static SduiDiffResult diff(SduiNode oldTree, SduiNode newTree) {
    final diffs = <SduiNodeDiff>[];
    _diffNode(oldTree, newTree, 'root', diffs);
    final hasDiffs = diffs.any((d) => d.type != SduiDiffType.unchanged);
    return SduiDiffResult(
      hasDiffs: hasDiffs,
      diffs: List.unmodifiable(diffs),
      updatedTree: newTree,
    );
  }

  static void _diffNode(
    SduiNode? oldNode,
    SduiNode? newNode,
    String path,
    List<SduiNodeDiff> diffs,
  ) {
    if (oldNode == null && newNode != null) {
      diffs.add(SduiNodeDiff(
        type: SduiDiffType.added,
        path: path,
        newNode: newNode,
      ),);
      // Recursively mark all children as added.
      if (newNode is SduiParentNode) {
        for (final child in newNode.children) {
          _diffNode(null, child, '$path/${child.id}', diffs);
        }
      }
      return;
    }

    if (oldNode != null && newNode == null) {
      diffs.add(SduiNodeDiff(
        type: SduiDiffType.removed,
        path: path,
        oldNode: oldNode,
      ),);
      return;
    }

    if (oldNode == null || newNode == null) return;

    // Version change → updated.
    if (oldNode.version != newNode.version) {
      diffs.add(SduiNodeDiff(
        type: SduiDiffType.updated,
        path: path,
        oldNode: oldNode,
        newNode: newNode,
      ),);
    } else {
      diffs.add(SduiNodeDiff(
        type: SduiDiffType.unchanged,
        path: path,
        oldNode: oldNode,
        newNode: newNode,
      ),);
    }

    // Recurse into children if both nodes are parents.
    if (oldNode is SduiParentNode && newNode is SduiParentNode) {
      _diffChildren(oldNode.children, newNode.children, path, diffs);
    }
  }

  static void _diffChildren(
    List<SduiNode> oldChildren,
    List<SduiNode> newChildren,
    String parentPath,
    List<SduiNodeDiff> diffs,
  ) {
    // Index old children by id for O(n) lookup.
    final oldById = {for (final n in oldChildren) n.id: n};
    final newById = {for (final n in newChildren) n.id: n};

    // Process new children: updated, added, or moved.
    for (var i = 0; i < newChildren.length; i++) {
      final newChild = newChildren[i];
      final oldChild = oldById[newChild.id];
      final childPath = '$parentPath/${newChild.id}';

      if (oldChild == null) {
        // Added.
        _diffNode(null, newChild, childPath, diffs);
      } else {
        // Check for move: same id, different position.
        final oldIndex = oldChildren.indexWhere((n) => n.id == newChild.id);
        if (oldIndex != i) {
          diffs.add(SduiNodeDiff(
            type: SduiDiffType.moved,
            path: childPath,
            oldNode: oldChild,
            newNode: newChild,
          ),);
          // Still recurse to catch nested updates.
          if (oldChild is SduiParentNode && newChild is SduiParentNode) {
            _diffChildren(
                oldChild.children, newChild.children, childPath, diffs,);
          }
        } else {
          _diffNode(oldChild, newChild, childPath, diffs);
        }
      }
    }

    // Find removed nodes (in old but not in new).
    for (final oldChild in oldChildren) {
      if (!newById.containsKey(oldChild.id)) {
        _diffNode(oldChild, null, '$parentPath/${oldChild.id}', diffs);
      }
    }
  }
}
