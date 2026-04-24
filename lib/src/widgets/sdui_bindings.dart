import 'package:flutter/widgets.dart';

/// A [ChangeNotifier] that holds observable key/value bindings for the SDUI
/// tree.
///
/// Create one, populate it from your state-management layer, and wrap your
/// `SduiScope` with a [SduiBindings] widget. Any node whose `visible_if` prop
/// starts with `binding.` will be shown or hidden based on the live value
/// stored here — without a server round-trip.
///
/// ```dart
/// final bindings = SduiBindingsNotifier({
///   'user.isPremium': false,
///   'feature.newCheckout': false,
/// });
///
/// // Update from Bloc / Provider / Riverpod:
/// authBloc.stream.listen((s) {
///   bindings.put('user.isPremium', s.isPremium);
/// });
///
/// // Wire into the widget tree:
/// SduiBindings(
///   notifier: bindings,
///   child: SduiScope(child: ...),
/// )
///
/// // Server JSON:
/// // { "visible_if": "binding.user.isPremium" }
/// // { "visible_if": "binding.feature.newCheckout" }
/// ```
final class SduiBindingsNotifier extends ChangeNotifier {
  /// Creates a notifier, optionally seeded with [initial] values.
  SduiBindingsNotifier([Map<String, Object?> initial = const {}])
      : _values = Map.of(initial);

  Map<String, Object?> _values;

  /// A read-only view of the current bindings.
  Map<String, Object?> get values => Map.unmodifiable(_values);

  /// Sets a single [key] to [value] and notifies listeners if the value
  /// changed.
  void put(String key, Object? value) {
    if (_values[key] == value) return;
    _values = {..._values, key: value};
    notifyListeners();
  }

  /// Merges all entries from [values] and notifies once if anything changed.
  void putAll(Map<String, Object?> values) {
    final next = Map.of(_values);
    var changed = false;
    for (final entry in values.entries) {
      if (next[entry.key] != entry.value) {
        next[entry.key] = entry.value;
        changed = true;
      }
    }
    if (changed) {
      _values = next;
      notifyListeners();
    }
  }

  /// Removes the entry for [key] and notifies listeners if it existed.
  void remove(String key) {
    if (!_values.containsKey(key)) return;
    _values = Map.of(_values)..remove(key);
    notifyListeners();
  }

  /// Resolves [key] to its current value, or `null` if not set.
  Object? resolve(String key) => _values[key];
}

/// An [InheritedNotifier] that propagates a [SduiBindingsNotifier] down the
/// widget tree.
///
/// Descendant widgets (specifically the SDUI renderer when evaluating
/// `visible_if: "binding.X"` expressions) depend on this widget and rebuild
/// automatically when any binding changes.
///
/// Place it above `SduiScope`:
///
/// ```dart
/// SduiBindings(
///   notifier: myBindingsNotifier,
///   child: SduiScope(
///     child: MaterialApp(home: SduiScreen(url: '...')),
///   ),
/// )
/// ```
class SduiBindings extends InheritedNotifier<SduiBindingsNotifier> {
  /// Creates a [SduiBindings] widget.
  const SduiBindings({
    super.key,
    required SduiBindingsNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  /// Returns the [SduiBindingsNotifier] from the nearest [SduiBindings]
  /// ancestor, or `null` if none is present.
  ///
  /// Widgets that call this method will rebuild when the notifier fires.
  static SduiBindingsNotifier? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SduiBindings>()?.notifier;
}
