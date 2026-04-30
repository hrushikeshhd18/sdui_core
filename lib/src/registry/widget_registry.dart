import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart' show SduiScope;

import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/widgets/sdui_scope.dart' show SduiScope;

/// Context object passed to every [SduiWidgetBuilder].
///
/// Carries both registries, the current tree path for diagnostics, the
/// pre-built child widgets, and an optional [navigatorKey] for safe navigation
/// across async action handlers.
class SduiBuildContext {
  /// Creates a [SduiBuildContext].
  const SduiBuildContext({
    required this.flutterContext,
    required this.registry,
    required this.actionRegistry,
    required this.nodePath,
    this.navigatorKey,
    Map<String, List<Widget>> prebuiltChildren = const {},
  }) : _prebuiltChildren = prebuiltChildren;

  /// The ambient Flutter [BuildContext].
  final BuildContext flutterContext;

  /// The widget registry in scope.
  final SduiWidgetRegistry registry;

  /// The action registry in scope.
  final SduiActionRegistry actionRegistry;

  /// Dot-separated path of the current node, e.g. `"root/hero/title"`.
  final String nodePath;

  /// Optional navigator key propagated from [SduiScope.navigatorKey].
  ///
  /// Widget builders pass this into [SduiActionContext] so navigation stays
  /// safe even when the originating [BuildContext] has been unmounted.
  final GlobalKey<NavigatorState>? navigatorKey;

  final Map<String, List<Widget>> _prebuiltChildren;

  /// Returns the pre-built child [Widget]s for [node].
  ///
  /// Parent widget builders must call this instead of rendering children
  /// manually to preserve the keying and diffing guarantees.
  ///
  /// ```dart
  /// Widget myBuilder(SduiNode node, SduiBuildContext ctx) {
  ///   return Column(children: ctx.childWidgets(node));
  /// }
  /// ```
  List<Widget> childWidgets(SduiNode node) =>
      _prebuiltChildren[node.id] ?? const [];

  /// Returns a child context with [segment] appended to [nodePath].
  SduiBuildContext childPath(String segment) => SduiBuildContext(
        flutterContext: flutterContext,
        registry: registry,
        actionRegistry: actionRegistry,
        nodePath: '$nodePath/$segment',
        navigatorKey: navigatorKey,
        prebuiltChildren: _prebuiltChildren,
      );

  /// Returns a copy of this context with [children] stored under [nodeId].
  SduiBuildContext withChildren(String nodeId, List<Widget> children) =>
      SduiBuildContext(
        flutterContext: flutterContext,
        registry: registry,
        actionRegistry: actionRegistry,
        nodePath: nodePath,
        navigatorKey: navigatorKey,
        prebuiltChildren: {..._prebuiltChildren, nodeId: children},
      );
}

/// A function that converts an [SduiNode] into a Flutter [Widget].
typedef SduiWidgetBuilder = Widget Function(
  SduiNode node,
  SduiBuildContext ctx,
);

/// Registry that maps widget type strings to [SduiWidgetBuilder] functions.
///
/// Unlike a singleton, each [SduiWidgetRegistry] instance is fully isolated,
/// making it safe to create per-test registries:
///
/// ```dart
/// // Production — use the pre-loaded defaults:
/// SduiScope(registry: SduiWidgetRegistry.withDefaults(), child: ...)
///
/// // Testing — create a fresh instance:
/// final reg = SduiWidgetRegistry()..register('sdui:text', myStub);
/// ```
final class SduiWidgetRegistry {
  /// Creates an empty registry.
  SduiWidgetRegistry();

  /// Creates a registry pre-loaded with all built-in `sdui:` widgets.
  ///
  /// This is the registry [SduiScope] uses when none is provided.
  factory SduiWidgetRegistry.withDefaults() =>
      SduiWidgetRegistry().._loadDefaults();

  /// The shared default registry pre-loaded with all built-in widgets.
  ///
  /// Populated lazily on first access. [SduiScope] wires the factory via
  /// [configureDefaultFactory] before the first render, so this is always
  /// non-empty in normal app usage.
  static SduiWidgetRegistry get defaults =>
      _defaults ??= SduiWidgetRegistry.withDefaults();

  // Backing store for [defaults]; reset by [configureDefaultFactory].
  static SduiWidgetRegistry? _defaults;

  // Factory set by [configureDefaultFactory]. Starts as a no-op so early
  // accesses to [defaults] return an empty (safe) registry rather than crashing.
  static Map<String, SduiWidgetBuilder> Function() _defaultsFactory =
      () => const {};

  /// Wires the builder factory used by `withDefaults` and [defaults].
  ///
  /// Called once by [SduiScope] at app start to register core + Material
  /// widgets. Invalidates the cached [defaults] so the next access rebuilds
  /// with the new factory.
  ///
  /// You should not call this directly — pass a custom registry to [SduiScope]
  /// instead.
  static void configureDefaultFactory(
    Map<String, SduiWidgetBuilder> Function() factory,
  ) {
    _defaultsFactory = factory;
    // If defaults has already been accessed (e.g. app registered custom widgets
    // on it before SduiScope was built), merge the factory builders in rather
    // than discarding the instance — preserves those custom registrations.
    // If defaults hasn't been accessed yet, the factory is picked up on first access.
    _defaults?.registerAll(factory());
  }

  final Map<String, SduiWidgetBuilder> _builders = {};
  final Map<String, SduiWidgetBuilder> _wildcards = {};
  SduiWidgetBuilder? _fallback;

  void _loadDefaults() => registerAll(_defaultsFactory());

  /// Registers [builder] for the exact [type] string.
  ///
  /// Overwrites any previously registered builder for the same type.
  void register(String type, SduiWidgetBuilder builder) {
    _builders[type] = builder;
  }

  /// Registers every entry in [builders].
  void registerAll(Map<String, SduiWidgetBuilder> builders) {
    _builders.addAll(builders);
  }

  /// Registers [builder] as the handler for any type in [namespace].
  ///
  /// For example, `registerNamespaceWildcard('myapp', myBuilder)` handles
  /// `myapp:anything` that has no explicit registration.
  void registerNamespaceWildcard(String namespace, SduiWidgetBuilder builder) {
    _wildcards[namespace] = builder;
  }

  /// Sets a catch-all [builder] used when no registered type or wildcard matches.
  void setFallback(SduiWidgetBuilder builder) {
    _fallback = builder;
  }

  /// Resolves the builder for [type], trying in order:
  /// 1. Exact match.
  /// 2. Namespace wildcard (e.g. `"myapp:*"`).
  /// 3. Fallback builder.
  /// 4. Throws [SduiUnknownWidgetException].
  SduiWidgetBuilder resolve(String type, {required String nodePath}) {
    if (_builders.containsKey(type)) return _builders[type]!;

    // Check namespace wildcard.
    final colon = type.indexOf(':');
    if (colon > 0) {
      final ns = type.substring(0, colon);
      if (_wildcards.containsKey(ns)) return _wildcards[ns]!;
    }

    if (_fallback != null) return _fallback!;
    throw SduiUnknownWidgetException(type: type, path: nodePath);
  }

  /// Returns `true` if an exact builder is registered for [type].
  bool isRegistered(String type) => _builders.containsKey(type);

  /// Removes the builder for [type].
  void unregister(String type) => _builders.remove(type);

  /// Removes all builders, wildcards, and the fallback.
  ///
  /// Intended for use in tests.
  void clear() {
    _builders.clear();
    _wildcards.clear();
    _fallback = null;
  }

  /// All explicitly registered type strings (no wildcards).
  List<String> get registeredTypes => List.unmodifiable(_builders.keys);

  /// A debug description listing registered namespaces and type counts.
  String get debugDescription {
    final ns = <String, int>{};
    for (final t in _builders.keys) {
      final colon = t.indexOf(':');
      final key = colon > 0 ? t.substring(0, colon) : '<no-ns>';
      ns[key] = (ns[key] ?? 0) + 1;
    }
    final parts = ns.entries.map((e) => '${e.key}(${e.value})').join(', ');
    return 'SduiWidgetRegistry[$parts]';
  }
}
