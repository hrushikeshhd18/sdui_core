import 'package:flutter/material.dart';

import 'package:sdui_core/src/models/sdui_action.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/widgets/sdui_scope.dart';

/// Convenience extensions on [BuildContext] for `sdui_core` consumers.
extension SduiContextExtension on BuildContext {
  /// Returns the [SduiWidgetRegistry] from the nearest [SduiScope].
  SduiWidgetRegistry get sduiRegistry => SduiScope.of(this).registry;

  /// Returns the [SduiActionRegistry] from the nearest [SduiScope].
  SduiActionRegistry get sduiActions => SduiScope.of(this).actionRegistry;

  /// Dispatches a named SDUI action programmatically from anywhere in the tree.
  ///
  /// ```dart
  /// await context.dispatchSduiAction(
  ///   'add_to_cart',
  ///   payload: {'sku': 'APPLE_1KG'},
  /// );
  /// ```
  Future<SduiActionResult> dispatchSduiAction(
    String eventName, {
    Map<String, Object?> payload = const {},
    String nodePath = '<imperative>',
  }) {
    final action = SduiAction(
      type: SduiActionType.dispatch,
      event: eventName,
      payload: payload,
    );
    final actionCtx = SduiActionContext(
      flutterContext: this,
      nodeProps: const {},
      nodePath: nodePath,
    );
    return sduiActions.dispatch(eventName, action, actionCtx);
  }
}
