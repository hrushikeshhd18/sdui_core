import 'sdui_action.dart';

/// The sealed base for every node in an SDUI tree.
///
/// Every node decoded from JSON is one of:
/// - [SduiLeafNode]   – a terminal widget with no children.
/// - [SduiParentNode] – a layout widget that owns a list of child nodes.
/// - [SduiUnknownNode] – a node whose `type` is not registered; never crashes.
sealed class SduiNode {
  /// Stable, server-assigned identifier used for keying and diffing.
  final String id;

  /// Registered widget type string, e.g. `"sdui:text"` or `"myapp:banner"`.
  final String type;

  /// Incremented by the server when this node's content changes.
  /// The renderer rebuilds only nodes whose version increases.
  final int version;

  /// Arbitrary key/value data forwarded to the widget builder.
  final Map<String, dynamic> props;

  /// Named gestures mapped to their [SduiAction] descriptors.
  final Map<String, SduiAction> actions;

  /// Creates a [SduiNode].
  const SduiNode({
    required this.id,
    required this.type,
    required this.version,
    required this.props,
    required this.actions,
  });
}

/// A terminal node that renders a single widget with no children.
final class SduiLeafNode extends SduiNode {
  /// Creates a [SduiLeafNode].
  const SduiLeafNode({
    required super.id,
    required super.type,
    required super.version,
    required super.props,
    required super.actions,
  });

  @override
  String toString() =>
      'SduiLeafNode(id: $id, type: $type, version: $version)';
}

/// A layout node that owns an ordered list of child [SduiNode]s.
final class SduiParentNode extends SduiNode {
  /// Ordered child nodes. May be empty but never null.
  final List<SduiNode> children;

  /// Creates a [SduiParentNode].
  const SduiParentNode({
    required super.id,
    required super.type,
    required super.version,
    required super.props,
    required super.actions,
    required this.children,
  });

  @override
  String toString() =>
      'SduiParentNode(id: $id, type: $type, children: ${children.length})';
}

/// Placeholder for a node whose `type` is not registered.
///
/// In debug mode the renderer shows a visible error tile.
/// In release mode it returns [SizedBox.shrink] — the app never crashes.
final class SduiUnknownNode extends SduiNode {
  /// Creates an [SduiUnknownNode].
  const SduiUnknownNode({
    required super.id,
    required super.type,
    required super.version,
    required super.props,
    required super.actions,
  });

  @override
  String toString() => 'SduiUnknownNode(id: $id, type: $type)';
}
