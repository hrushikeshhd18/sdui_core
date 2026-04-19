import 'dart:convert';
import 'dart:isolate';

import '../exceptions/sdui_exceptions.dart';
import '../models/sdui_action.dart';
import '../models/sdui_node.dart';
import '../registry/widget_registry.dart';

/// Types that are treated as layout containers and may have children.
///
/// All other registered types are treated as leaf nodes.
const _parentTypes = {
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
};

/// Converts raw JSON maps into a typed [SduiNode] tree.
///
/// The top-level payload must include a `"sdui_version"` field:
/// ```json
/// {
///   "sdui_version": "1.0",
///   "root": { "type": "sdui:column", "id": "root", ... }
/// }
/// ```
class SduiParser {
  SduiParser._();

  /// Schema versions this parser can handle.
  static const List<String> supportedVersions = ['1.0'];

  /// Parses a decoded JSON [map] synchronously.
  ///
  /// Validates `sdui_version`, then recursively builds the [SduiNode] tree
  /// starting at the `"root"` key (or the map itself if no `"root"` key).
  ///
  /// Throws [SduiVersionException] if the version is missing or unsupported.
  /// Throws [SduiParseException] if a required field is absent.
  static SduiNode parse(Map<String, dynamic> map) {
    final version = map['sdui_version'] as String?;
    if (version == null || !supportedVersions.contains(version)) {
      throw SduiVersionException(
        receivedVersion: version ?? '<missing>',
        supportedVersions: supportedVersions,
      );
    }

    // Allow the payload to either be the node directly or wrap it under "root".
    final rawNode =
        map.containsKey('root') ? map['root'] as Map<String, dynamic> : map;

    return _parseNode(rawNode, 'root');
  }

  /// Parses [jsonString] in a separate [Isolate] to keep the UI thread free.
  ///
  /// Returns the same result as [parse] but never blocks the raster thread.
  static Future<SduiNode> parseAsync(String jsonString) async {
    return Isolate.run(() {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      return parse(decoded);
    });
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  // Safely converts an untyped Map (e.g. Map<dynamic, dynamic> from json
  // literals in tests) to Map<String, dynamic>.
  static Map<String, dynamic>? _toStringMap(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    return null;
  }

  static SduiNode _parseNode(Map<String, dynamic> json, String path) {
    final type = json['type'] as String?;
    if (type == null || type.isEmpty) {
      throw SduiParseException(
        nodeType: '<missing>',
        path: path,
        message: 'Node at "$path" is missing the required "type" field.',
      );
    }

    final id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw SduiParseException(
        nodeType: type,
        path: path,
        message: 'Node at "$path" (type: "$type") is missing the required "id" field.',
      );
    }

    final version = (json['version'] as num?)?.toInt() ?? 0;
    final props = _toStringMap(json['props']) ?? const {};
    final actionsRaw = _toStringMap(json['actions']) ?? const {};

    final actions = actionsRaw.map(
      (k, v) => MapEntry(k, SduiAction.fromJson(_toStringMap(v)!)),
    );

    final isRegistered = SduiWidgetRegistry.instance.isRegistered(type);

    // Unknown type → produce SduiUnknownNode, never throw.
    if (!isRegistered && !_parentTypes.contains(type)) {
      // Check if the JSON has children to decide which unknown node to use.
      final rawChildren = (json['children'] as List?)?.cast<dynamic>() ?? const [];
      if (rawChildren.isNotEmpty) {
        final children = _parseChildren(rawChildren, path);
        return SduiParentNode(
          id: id,
          type: type,
          version: version,
          props: props,
          actions: actions,
          children: children,
        );
      }
      return SduiUnknownNode(
        id: id,
        type: type,
        version: version,
        props: props,
        actions: actions,
      );
    }

    final isParent = _parentTypes.contains(type);
    final rawChildren = (json['children'] as List?)?.cast<dynamic>() ?? const [];

    if (isParent || rawChildren.isNotEmpty) {
      final children = _parseChildren(rawChildren, path);
      return SduiParentNode(
        id: id,
        type: type,
        version: version,
        props: props,
        actions: actions,
        children: children,
      );
    }

    return SduiLeafNode(
      id: id,
      type: type,
      version: version,
      props: props,
      actions: actions,
    );
  }

  static List<SduiNode> _parseChildren(
      List<dynamic> rawList, String parentPath) {
    final children = <SduiNode>[];
    for (var i = 0; i < rawList.length; i++) {
      final child = rawList[i];
      final childMap = _toStringMap(child);
      if (childMap != null) {
        final childId = childMap['id'] as String? ?? i.toString();
        children.add(_parseNode(childMap, '$parentPath/$childId'));
      }
    }
    return children;
  }
}
