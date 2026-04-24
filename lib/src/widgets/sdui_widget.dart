import 'package:flutter/widgets.dart';

import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/renderer/sdui_renderer.dart';
import 'package:sdui_core/src/widgets/sdui_scope.dart';

/// Renders a pre-parsed [SduiNode] directly as a Flutter widget.
///
/// Use this to embed an SDUI-rendered section inside a regular screen
/// without making a network request:
/// ```dart
/// final node = SduiParser.parse(myMap);
///
/// @override
/// Widget build(BuildContext context) {
///   return Column(
///     children: [
///       const Text('Regular Flutter widget above'),
///       SduiWidget(node: node),
///       const Text('Regular Flutter widget below'),
///     ],
///   );
/// }
/// ```
class SduiWidget extends StatelessWidget {
  /// Creates an [SduiWidget] from a pre-parsed [node].
  const SduiWidget({super.key, required this.node});

  /// The node tree to render.
  final SduiNode node;

  @override
  Widget build(BuildContext context) {
    final scope = SduiScope.maybeOf(context);
    final registry = scope?.registry ?? SduiWidgetRegistry.defaults;
    final actionRegistry = scope?.actionRegistry ?? SduiActionRegistry.defaults;

    final sdCtx = SduiBuildContext(
      flutterContext: context,
      registry: registry,
      actionRegistry: actionRegistry,
      nodePath: 'root',
      navigatorKey: scope?.navigatorKey,
    );

    return SduiRenderer.render(node, sdCtx);
  }
}
