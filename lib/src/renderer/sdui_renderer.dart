import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/renderer/key_manager.dart';
import 'package:sdui_core/src/widgets/sdui_debug_overlay.dart';

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
  static Widget render(SduiNode node, SduiBuildContext ctx) {
    if (!_isVisible(node, ctx)) {
      return SizedBox.shrink(
        key: SduiKeyManager.keyFor(node, parentPath: ctx.nodePath),
      );
    }
    return switch (node) {
      SduiUnknownNode() => _renderUnknown(node, ctx),
      SduiLeafNode() => _renderLeaf(node, ctx),
      SduiParentNode() => _renderParent(node, ctx),
    };
  }

  /// Evaluates the `visible_if` prop.
  ///
  /// Supported forms:
  /// - Absent → always visible.
  /// - `bool` literal → used directly.
  /// - `"props.X"` string → resolves `node.props['X']` and coerces to bool.
  /// - Other `String` → visible unless `""` or `"false"`.
  static bool _isVisible(SduiNode node, SduiBuildContext ctx) {
    final raw = node.props['visible_if'];
    if (raw == null) return true;
    if (raw is bool) return raw;
    if (raw is String) {
      if (raw.startsWith('props.')) {
        final key = raw.substring(6);
        final value = node.props[key];
        if (value == null) return false;
        if (value is bool) return value;
        return value.toString().isNotEmpty && value.toString() != 'false';
      }
      return raw.isNotEmpty && raw != 'false';
    }
    return true;
  }

  static Widget _renderLeaf(SduiLeafNode node, SduiBuildContext ctx) {
    final builder = ctx.registry.resolve(node.type, nodePath: ctx.nodePath);
    final built = KeyedSubtree(
      key: SduiKeyManager.keyFor(node, parentPath: ctx.nodePath),
      child: builder(node, ctx),
    );
    return _wrapDebug(built, node, ctx);
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

    final wrapped = isolate ? RepaintBoundary(child: built) : built;
    return _wrapDebug(wrapped, node, ctx);
  }

  static Widget _renderUnknown(SduiUnknownNode node, SduiBuildContext ctx) {
    if (kDebugMode) {
      return _wrapDebug(_DebugUnknownTile(node: node, path: ctx.nodePath), node, ctx);
    }
    return const SizedBox.shrink();
  }

  static Widget _wrapDebug(Widget child, SduiNode node, SduiBuildContext ctx) {
    if (kReleaseMode || !SduiDebugOverlay.enabled) return child;
    return SduiDebugOverlay(
      node: node,
      nodePath: ctx.nodePath,
      child: child,
    );
  }
}

class _DebugUnknownTile extends StatelessWidget {
  const _DebugUnknownTile({required this.node, required this.path});

  final SduiUnknownNode node;
  final String path;

  @override
  Widget build(BuildContext context) => DecoratedBox(
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
