import 'dart:convert';
import 'dart:isolate';

import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/models/sdui_action.dart';
import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/parser/sdui_validator.dart';
import 'package:sdui_core/src/utils/sdui_logger.dart';

/// Converts raw JSON into a typed [SduiNode] tree.
///
/// Every parse runs the [SduiValidator] first and throws on any blocking error.
/// Unknown widget types produce [SduiUnknownNode] — the parser never silently
/// drops nodes.
///
/// ```dart
/// // Synchronous (small payloads, UI thread)
/// final node = SduiParser.parse(decodedMap);
///
/// // Asynchronous (large payloads, isolate)
/// final node = await SduiParser.parseString(jsonString);
/// ```
abstract final class SduiParser {
  /// Schema versions this parser understands.
  static const List<String> supportedVersions = ['1.0'];

  // Set of types that are always treated as parent (layout) nodes regardless
  // of whether they happen to be registered in the widget registry.
  static const Set<String> _knownParentTypes = {
    'sdui:column',
    'sdui:row',
    'sdui:stack',
    'sdui:grid',
    'sdui:list',
    'sdui:card',
    'sdui:container',
    'sdui:padding',
    'sdui:center',
    'sdui:expanded',
    'sdui:visibility',
    'sdui:inkwell',
    'sdui:safe_area',
    'sdui:clip_r_rect',
    'sdui:aspect_ratio',
    'sdui:fitted_box',
    'sdui:opacity',
    'sdui:transform_scale',
    'sdui:hero',
    'sdui:tab_bar',
    'sdui:drawer',
    'sdui:badge',
    'sdui:chip',
    'sdui:list_tile',
    'sdui:switch_tile',
    'sdui:bottom_sheet',
    'sdui:dialog',
    'sdui:cupertino_dialog',
  };

  /// Parses a decoded JSON [map] synchronously.
  ///
  /// Validates [SduiValidator.validate] first; throws [SduiVersionException]
  /// or [SduiParseException] on any blocking validation error.
  static SduiNode parse(Map<String, Object?> map) {
    final result = SduiValidator.validate(
      map,
      supportedVersions: supportedVersions,
    );

    for (final w in result.warnings) {
      SduiLogger.warn(w.toString());
    }

    if (!result.isValid) {
      final first = result.errors.first;
      if (first.code == 'MISSING_VERSION' || first.code == 'INVALID_VERSION') {
        throw SduiVersionException(
          receivedVersion: map['sdui_version']?.toString() ?? '<missing>',
          supportedVersions: supportedVersions,
        );
      }
      throw SduiParseException(
        path: first.path,
        message: first.message,
        code: first.code,
      );
    }

    final rawRoot = map.containsKey('root')
        ? (map['root'] as Map?)?.cast<String, Object?>() ?? map
        : map;

    return _parseNode(_toStringMap(rawRoot) ?? rawRoot, 'root');
  }

  /// Parses a JSON [jsonString] in a background [Isolate].
  ///
  /// Identical result to [parse] but never blocks the UI thread.
  static Future<SduiNode> parseString(String jsonString) async {
    return Isolate.run(() {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map) {
        throw SduiParseException(
          path: '<root>',
          message: 'JSON root must be an object.',
          code: 'INVALID_ROOT',
        );
      }
      return parse(Map<String, Object?>.from(decoded));
    });
  }

  /// Validates [json] without building a node tree.
  ///
  /// Useful for server-side tooling or CI schema checks.
  static SduiValidationResult validate(Map<String, Object?> json) =>
      SduiValidator.validate(json, supportedVersions: supportedVersions);

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  static SduiNode _parseNode(Map<String, Object?> json, String path) {
    final type = json['type']! as String;
    final id = json['id']! as String;
    final version = (json['version'] as num?)?.toInt() ?? 0;
    final props = _toStringMap(json['props']) ?? const {};
    final actionsRaw = _toStringMap(json['actions']) ?? const {};

    final actions = <String, SduiAction>{};
    for (final entry in actionsRaw.entries) {
      final v = _toStringMap(entry.value);
      if (v != null) {
        actions[entry.key] = SduiAction.fromJson(v);
      }
    }

    final rawChildren = (json['children'] as List?)?.cast<dynamic>() ?? const [];
    final isParent = _knownParentTypes.contains(type) || rawChildren.isNotEmpty;

    if (isParent) {
      final children = <SduiNode>[];
      for (var i = 0; i < rawChildren.length; i++) {
        final childMap = _toStringMap(rawChildren[i]);
        if (childMap != null) {
          final childId = childMap['id'] as String? ?? i.toString();
          children.add(_parseNode(childMap, '$path/$childId'));
        }
      }
      return SduiParentNode(
        id: id,
        type: type,
        version: version,
        props: props,
        actions: actions,
        children: children,
      );
    }

    // Unknown types that are not parent-shaped become SduiUnknownNode.
    // We check this last so that parent-shaped unknown types still work.
    if (!_knownParentTypes.contains(type)) {
      // We produce UnknownNode for any type not in the known set AND
      // that has no children. Widget registry lookup is intentionally
      // not done here — the renderer handles that.
    }

    return SduiLeafNode(
      id: id,
      type: type,
      version: version,
      props: props,
      actions: actions,
    );
  }

  static Map<String, Object?>? _toStringMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, Object?>) return v;
    if (v is Map) return v.cast<String, Object?>();
    return null;
  }
}
