import 'package:flutter/widgets.dart';
import 'package:sdui_core/sdui_core.dart' show SduiScreen;

import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/widgets/builders/core_widgets.dart';
import 'package:sdui_core/src/widgets/builders/cupertino_widgets.dart';
import 'package:sdui_core/src/widgets/builders/material_widgets.dart';
import 'package:sdui_core/src/widgets/sdui_screen.dart' show SduiScreen;

/// Propagates [SduiWidgetRegistry], [SduiActionRegistry], and an optional
/// [navigatorKey] down the widget tree.
///
/// Wrap your app or a subtree with [SduiScope] to give every [SduiScreen]
/// access to the registries without prop-drilling:
/// ```dart
/// final _navigatorKey = GlobalKey<NavigatorState>();
///
/// SduiScope(
///   navigatorKey: _navigatorKey,   // optional — enables safe async navigation
///   registry: SduiWidgetRegistry.withDefaults()
///     ..register('myapp:banner', myBannerBuilder),
///   child: MaterialApp(
///     navigatorKey: _navigatorKey,
///     home: SduiScreen(url: '...'),
///   ),
/// )
/// ```
/// When [registry] or [actionRegistry] are omitted the built-in defaults
/// are used automatically.
class SduiScope extends InheritedWidget {
  /// Creates an [SduiScope].
  SduiScope({
    super.key,
    SduiWidgetRegistry? registry,
    SduiActionRegistry? actionRegistry,
    this.navigatorKey,
    required super.child,
  })  : registry = registry ?? (_defaultRegistry ??= _buildDefault()),
        actionRegistry = actionRegistry ?? SduiActionRegistry.defaults;

  /// The widget registry exposed to all descendants.
  final SduiWidgetRegistry registry;

  /// The action registry exposed to all descendants.
  final SduiActionRegistry actionRegistry;

  /// Optional [GlobalKey] for the app's root [NavigatorState].
  ///
  /// When provided, all SDUI `navigate` actions use this key instead of the
  /// local [BuildContext], which prevents crashes when the context is unmounted
  /// during a long-running async action handler:
  ///
  /// ```dart
  /// // app setup
  /// final _navKey = GlobalKey<NavigatorState>();
  ///
  /// SduiScope(navigatorKey: _navKey, child: MaterialApp(navigatorKey: _navKey, ...))
  /// ```
  final GlobalKey<NavigatorState>? navigatorKey;

  // Lazy singleton for the default registry — built once on first use.
  static SduiWidgetRegistry? _defaultRegistry;

  static SduiWidgetRegistry _buildDefault() {
    SduiWidgetRegistry.configureDefaultFactory(
      () => {
        ...createCoreWidgets(),
        ...createMaterialWidgets(),
        ...createCupertinoWidgets(),
      },
    );
    return SduiWidgetRegistry.withDefaults();
  }

  /// Returns the nearest [SduiScope] ancestor.
  ///
  /// Throws a [FlutterError] if none is found — use [maybeOf] when the scope
  /// may be absent.
  static SduiScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SduiScope>();
    if (scope == null) {
      throw FlutterError(
        'SduiScope.of() called with a context that has no SduiScope ancestor.\n'
        'Wrap your widget tree with SduiScope:\n'
        '  SduiScope(child: MaterialApp(...))',
      );
    }
    return scope;
  }

  /// Returns the nearest [SduiScope] ancestor, or `null` if none exists.
  static SduiScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SduiScope>();

  @override
  bool updateShouldNotify(SduiScope oldWidget) =>
      registry != oldWidget.registry ||
      actionRegistry != oldWidget.actionRegistry ||
      navigatorKey != oldWidget.navigatorKey;
}
