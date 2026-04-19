/// Well-known action type constants understood by [SduiActionRegistry].
abstract final class SduiActionType {
  /// Fires a named event to a registered [SduiActionHandler].
  static const String dispatch = 'dispatch';

  /// Calls [Navigator] to push a named route.
  static const String navigate = 'navigate';

  /// Launches a URL in the platform browser.
  static const String openUrl = 'open_url';

  /// Copies a value to the system clipboard.
  static const String copyToClipboard = 'copy_to_clipboard';

  /// Displays a [SnackBar] with a message from the action payload.
  static const String showSnackbar = 'show_snackbar';
}

/// Describes a side-effect that a widget can trigger in response to a gesture.
///
/// Actions are decoded from the `"actions"` map in a node's JSON:
/// ```json
/// {
///   "onTap": {
///     "type": "dispatch",
///     "event": "add_to_cart",
///     "payload": { "product_id": "sku_42" }
///   }
/// }
/// ```
class SduiAction {
  /// One of the [SduiActionType] constants or any custom string.
  final String type;

  /// The event name forwarded to the action registry (used with [SduiActionType.dispatch]).
  final String event;

  /// Arbitrary key/value data attached to the action.
  final Map<String, dynamic> payload;

  /// Creates an [SduiAction].
  const SduiAction({
    required this.type,
    required this.event,
    this.payload = const {},
  });

  /// Decodes an [SduiAction] from a raw JSON map.
  factory SduiAction.fromJson(Map<String, dynamic> json) {
    return SduiAction(
      type: json['type'] as String? ?? SduiActionType.dispatch,
      event: json['event'] as String? ?? '',
      payload: (json['payload'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// Serialises this action back to a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'type': type,
        'event': event,
        'payload': payload,
      };

  @override
  String toString() => 'SduiAction(type: $type, event: $event)';
}
