import 'package:flutter/material.dart';

/// Type-safe wrapper around a raw JSON props map.
///
/// Use this in custom widget builders to read props without casting noise:
/// ```dart
/// Widget myBuilder(SduiNode node, SduiBuildContext ctx) {
///   final p = SduiProps(node.props);
///   return Text(
///     p.getString('text'),
///     style: TextStyle(color: p.getColor('color', fallback: Colors.black)),
///     maxLines: p.getInt('maxLines', fallback: 1),
///   );
/// }
/// ```
@immutable
final class SduiProps {
  /// Creates a [SduiProps] wrapper around `map`.
  const SduiProps(this._map);

  final Map<String, Object?> _map;

  // ---------------------------------------------------------------------------
  // String
  // ---------------------------------------------------------------------------

  /// Returns the string value for [key], or [fallback] if missing or not a string.
  String getString(String key, {String fallback = ''}) {
    final v = _map[key];
    return v is String ? v : fallback;
  }

  /// Returns the string value for [key], or `null` if missing.
  String? getStringOrNull(String key) {
    final v = _map[key];
    return v is String ? v : null;
  }

  // ---------------------------------------------------------------------------
  // Numbers
  // ---------------------------------------------------------------------------

  /// Returns the double value for [key], or [fallback] if missing.
  double getDouble(String key, {double fallback = 0.0}) {
    final v = _map[key];
    if (v is num) return v.toDouble();
    return fallback;
  }

  /// Returns the double value for [key], or `null` if missing.
  double? getDoubleOrNull(String key) {
    final v = _map[key];
    return v is num ? v.toDouble() : null;
  }

  /// Returns the int value for [key], or [fallback] if missing.
  int getInt(String key, {int fallback = 0}) {
    final v = _map[key];
    if (v is num) return v.toInt();
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Bool
  // ---------------------------------------------------------------------------

  /// Returns the bool value for [key], or [fallback] if missing.
  bool getBool(String key, {bool fallback = false}) {
    final v = _map[key];
    if (v is bool) return v;
    if (v is String) return v == 'true';
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Color — accepts '#RRGGBB', '#AARRGGBB', or int 0xAARRGGBB
  // ---------------------------------------------------------------------------

  /// Returns a [Color] for [key].
  ///
  /// Accepted formats: `"#RGB"`, `"#RRGGBB"`, `"#AARRGGBB"`, or an integer
  /// like `0xFFFF0000`.
  ///
  /// Returns [fallback] if the key is missing or the value can't be parsed.
  Color getColor(String key, {Color fallback = Colors.transparent}) =>
      getColorOrNull(key) ?? fallback;

  /// Returns a [Color] for [key], or `null` if missing or unparseable.
  Color? getColorOrNull(String key) {
    final v = _map[key];
    if (v == null) return null;
    if (v is int) return Color(v);
    if (v is String) return _parseHexColor(v);
    return null;
  }

  static Color? _parseHexColor(String raw) {
    final hex = raw.replaceFirst('#', '');
    switch (hex.length) {
      case 3:
        final r = hex[0] * 2;
        final g = hex[1] * 2;
        final b = hex[2] * 2;
        return Color(int.tryParse('FF$r$g$b', radix: 16) ?? 0);
      case 6:
        final v = int.tryParse('FF$hex', radix: 16);
        return v != null ? Color(v) : null;
      case 8:
        final v = int.tryParse(hex, radix: 16);
        return v != null ? Color(v) : null;
      default:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // EdgeInsets
  // ---------------------------------------------------------------------------

  /// Returns [EdgeInsets] for [key].
  ///
  /// The prop can be a single double (all sides) or a nested map with
  /// `left`, `top`, `right`, `bottom`, `horizontal`, `vertical` keys.
  EdgeInsets getEdgeInsets(
    String key, {
    EdgeInsets fallback = EdgeInsets.zero,
  }) {
    final v = _map[key];
    if (v == null) {
      // Fall back to top-level shorthand keys for the common case where
      // padding props are stored directly in the node's props map.
      return _edgeInsetsFromMap(_map) ?? fallback;
    }
    if (v is num) return EdgeInsets.all(v.toDouble());
    if (v is Map) {
      final m = Map<String, Object?>.from(v);
      return _edgeInsetsFromMap(m) ?? fallback;
    }
    return fallback;
  }

  static EdgeInsets? _edgeInsetsFromMap(Map<String, Object?> m) {
    final all =
        (m['all'] as num?)?.toDouble() ?? (m['padding'] as num?)?.toDouble();
    if (all != null) return EdgeInsets.all(all);

    final h = (m['horizontal'] as num?)?.toDouble();
    final v = (m['vertical'] as num?)?.toDouble();
    final l = (m['left'] as num?)?.toDouble() ?? h;
    final t = (m['top'] as num?)?.toDouble() ?? v;
    final r = (m['right'] as num?)?.toDouble() ?? h;
    final b = (m['bottom'] as num?)?.toDouble() ?? v;

    if (l == null && t == null && r == null && b == null) return null;
    return EdgeInsets.fromLTRB(l ?? 0, t ?? 0, r ?? 0, b ?? 0);
  }

  // ---------------------------------------------------------------------------
  // BorderRadius
  // ---------------------------------------------------------------------------

  /// Returns [BorderRadius] for [key].
  ///
  /// Accepts a single double (circular) or a map with `tl`, `tr`, `bl`, `br`.
  BorderRadius getBorderRadius(
    String key, {
    BorderRadius fallback = BorderRadius.zero,
  }) {
    final v = _map[key];
    if (v == null) return fallback;
    if (v is num) return BorderRadius.circular(v.toDouble());
    if (v is Map) {
      final m = v.cast<String, Object?>();
      return BorderRadius.only(
        topLeft: Radius.circular((m['tl'] as num?)?.toDouble() ?? 0),
        topRight: Radius.circular((m['tr'] as num?)?.toDouble() ?? 0),
        bottomLeft: Radius.circular((m['bl'] as num?)?.toDouble() ?? 0),
        bottomRight: Radius.circular((m['br'] as num?)?.toDouble() ?? 0),
      );
    }
    return fallback;
  }

  // ---------------------------------------------------------------------------
  // Alignment
  // ---------------------------------------------------------------------------

  /// Returns an [Alignment] for [key] from a named string.
  ///
  /// Supported values: `center`, `topLeft`, `topCenter`, `topRight`,
  /// `centerLeft`, `centerRight`, `bottomLeft`, `bottomCenter`, `bottomRight`.
  Alignment getAlignment(String key, {Alignment fallback = Alignment.center}) =>
      switch (_map[key] as String? ?? '') {
        'topLeft' => Alignment.topLeft,
        'topCenter' => Alignment.topCenter,
        'topRight' => Alignment.topRight,
        'centerLeft' => Alignment.centerLeft,
        'center' => Alignment.center,
        'centerRight' => Alignment.centerRight,
        'bottomLeft' => Alignment.bottomLeft,
        'bottomCenter' => Alignment.bottomCenter,
        'bottomRight' => Alignment.bottomRight,
        _ => fallback,
      };

  // ---------------------------------------------------------------------------
  // Layout enums
  // ---------------------------------------------------------------------------

  /// Returns a [MainAxisAlignment] from a named string prop.
  MainAxisAlignment getMainAxisAlignment(
    String key, {
    MainAxisAlignment fallback = MainAxisAlignment.start,
  }) =>
      switch (_map[key] as String? ?? '') {
        'center' => MainAxisAlignment.center,
        'end' => MainAxisAlignment.end,
        'spaceBetween' => MainAxisAlignment.spaceBetween,
        'spaceAround' => MainAxisAlignment.spaceAround,
        'spaceEvenly' => MainAxisAlignment.spaceEvenly,
        _ => fallback,
      };

  /// Returns a [CrossAxisAlignment] from a named string prop.
  CrossAxisAlignment getCrossAxisAlignment(
    String key, {
    CrossAxisAlignment fallback = CrossAxisAlignment.center,
  }) =>
      switch (_map[key] as String? ?? '') {
        'start' => CrossAxisAlignment.start,
        'end' => CrossAxisAlignment.end,
        'stretch' => CrossAxisAlignment.stretch,
        'baseline' => CrossAxisAlignment.baseline,
        _ => fallback,
      };

  /// Returns a [TextAlign] from a named string prop.
  TextAlign getTextAlign(
    String key, {
    TextAlign fallback = TextAlign.start,
  }) =>
      switch (_map[key] as String? ?? '') {
        'center' => TextAlign.center,
        'right' || 'end' => TextAlign.right,
        'justify' => TextAlign.justify,
        'left' || 'start' => TextAlign.left,
        _ => fallback,
      };

  /// Returns a [BoxFit] from a named string prop.
  BoxFit getBoxFit(String key, {BoxFit fallback = BoxFit.cover}) =>
      switch (_map[key] as String? ?? '') {
        'contain' => BoxFit.contain,
        'fill' => BoxFit.fill,
        'fitWidth' => BoxFit.fitWidth,
        'fitHeight' => BoxFit.fitHeight,
        'none' => BoxFit.none,
        'scaleDown' => BoxFit.scaleDown,
        _ => fallback,
      };

  /// Returns an [Axis] from a named string prop.
  Axis getAxis(String key, {Axis fallback = Axis.vertical}) =>
      (_map[key] as String? ?? '') == 'horizontal' ? Axis.horizontal : fallback;

  /// Returns a [MainAxisSize] from a named string prop.
  MainAxisSize getMainAxisSize(
    String key, {
    MainAxisSize fallback = MainAxisSize.max,
  }) =>
      (_map[key] as String? ?? '') == 'min' ? MainAxisSize.min : fallback;

  // ---------------------------------------------------------------------------
  // Nested & collections
  // ---------------------------------------------------------------------------

  /// Returns a nested [SduiProps] for [key], or an empty props if missing.
  SduiProps getNested(String key) {
    final v = _map[key];
    if (v is Map) return SduiProps(Map<String, Object?>.from(v));
    return const SduiProps({});
  }

  /// Returns a typed list for [key], applying [mapper] to each element.
  List<T> getList<T>(String key, T Function(Object?) mapper) {
    final v = _map[key];
    if (v is! List) return const [];
    return v.map(mapper).toList();
  }

  // ---------------------------------------------------------------------------
  // Raw access
  // ---------------------------------------------------------------------------

  /// Returns the raw value for [key].
  Object? operator [](String key) => _map[key];

  /// Returns `true` if [key] exists in the props map.
  bool containsKey(String key) => _map.containsKey(key);

  @override
  String toString() => 'SduiProps(${_map.keys.join(', ')})';
}
