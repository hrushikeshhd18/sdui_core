import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../models/sdui_node.dart';
import '../registry/widget_registry.dart';
import 'key_manager.dart';

/// Stateless recursive renderer that converts an [SduiNode] tree into widgets.
///
/// This class holds no state — call [render] whenever you have a fresh tree.
abstract final class SduiRenderer {
  /// Converts [node] into the corresponding Flutter widget subtree.
  ///
  /// The [ctx] carries the ambient registries and current tree path.
  static Widget render(SduiNode node, SduiBuildContext ctx) {
    return switch (node) {
      SduiUnknownNode() => _renderUnknown(node, ctx),
      SduiLeafNode() => _renderLeaf(node, ctx),
      SduiParentNode() => _renderParent(node, ctx),
    };
  }

  // ---------------------------------------------------------------------------

  static Widget _renderLeaf(SduiLeafNode node, SduiBuildContext ctx) {
    final builder = ctx.registry.resolve(node.type, ctx.nodePath);
    return KeyedSubtree(
      key: SduiKeyManager.keyFor(node, parentPath: ctx.nodePath),
      child: builder(node, ctx),
    );
  }

  static Widget _renderParent(SduiParentNode node, SduiBuildContext ctx) {
    // Build children first with an updated path for diagnostics.
    final childCtx = ctx.childPath(node.id);
    final childWidgets = [
      for (final child in node.children) render(child, childCtx),
    ];

    // Stash the pre-built children in the context so the builder can retrieve
    // them via ctx.childWidgets(node) without re-entering the renderer.
    final ctxWithKids = ctx.withChildren(node.id, childWidgets);

    final builder = ctx.registry.resolve(node.type, ctx.nodePath);

    // Allow the server to opt specific subtrees into isolated repaint.
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

/// Debug-only tile shown when a node type is not registered.
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
