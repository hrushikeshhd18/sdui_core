import 'package:flutter/material.dart';

/// Extension methods for parsing color values from strings.
extension SduiColorParsing on String {
  /// Parses this string as a CSS-style hex color.
  ///
  /// Supported formats: `"#RGB"`, `"#RRGGBB"`, `"#AARRGGBB"`, `"0xAARRGGBB"`.
  ///
  /// Returns [fallback] if parsing fails.
  Color toColor({Color fallback = Colors.transparent}) {
    var s = trim().replaceFirst('#', '').replaceFirst('0x', '');
    switch (s.length) {
      case 3:
        s = '${s[0]}${s[0]}${s[1]}${s[1]}${s[2]}${s[2]}';
        s = 'FF$s';
      case 6:
        s = 'FF$s';
      case 8:
        break;
      default:
        return fallback;
    }
    final v = int.tryParse(s, radix: 16);
    return v != null ? Color(v) : fallback;
  }
}

/// Extension methods for converting integers to [Color].
extension SduiColorFromInt on int {
  /// Interprets this integer as an ARGB color value.
  Color toColor() => Color(this);
}
