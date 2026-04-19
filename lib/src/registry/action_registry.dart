import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../exceptions/sdui_exceptions.dart';
import '../models/sdui_action.dart';

/// Context object passed to every [SduiActionHandler].
class SduiActionContext {
  /// The ambient Flutter [BuildContext] at the time the action fired.
  final BuildContext flutterContext;

  /// The `props` map of the node that triggered the action.
  final Map<String, dynamic> nodeProps;

  /// Dot-separated path of the triggering node, e.g. `"root/hero/cta"`.
  final String nodePath;

  /// Creates a [SduiActionContext].
  const SduiActionContext({
    required this.flutterContext,
    required this.nodeProps,
    required this.nodePath,
  });
}

/// A handler invoked when an [SduiAction] is dispatched.
typedef SduiActionHandler = Future<void> Function(
  SduiAction action,
  SduiActionContext context,
);

/// Singleton registry that maps event names to [SduiActionHandler]s.
///
/// The five built-in action types ([SduiActionType]) are handled automatically
/// without any registration. Register custom event handlers on top:
/// ```dart
/// SduiActionRegistry.instance.register('add_to_cart', (action, ctx) async {
///   final id = action.payload['product_id'];
///   CartBloc.of(ctx.flutterContext).add(AddItem(id));
/// });
/// ```
class SduiActionRegistry {
  SduiActionRegistry._();

  /// The global singleton instance.
  static final SduiActionRegistry instance = SduiActionRegistry._();

  final Map<String, SduiActionHandler> _handlers = {};

  /// Registers [handler] for [eventName].
  ///
  /// Overwrites any previously registered handler for the same name.
  void register(String eventName, SduiActionHandler handler) {
    _handlers[eventName] = handler;
  }

  /// Returns `true` if [eventName] has a registered handler.
  bool hasHandler(String eventName) => _handlers.containsKey(eventName);

  /// Removes the handler for [eventName] if present.
  void unregister(String eventName) => _handlers.remove(eventName);

  /// Removes all registered handlers.
  ///
  /// Intended for use in tests only.
  void clear() => _handlers.clear();

  /// Dispatches [action] to the appropriate handler.
  ///
  /// Built-in action types are handled first. Unknown [SduiActionType.dispatch]
  /// events that have no registered handler throw [SduiActionException].
  Future<void> dispatch(
    String eventName,
    SduiAction action,
    SduiActionContext ctx,
  ) async {
    switch (action.type) {
      case SduiActionType.navigate:
        final route = action.payload['route'] as String? ?? action.event;
        Navigator.of(ctx.flutterContext).pushNamed(route);
        return;

      case SduiActionType.openUrl:
        final raw = action.payload['url'] as String? ?? action.event;
        final uri = Uri.tryParse(raw);
        if (uri != null) await launchUrl(uri);
        return;

      case SduiActionType.copyToClipboard:
        final text = action.payload['text'] as String? ??
            ctx.nodeProps['text'] as String? ??
            '';
        await Clipboard.setData(ClipboardData(text: text));
        return;

      case SduiActionType.showSnackbar:
        final msg = action.payload['message'] as String? ?? '';
        if (ctx.flutterContext.mounted) {
          ScaffoldMessenger.of(ctx.flutterContext).showSnackBar(
            SnackBar(content: Text(msg)),
          );
        }
        return;

      case SduiActionType.dispatch:
      default:
        final handler = _handlers[eventName];
        if (handler == null) {
          throw SduiActionException(
            actionName: eventName,
            message: 'No handler registered for event "$eventName".',
          );
        }
        await handler(action, ctx);
    }
  }
}
