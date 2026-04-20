import 'package:flutter/widgets.dart';

/// An [InheritedWidget] that holds a named [TextStyle] registry for SDUI.
///
/// Widgets resolved from the server can reference styles by name (e.g. `"h1"`,
/// `"promo"`) without hard-coding values. Register app-specific or brand styles
/// here so the server can control typography without a native release.
///
/// ```dart
/// SduiTheme(
///   styles: {
///     'promo': TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
///     'fine_print': TextStyle(fontSize: 10, color: Colors.grey),
///   },
///   child: SduiScreen(url: '...'),
/// )
/// ```
class SduiTheme extends InheritedWidget {
  /// Creates a [SduiTheme].
  const SduiTheme({
    super.key,
    required this.styles,
    required super.child,
  });

  /// Named [TextStyle] registry.  Keys should be camelCase or snake_case
  /// strings that match the `"style"` prop value in server JSON.
  final Map<String, TextStyle> styles;

  /// Returns the nearest [SduiTheme] ancestor, or `null` if none is present.
  static SduiTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SduiTheme>();

  /// Returns the nearest [SduiTheme] ancestor.
  ///
  /// Throws a [FlutterError] if no [SduiTheme] is in scope — use [maybeOf]
  /// when the theme is truly optional.
  static SduiTheme of(BuildContext context) {
    final theme = maybeOf(context);
    assert(theme != null, 'No SduiTheme found in the widget tree.');
    return theme!;
  }

  /// Resolves [name] to a [TextStyle], returning `null` if not registered.
  TextStyle? resolve(String name) => styles[name];

  @override
  bool updateShouldNotify(SduiTheme oldWidget) => styles != oldWidget.styles;
}
