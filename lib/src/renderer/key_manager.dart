import 'package:flutter/widgets.dart';

import 'package:sdui_core/src/models/sdui_node.dart';

/// Generates deterministic [ValueKey]s and compares node versions.
///
/// Keys are always derived from [SduiNode.id] + [SduiNode.version], never
/// from list indices, so Flutter's reconciliation algorithm correctly handles
/// reordering.
abstract final class SduiKeyManager {
  /// Returns a [ValueKey] that uniquely identifies [node] in the widget tree.
  ///
  /// Format: `"sdui_{parentPath}/{id}_v{version}"` (or without the parent
  /// path prefix when [parentPath] is omitted).
  static ValueKey<String> keyFor(
    SduiNode node, {
    String? parentPath,
  }) {
    final raw = parentPath != null
        ? '$parentPath/${node.id}_v${node.version}'
        : '${node.id}_v${node.version}';
    return ValueKey('sdui_$raw');
  }

  /// Returns `true` when [newNode] has a different [SduiNode.version] than
  /// [oldNode], signalling that this subtree must be rebuilt.
  static bool shouldRebuild(SduiNode oldNode, SduiNode newNode) =>
      oldNode.version != newNode.version;
}
