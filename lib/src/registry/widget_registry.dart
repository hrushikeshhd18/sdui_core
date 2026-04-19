import 'package:flutter/widgets.dart';

import '../exceptions/sdui_exceptions.dart';
import '../models/sdui_node.dart';
import 'action_registry.dart';

/// Context object passed to every [SduiWidgetBuilder].
///
/// Provides access to both registries, the current node's path in the tree,
/// and (for parent nodes) the pre-built child widgets so builders never need
/// to re-enter the renderer manually.
class SduiBuildContext {
  /// The ambient Flutter [BuildContext].
  final BuildContext flutterContext;

  /// The widget registry in scope.
  final SduiWidgetRegistry registry;

  /// The action registry in scope.
  final SduiActionRegistry actionRegistry;

  /// Dot-separated path of the current node, e.g. `"root/hero/title"`.
  final String nodePath;

  // Pre-built children stored by node id — populated by SduiRenderer before
  // invoking a parent builder so builders can call childWidgets(node).
  final Map<String, List<Widget>> _prebuiltChildren;

  /// Creates a [SduiBuildContext].
  const SduiBuildContext({
    required this.flutterContext,
    required this.registry,
    required this.actionRegistry,
    required this.nodePath,
    Map<String, List<Widget>> prebuiltChildren = const {},
  }) : _prebuiltChildren = prebuiltChildren;

  /// Returns the pre-built child widgets for [node], or an empty list.
  ///
  /// Call this inside a parent widget builder instead of rendering children
  /// manually:
  /// ```dart
  /// final kids = ctx.childWidgets(node);
  /// return Column(children: kids);
  /// ```
  List<Widget> childWidgets(SduiNode node) =>
      _prebuiltChildren[node.id] ?? const [];

  /// Returns a child context with the given [segment] appended to [nodePath].
  SduiBuildContext childPath(String segment) => SduiBuildContext(
        flutterContext: flutterContext,
        registry: registry,
        actionRegistry: actionRegistry,
        nodePath: '$nodePath/$segment',
        prebuiltChildren: _prebuiltChildren,
      );

  /// Returns a context carrying [children] keyed under [nodeId].
  SduiBuildContext withChildren(String nodeId, List<Widget> children) {
    return SduiBuildContext(
      flutterContext: flutterContext,
      registry: registry,
      actionRegistry: actionRegistry,
      nodePath: nodePath,
      prebuiltChildren: {..._prebuiltChildren, nodeId: children},
    );
  }
}

/// A function that converts an [SduiNode] into a Flutter [Widget].
typedef SduiWidgetBuilder = Widget Function(
  SduiNode node,
  SduiBuildContext context,
);

/// Singleton registry that maps widget type strings to [SduiWidgetBuilder]s.
///
/// Register built-in widgets once at startup:
/// ```dart
/// SduiWidgetRegistry.instance.registerAll(createCoreWidgets());
/// ```
/// Then register custom widgets as needed:
/// ```dart
/// SduiWidgetRegistry.instance.register('myapp:banner', myBannerBuilder);
/// ```
class SduiWidgetRegistry {
  SduiWidgetRegistry._();

  /// The global singleton instance.
  static final SduiWidgetRegistry instance = SduiWidgetRegistry._();

  final Map<String, SduiWidgetBuilder> _builders = {};
  SduiWidgetBuilder? _fallback;

  /// Registers [builder] for [type].
  ///
  /// Overwrites any previously registered builder for the same type.
  void register(String type, SduiWidgetBuilder builder) {
    _builders[type] = builder;
  }

  /// Registers every entry in [builders].
  void registerAll(Map<String, SduiWidgetBuilder> builders) {
    _builders.addAll(builders);
  }

  /// Sets a [builder] to use when [resolve] is called for an unknown type.
  void setFallback(SduiWidgetBuilder builder) {
    _fallback = builder;
  }

  /// Returns the builder registered for [type].
  ///
  /// Falls back to the fallback builder if set, otherwise throws
  /// [SduiUnknownWidgetException].
  SduiWidgetBuilder resolve(String type, String nodePath) {
    final builder = _builders[type] ?? _fallback;
    if (builder == null) {
      throw SduiUnknownWidgetException(type: type, path: nodePath);
    }
    return builder;
  }

  /// Returns `true` if [type] has a registered builder.
  bool isRegistered(String type) => _builders.containsKey(type);

  /// Removes the builder for [type] if present.
  void unregister(String type) => _builders.remove(type);

  /// Removes all registered builders and the fallback.
  ///
  /// Intended for use in tests only.
  void clear() {
    _builders.clear();
    _fallback = null;
  }

  /// All currently registered type strings.
  List<String> get registeredTypes => List.unmodifiable(_builders.keys);
}
