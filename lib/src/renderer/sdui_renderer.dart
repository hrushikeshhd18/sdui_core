import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/renderer/key_manager.dart';
import 'package:sdui_core/src/widgets/sdui_bindings.dart';
import 'package:sdui_core/src/widgets/sdui_debug_overlay.dart';

/// Stateless recursive renderer: [SduiNode] → Flutter [Widget].
///
/// Holds no state — call [render] whenever you have a fresh tree. The renderer
/// uses [SduiKeyManager] for deterministic keying so Flutter's reconciliation
/// can skip unchanged subtrees.
///
/// Every node is wrapped in a try-catch. If a builder throws (e.g. a missing
/// required prop or an unregistered type), the renderer returns an inline error
/// tile in debug mode and a [SizedBox.shrink] in release mode — so one bad node
/// can never crash the whole screen.
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
  /// - `"binding.X"` string → resolves value from [SduiBindings] in the tree.
  ///   The node is hidden when the key is absent or resolves to `false`/`""`.
  /// - Other non-empty `String` → visible (treats non-empty string as truthy).
  ///
  /// Example JSON:
  /// ```json
  /// { "visible_if": "binding.feature.newCheckout" }
  /// { "visible_if": "binding.user.isPremium" }
  /// { "visible_if": "props.inStock" }
  /// ```
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
      if (raw.startsWith('binding.')) {
        final key = raw.substring(8);
        final value = SduiBindings.maybeOf(ctx.flutterContext)?.resolve(key);
        if (value == null) return false;
        if (value is bool) return value;
        return value.toString().isNotEmpty && value.toString() != 'false';
      }
      return raw.isNotEmpty && raw != 'false';
    }
    return true;
  }

  static Widget _renderLeaf(SduiLeafNode node, SduiBuildContext ctx) {
    Widget child;
    try {
      final builder = ctx.registry.resolve(node.type, nodePath: ctx.nodePath);
      child = builder(node, ctx);
    } catch (e, stack) {
      child = _RendererErrorTile(node: node, error: e, path: ctx.nodePath);
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: stack,
            context: ErrorDescription(
              'rendering SDUI node "${node.type}" at path "${ctx.nodePath}"',
            ),
          ),
        );
      }
    }
    final keyed = KeyedSubtree(
      key: SduiKeyManager.keyFor(node, parentPath: ctx.nodePath),
      child: child,
    );
    return _wrapDebug(keyed, node, ctx);
  }

  static Widget _renderParent(SduiParentNode node, SduiBuildContext ctx) {
    final childCtx = ctx.childPath(node.id);
    final childWidgets = [
      for (final child in node.children) render(child, childCtx),
    ];

    // Stash children in context so parent builders can retrieve them via
    // ctx.childWidgets(node) without re-entering the renderer.
    final ctxWithKids = ctx.withChildren(node.id, childWidgets);

    Widget child;
    try {
      final builder = ctx.registry.resolve(node.type, nodePath: ctx.nodePath);
      final isolate = node.props['isolateRepaint'] as bool? ?? false;
      child = builder(node, ctxWithKids);
      if (isolate) child = RepaintBoundary(child: child);
    } catch (e, stack) {
      child = _RendererErrorTile(node: node, error: e, path: ctx.nodePath);
      if (kDebugMode) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: e,
            stack: stack,
            context: ErrorDescription(
              'rendering SDUI node "${node.type}" at path "${ctx.nodePath}"',
            ),
          ),
        );
      }
    }

    final keyed = KeyedSubtree(
      key: SduiKeyManager.keyFor(node, parentPath: ctx.nodePath),
      child: child,
    );
    return _wrapDebug(keyed, node, ctx);
  }

  static Widget _renderUnknown(SduiUnknownNode node, SduiBuildContext ctx) {
    if (kDebugMode) {
      return _wrapDebug(
        _DebugUnknownTile(node: node, path: ctx.nodePath),
        node,
        ctx,
      );
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

/// Shown in place of a node whose builder threw at render time.
///
/// Visible in debug builds only. Release builds return [SizedBox.shrink]
/// so the rest of the screen keeps rendering.
class _RendererErrorTile extends StatelessWidget {
  const _RendererErrorTile({
    required this.node,
    required this.error,
    required this.path,
  });

  final SduiNode node;
  final Object error;
  final String path;

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDD2222), width: 2),
        color: const Color(0x18FF0000),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          'SDUI render error — ${node.type}\n'
          'Path: $path\n'
          '$error',
          style: const TextStyle(
            color: Color(0xFFCC0000),
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ),
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
