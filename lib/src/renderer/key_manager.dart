import 'package:flutter/widgets.dart';

import '../models/sdui_node.dart';

/// Generates deterministic [ValueKey]s for [SduiNode]s and compares versions.
///
/// Keys are always based on the node's [SduiNode.id] and [SduiNode.version],
/// never on list indices, so Flutter's reconciliation algorithm correctly
/// identifies nodes when the order changes.
abstract final class SduiKeyManager {
  /// Returns a [ValueKey] that uniquely identifies [node] in the widget tree.
  ///
  /// Format: `"sdui_{id}_v{version}"` — or, if [parentPath] is supplied,
  /// `"sdui_{parentPath}/{id}_v{version}"`.
  static ValueKey<String> keyFor(
    SduiNode node, {
    String? parentPath,
  }) {
    final raw = parentPath != null
        ? '$parentPath/${node.id}_v${node.version}'
        : '${node.id}_v${node.version}';
    return ValueKey('sdui_$raw');
  }

  /// Returns `true` when [newNode] has a higher [SduiNode.version] than
  /// [oldNode], signalling that this subtree must be rebuilt.
  static bool shouldRebuild(SduiNode oldNode, SduiNode newNode) {
    return oldNode.version != newNode.version;
  }
}
