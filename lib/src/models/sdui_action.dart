import 'package:flutter/material.dart' show AlertDialog, Navigator, SnackBar;
import 'package:meta/meta.dart';
import 'package:sdui_core/sdui_core.dart' show SduiActionRegistry, SduiScreen;

/// Well-known action type constants understood by [SduiActionRegistry].
abstract final class SduiActionType {
  /// Fires a named event to a registered handler.
  static const String dispatch = 'dispatch';

  /// Calls [Navigator] to push a named route.
  static const String navigate = 'navigate';

  /// Launches a URL in the platform browser.
  static const String openUrl = 'open_url';

  /// Copies a value to the system clipboard.
  static const String copyToClipboard = 'copy_to_clipboard';

  /// Displays a [SnackBar] with a message from the action payload.
  static const String showSnackbar = 'show_snackbar';

  /// Displays a modal bottom sheet.
  static const String showBottomSheet = 'show_bottom_sheet';

  /// Dismisses the topmost modal bottom sheet.
  static const String dismissBottomSheet = 'dismiss_bottom_sheet';

  /// Shows an [AlertDialog].
  static const String showDialog = 'show_dialog';

  /// Triggers a reload of the nearest [SduiScreen].
  static const String refresh = 'refresh';
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
@immutable
final class SduiAction {
  /// Creates an [SduiAction].
  const SduiAction({
    required this.type,
    required this.event,
    this.payload = const {},
    this.debounceMs,
  });

  /// One of the [SduiActionType] constants or any custom string.
  final String type;

  /// The event name forwarded to the action registry when
  /// [SduiActionType.dispatch] is used.
  final String event;

  /// Arbitrary key/value data passed to the handler.
  final Map<String, Object?> payload;

  /// When set, the action cannot re-fire within this many milliseconds.
  /// Prevents double-tap issues on slow devices.
  final int? debounceMs;

  /// Decodes an [SduiAction] from a raw JSON map.
  factory SduiAction.fromJson(Map<String, Object?> json) {
    final rawPayload = json['payload'];
    final Map<String, Object?> payload;
    if (rawPayload is Map) {
      payload = Map<String, Object?>.from(rawPayload);
    } else {
      payload = const {};
    }
    return SduiAction(
      type: json['type'] as String? ?? SduiActionType.dispatch,
      event: json['event'] as String? ?? '',
      payload: payload,
      debounceMs: json['debounceMs'] as int?,
    );
  }

  /// Serialises this action to a JSON-compatible map.
  Map<String, Object?> toJson() => {
        'type': type,
        'event': event,
        'payload': payload,
        if (debounceMs != null) 'debounceMs': debounceMs,
      };

  /// Returns a copy of this action with the given fields replaced.
  SduiAction copyWith({
    String? type,
    String? event,
    Map<String, Object?>? payload,
    int? debounceMs,
  }) =>
      SduiAction(
        type: type ?? this.type,
        event: event ?? this.event,
        payload: payload ?? this.payload,
        debounceMs: debounceMs ?? this.debounceMs,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SduiAction &&
          type == other.type &&
          event == other.event &&
          debounceMs == other.debounceMs;

  @override
  int get hashCode => Object.hash(type, event, debounceMs);

  @override
  String toString() => 'SduiAction(type: $type, event: $event)';
}
