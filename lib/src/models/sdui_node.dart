import 'package:flutter/cupertino.dart' show SizedBox;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show SizedBox;
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:sdui_core/sdui_core.dart' show SduiProps;

import 'package:sdui_core/src/models/sdui_action.dart';
import 'package:sdui_core/src/models/sdui_props.dart' show SduiProps;

/// The sealed base for every node in an SDUI tree.
///
/// Every node decoded from JSON is one of:
/// - [SduiLeafNode]    – a terminal widget with no children.
/// - [SduiParentNode]  – a layout widget that owns a list of child nodes.
/// - [SduiUnknownNode] – a node whose `type` is not registered; never crashes.
///
/// All subtypes are immutable. Use [SduiNode.copyWith] to produce mutations.
@immutable
sealed class SduiNode with Diagnosticable {
  /// Creates an [SduiNode].
  const SduiNode({
    required this.id,
    required this.type,
    this.version = 0,
    this.props = const {},
    this.actions = const {},
  });

  /// Stable, server-assigned identifier used for keying and diffing.
  ///
  /// Must be unique across the entire tree. The renderer uses this to avoid
  /// unnecessary rebuilds when the tree is refreshed.
  final String id;

  /// Registered widget type string, e.g. `"sdui:text"` or `"myapp:banner"`.
  final String type;

  /// Incremented by the server when this node's content changes.
  ///
  /// The renderer rebuilds only nodes whose version increases — unchanged
  /// nodes are keyed and skipped.
  final int version;

  /// Arbitrary key/value data forwarded to the widget builder.
  ///
  /// Prefer reading props via [SduiProps] in widget builders for type safety.
  final Map<String, Object?> props;

  /// Named gestures mapped to their [SduiAction] descriptors, e.g. `"onTap"`.
  final Map<String, SduiAction> actions;

  /// Returns a copy of this node with the given fields replaced.
  SduiNode copyWith({
    String? id,
    String? type,
    int? version,
    Map<String, Object?>? props,
    Map<String, SduiAction>? actions,
  });

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('id', id))
      ..add(StringProperty('type', type))
      ..add(IntProperty('version', version))
      ..add(IntProperty('props.count', props.length))
      ..add(IntProperty('actions.count', actions.length));
  }

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}

// ---------------------------------------------------------------------------

/// A terminal node that renders a single widget with no children.
@immutable
final class SduiLeafNode extends SduiNode {
  /// Creates a [SduiLeafNode].
  const SduiLeafNode({
    required super.id,
    required super.type,
    super.version,
    super.props,
    super.actions,
  });

  @override
  SduiLeafNode copyWith({
    String? id,
    String? type,
    int? version,
    Map<String, Object?>? props,
    Map<String, SduiAction>? actions,
  }) =>
      SduiLeafNode(
        id: id ?? this.id,
        type: type ?? this.type,
        version: version ?? this.version,
        props: props ?? this.props,
        actions: actions ?? this.actions,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SduiLeafNode &&
          id == other.id &&
          type == other.type &&
          version == other.version;

  @override
  int get hashCode => Object.hash(id, type, version);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'SduiLeafNode(id: $id, type: $type, v$version)';
}

// ---------------------------------------------------------------------------

/// A layout node that owns an ordered list of child [SduiNode]s.
@immutable
final class SduiParentNode extends SduiNode {
  /// Creates a [SduiParentNode].
  const SduiParentNode({
    required super.id,
    required super.type,
    super.version,
    super.props,
    super.actions,
    this.children = const [],
  });

  /// Ordered child nodes. May be empty but never null.
  final List<SduiNode> children;

  @override
  SduiParentNode copyWith({
    String? id,
    String? type,
    int? version,
    Map<String, Object?>? props,
    Map<String, SduiAction>? actions,
    List<SduiNode>? children,
  }) =>
      SduiParentNode(
        id: id ?? this.id,
        type: type ?? this.type,
        version: version ?? this.version,
        props: props ?? this.props,
        actions: actions ?? this.actions,
        children: children ?? this.children,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('children.count', children.length));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SduiParentNode &&
          id == other.id &&
          type == other.type &&
          version == other.version &&
          children.length == other.children.length;

  @override
  int get hashCode => Object.hash(id, type, version, children.length);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'SduiParentNode(id: $id, type: $type, v$version, children: ${children.length})';
}

// ---------------------------------------------------------------------------

/// Placeholder for a node whose `type` has no registered builder.
///
/// In debug builds the renderer shows a visible red error tile.
/// In release builds it returns [SizedBox.shrink] — the app never crashes.
@immutable
final class SduiUnknownNode extends SduiNode {
  /// Creates an [SduiUnknownNode].
  const SduiUnknownNode({
    required super.id,
    required super.type,
  });

  @override
  SduiUnknownNode copyWith({
    String? id,
    String? type,
    int? version,
    Map<String, Object?>? props,
    Map<String, SduiAction>? actions,
  }) =>
      SduiUnknownNode(
        id: id ?? this.id,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SduiUnknownNode && id == other.id && type == other.type;

  @override
  int get hashCode => Object.hash(id, type);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'SduiUnknownNode(id: $id, type: $type)';
}
