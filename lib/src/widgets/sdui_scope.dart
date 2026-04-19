import 'package:flutter/widgets.dart';

import '../registry/action_registry.dart';
import '../registry/widget_registry.dart';

/// An [InheritedWidget] that propagates [SduiWidgetRegistry] and
/// [SduiActionRegistry] down the widget tree.
///
/// Wrap your app (or a subtree) with [SduiScope] to avoid passing registries
/// through every layer of code:
/// ```dart
/// SduiScope(
///   child: MaterialApp(home: SduiScreen(url: '...')),
/// )
/// ```
/// When [registry] or [actionRegistry] are omitted the global singleton
/// instances are used automatically.
class SduiScope extends InheritedWidget {
  /// The widget registry in scope.
  final SduiWidgetRegistry registry;

  /// The action registry in scope.
  final SduiActionRegistry actionRegistry;

  /// Creates an [SduiScope].
  ///
  /// Omit [registry] and [actionRegistry] to use the global singletons.
  SduiScope({
    super.key,
    SduiWidgetRegistry? registry,
    SduiActionRegistry? actionRegistry,
    required super.child,
  })  : registry = registry ?? SduiWidgetRegistry.instance,
        actionRegistry = actionRegistry ?? SduiActionRegistry.instance;

  /// Returns the nearest [SduiScope] ancestor.
  ///
  /// Throws a [FlutterError] if none is found. Use [maybeOf] when the scope
  /// may be absent.
  static SduiScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SduiScope>();
    if (scope == null) {
      throw FlutterError(
        'SduiScope.of() called with a context that does not contain a SduiScope.\n'
        'Wrap your widget tree (or your MaterialApp) with SduiScope.',
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
      actionRegistry != oldWidget.actionRegistry;
}
