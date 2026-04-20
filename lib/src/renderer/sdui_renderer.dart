import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/renderer/key_manager.dart';

/// Stateless recursive renderer: [SduiNode] → Flutter [Widget].
///
/// Holds no state — call [render] whenever you have a fresh tree. The renderer
/// uses [SduiKeyManager] for deterministic keying so Flutter's reconciliation
/// can skip unchanged subtrees.
abstract final class SduiRenderer {
  /// Converts [node] into the corresponding Flutter widget subtree.
  ///
  /// [ctx] carries the ambient registries, the current tree path, and any
  /// pre-built child widgets.
  static Widget render(SduiNode node, SduiBuildContext ctx) => switch (node) {
        SduiUnknownNode() => _renderUnknown(node, ctx),
        SduiLeafNode() => _renderLeaf(node, ctx),
        SduiParentNode() => _renderParent(node, ctx),
      };

  static Widget _renderLeaf(SduiLeafNode node, SduiBuildContext ctx) {
    final builder = ctx.registry.resolve(node.type, nodePath: ctx.nodePath);
    return KeyedSubtree(
      key: SduiKeyManager.keyFor(node, parentPath: ctx.nodePath),
      child: builder(node, ctx),
    );
  }

  static Widget _renderParent(SduiParentNode node, SduiBuildContext ctx) {
    final childCtx = ctx.childPath(node.id);
    final childWidgets = [
      for (final child in node.children) render(child, childCtx),
    ];

    // Stash children in context so parent builders can retrieve them via
    // ctx.childWidgets(node) without re-entering the renderer.
    final ctxWithKids = ctx.withChildren(node.id, childWidgets);
    final builder = ctx.registry.resolve(node.type, nodePath: ctx.nodePath);

    final isolate = node.props['isolateRepaint'] as bool? ?? false;
    final built = KeyedSubtree(
      key: SduiKeyManager.keyFor(node, parentPath: ctx.nodePath),
      child: builder(node, ctxWithKids),
    );

    return isolate ? RepaintBoundary(child: built) : built;
  }

  static Widget _renderUnknown(SduiUnknownNode node, SduiBuildContext ctx) {
    if (kDebugMode) {
      return _DebugUnknownTile(node: node, path: ctx.nodePath);
    }
    return const SizedBox.shrink();
  }
}

class _DebugUnknownTile extends StatelessWidget {
  const _DebugUnknownTile({required this.node, required this.path});

  final SduiUnknownNode node;
  final String path;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFFF0000), width: 2),
        color: const Color(0x22FF0000),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'Unknown SDUI widget: "${node.type}"\nPath: $path',
          style: const TextStyle(
            color: Color(0xFFFF0000),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }
}
