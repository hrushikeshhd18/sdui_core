import 'dart:convert';

import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/parser/sdui_template.dart';

/// Resolves [$ref] references and [templates] in an SDUI JSON payload.
///
/// Inspired by DivKit's template system — allows JSON payloads to define
/// reusable templates that are expanded before parsing.
///
/// **Usage in JSON:**
/// ```json
/// {
///   "sdui_version": "1.0",
///   "templates": {
///     "product_card": {
///       "type": "sdui:card",
///       "props": { "borderRadius": 12, "elevation": 2 },
///       "children": [
///         { "$ref": "product_content" }
///       ]
///     },
///     "product_content": {
///       "type": "sdui:column",
///       "props": { "crossAxisAlignment": "stretch" },
///       "children": [
///         { "type": "sdui:image", "props": { "fit": "cover" } },
///         { "type": "sdui:text", "props": { "style": "body" } }
///       ]
///     }
///   },
///   "root": {
///     "type": "sdui:column",
///     "children": [
///       { "$ref": "product_card", "id": "prod1", "props": { "image": "..." } }
///     ]
///   }
/// }
/// ```
///
/// Templates can contain:
/// - Placeholder variables: `"{{variable}}"` — replaced by the referencing node's props
/// - Nested $refs to compose larger patterns from smaller ones
abstract final class SduiTemplateResolver {
  /// Resolves all templates in [payload] in-place.
  ///
  /// Returns a new map with all `$ref` references expanded and template nodes
  /// merged with their reference sites.
  static Map<String, Object?> resolve(Map<String, Object?> payload) {
    // Extract templates from the payload
    final templatesRaw = payload['templates'];
    if (templatesRaw is! Map) {
      // No templates — return payload as-is
      return payload;
    }

    final templateDefs = <String, Map<String, Object?>>{};
    for (final entry in templatesRaw.entries) {
      if (entry.value is Map) {
        templateDefs[entry.key.toString()] =
            Map<String, Object?>.from(entry.value as Map);
      }
    }

    if (templateDefs.isEmpty) return payload;

    // Build a copy of the payload without the templates key
    final result = Map<String, Object?>.from(payload);
    result.remove('templates');

    // Resolve $ref in the root node
    if (result['root'] is Map) {
      result['root'] = _resolveNodeRefs(
        Map<String, Object?>.from(result['root'] as Map<String, Object?>),
        templateDefs,
        {},
      );
    }

    return result;
  }

  static Map<String, Object?> _resolveNodeRefs(
    Map<String, Object?> node,
    Map<String, Map<String, Object?>> templates,
    Map<String, Object?> inheritedProps,
  ) {
    // Check if this node is a $ref
    final ref = node['\$ref'] as String?;
    if (ref != null && templates.containsKey(ref)) {
      final template = Map<String, Object?>.from(templates[ref]!);
      return _mergeNodeWithTemplate(node, template, templates, inheritedProps);
    }

    // Recursively resolve children
    final children = node['children'];
    if (children is List) {
      final resolvedChildren = <Object?>[];
      for (final child in children) {
        if (child is Map) {
          resolvedChildren.add(
            _resolveNodeRefs(
              Map<String, Object?>.from(child),
              templates,
              _extractProps(node),
            ),
          );
        } else {
          resolvedChildren.add(child);
        }
      }
      node['children'] = resolvedChildren;
    }

    // Resolve nested refs in other fields
    for (final key in node.keys.toList()) {
      if (key == '\$ref' || key == 'children' || key == 'templates') continue;
      final value = node[key];
      if (value is Map) {
        node[key] = _resolveNodeRefs(
          Map<String, Object?>.from(value as Map),
          templates,
          inheritedProps,
        );
      }
    }

    // Resolve template variable placeholders in all fields
    return _resolvePlaceholders(node, inheritedProps);
  }

  static Map<String, Object?> _mergeNodeWithTemplate(
    Map<String, Object?> refNode,
    Map<String, Object?> template,
    Map<String, Map<String, Object?>> templates,
    Map<String, Object?> inheritedProps,
  ) {
    // Start with template as base
    final merged = Map<String, Object?>.from(template);

    // Override with refNode's own fields (except $ref)
    for (final entry in refNode.entries) {
      if (entry.key == '\$ref') continue;

      if (entry.key == 'props' && merged.containsKey('props')) {
        // Deep-merge props
        final templateProps =
            (merged['props'] as Map?)?.cast<String, Object?>() ?? {};
        final refProps =
            (entry.value as Map?)?.cast<String, Object?>() ?? {};
        merged['props'] = {
          ...templateProps,
          ...refProps,
        };
      } else if (entry.key == 'children' && merged.containsKey('children')) {
        // Children from the ref replace template children
        if (entry.value is List) {
          merged['children'] = entry.value;
        }
      } else {
        merged[entry.key] = entry.value;
      }
    }

    // Resolve nested $refs in the merged node
    return _resolveNodeRefs(merged, templates, inheritedProps);
  }

  static Map<String, Object?> _resolvePlaceholders(
    Map<String, Object?> node,
    Map<String, Object?> inheritedProps,
  ) {
    final result = Map<String, Object?>.from(node);

    for (final key in result.keys.toList()) {
      final value = result[key];
      if (value is String && value.contains('{{')) {
        result[key] = _resolveStringPlaceholders(value, inheritedProps);
      }
    }

    return result;
  }

  static Object? _resolveStringPlaceholders(
    String value,
    Map<String, Object?> props,
  ) {
    // Replace {{variable}} with props.variable or inheritedProps.variable
    return value.replaceAllMapped(
      RegExp(r'\{\{(\w+)\}\}'),
      (match) {
        final varName = match.group(1)!;
        if (props.containsKey(varName)) {
          return props[varName]?.toString() ?? '';
        }
        return match.group(0)!; // Keep unresolved
      },
    );
  }

  static Map<String, Object?> _extractProps(Map<String, Object?> node) {
    final props = node['props'];
    if (props is Map) return props.cast<String, Object?>();
    return {};
  }
}
