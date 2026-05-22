import 'package:meta/meta.dart';
import 'package:sdui_core/sdui_core.dart' show SduiParser;
import 'package:sdui_core/src/parser/sdui_parser.dart' show SduiParser;

/// A single blocking validation error.
@immutable
final class SduiValidationError {
  /// Creates an [SduiValidationError].
  const SduiValidationError({
    required this.path,
    required this.message,
    required this.code,
  });

  /// Dot-separated tree path where the error was found, e.g. `"root/hero/0"`.
  final String path;

  /// Human-readable description of the problem.
  final String message;

  /// Machine-readable identifier, e.g. `"MISSING_ID"`.
  final String code;

  @override
  String toString() => '[$code] $path — $message';
}

/// A non-blocking validation warning (logged only).
@immutable
final class SduiValidationWarning {
  /// Creates a [SduiValidationWarning].
  const SduiValidationWarning({
    required this.path,
    required this.message,
  });

  /// Dot-separated tree path where the warning was found.
  final String path;

  /// Description of the issue.
  final String message;

  @override
  String toString() => '[WARN] $path — $message';
}

/// Result of validating a raw SDUI JSON payload.
@immutable
final class SduiValidationResult {
  /// Creates a [SduiValidationResult].
  const SduiValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// `true` when there are no blocking errors.
  final bool isValid;

  /// Blocking errors — if any exist the payload should not be parsed.
  final List<SduiValidationError> errors;

  /// Non-blocking warnings — logged but do not prevent parsing.
  final List<SduiValidationWarning> warnings;

  @override
  String toString() =>
      'SduiValidationResult(valid: $isValid, errors: ${errors.length}, '
      'warnings: ${warnings.length})';
}

/// Validates a raw SDUI JSON payload before parsing.
///
/// Validates the full tree in one pass, collecting all errors rather than
/// throwing on the first one. Use [SduiParser.validate] to call this.
///
/// ## Version-aware validation
///
/// Rules that differ between schema versions:
///
/// | Rule | v1.0 | v2.0 |
/// |---|---|---|
/// | Node `version` field | Optional | Required (`MISSING_NODE_VERSION`) |
/// | Root `metadata` field | Ignored | Validated as object if present |
/// | Node `props` type | Not checked | Must be object (`INVALID_PROPS_TYPE`) |
/// | Node `actions` type | Must be object if present | Must be object (`INVALID_ACTIONS_TYPE`) |
abstract final class SduiValidator {
  /// Validates [json] and returns a structured result.
  ///
  /// Call with the decoded top-level map (including `sdui_version`).
  /// Pass [supportedVersions] to override the accepted schema versions.
  static SduiValidationResult validate(
    Map<String, Object?> json, {
    List<String> supportedVersions = const ['1.0', '2.0'],
  }) {
    final errors = <SduiValidationError>[];
    final warnings = <SduiValidationWarning>[];
    final seenIds = <String, String>{}; // id → first path

    // Check sdui_version.
    final version = json['sdui_version'];
    String? resolvedVersion;
    if (version == null) {
      errors.add(
        const SduiValidationError(
          path: '<root>',
          message: 'Missing required "sdui_version" field.',
          code: 'MISSING_VERSION',
        ),
      );
    } else if (!supportedVersions.contains(version)) {
      errors.add(
        SduiValidationError(
          path: '<root>',
          message: 'Unsupported sdui_version "$version". '
              'Supported: ${supportedVersions.join(', ')}.',
          code: 'INVALID_VERSION',
        ),
      );
    } else {
      resolvedVersion = version as String;
    }

    final isV2 = resolvedVersion == '2.0';

    // v2: validate optional root metadata field.
    if (isV2) {
      final metadata = json['metadata'];
      if (metadata != null && metadata is! Map) {
        warnings.add(
          const SduiValidationWarning(
            path: '<root>',
            message: '"metadata" must be a JSON object if present.',
          ),
        );
      }
    }

    // Locate the root node (may be under 'root' key or the map itself).
    final rawRoot = json.containsKey('root') ? json['root'] : json;
    if (rawRoot is Map) {
      _validateNode(
        Map<String, Object?>.from(rawRoot),
        'root',
        errors,
        warnings,
        seenIds,
        isV2: isV2,
      );
    } else if (version != null) {
      errors.add(
        const SduiValidationError(
          path: '<root>',
          message: 'Missing or invalid "root" node.',
          code: 'MISSING_ROOT',
        ),
      );
    }

    return SduiValidationResult(
      isValid: errors.isEmpty,
      errors: List.unmodifiable(errors),
      warnings: List.unmodifiable(warnings),
    );
  }

  static void _validateNode(
    Map<String, Object?> node,
    String path,
    List<SduiValidationError> errors,
    List<SduiValidationWarning> warnings,
    Map<String, String> seenIds, {
    required bool isV2,
  }) {
    final type = node['type'];
    if (type == null || (type is String && type.isEmpty)) {
      errors.add(
        SduiValidationError(
          path: path,
          message: 'Node is missing the required "type" field.',
          code: 'MISSING_TYPE',
        ),
      );
    }

    final id = node['id'];
    if (id == null || (id is String && id.isEmpty)) {
      errors.add(
        SduiValidationError(
          path: path,
          message: 'Node is missing the required "id" field.',
          code: 'MISSING_ID',
        ),
      );
    } else if (id is String) {
      if (id.contains(' ')) {
        warnings.add(
          SduiValidationWarning(
            path: path,
            message: '"id" contains spaces — prefer snake_case.',
          ),
        );
      }
      if (seenIds.containsKey(id)) {
        errors.add(
          SduiValidationError(
            path: path,
            message: 'Duplicate id "$id" — also found at "${seenIds[id]}".',
            code: 'DUPLICATE_ID',
          ),
        );
      } else {
        seenIds[id] = path;
      }
    }

    final version = node['version'];
    if (version == null) {
      // v2 requires an explicit version on every node.
      if (isV2) {
        errors.add(
          SduiValidationError(
            path: path,
            message:
                'Node is missing the required "version" field (required in sdui_version 2.0).',
            code: 'MISSING_NODE_VERSION',
          ),
        );
      }
    } else if (version is! int && version is! double) {
      errors.add(
        SduiValidationError(
          path: path,
          message: '"version" must be an integer, got: $version',
          code: 'INVALID_VERSION_TYPE',
        ),
      );
    }

    // Validate props type (both versions).
    final props = node['props'];
    if (props != null && props is! Map) {
      errors.add(
        SduiValidationError(
          path: path,
          message: '"props" must be a JSON object, got: ${props.runtimeType}',
          code: 'INVALID_PROPS_TYPE',
        ),
      );
    }

    // Validate actions type and contents (both versions).
    final actions = node['actions'];
    if (actions != null && actions is! Map) {
      errors.add(
        SduiValidationError(
          path: path,
          message:
              '"actions" must be a JSON object, got: ${actions.runtimeType}',
          code: 'INVALID_ACTIONS_TYPE',
        ),
      );
    } else if (actions is Map) {
      for (final entry in actions.entries) {
        final actionVal = entry.value;
        if (actionVal is Map) {
          if (!actionVal.containsKey('type')) {
            errors.add(
              SduiValidationError(
                path: '$path/actions/${entry.key}',
                message: 'Action is missing required "type" field.',
                code: 'MISSING_ACTION_TYPE',
              ),
            );
          }
          if (!actionVal.containsKey('event')) {
            errors.add(
              SduiValidationError(
                path: '$path/actions/${entry.key}',
                message: 'Action is missing required "event" field.',
                code: 'MISSING_ACTION_EVENT',
              ),
            );
          }
        }
      }
    }

    final children = node['children'];
    if (children != null && children is! List) {
      errors.add(
        SduiValidationError(
          path: path,
          message: '"children" must be an array, got: ${children.runtimeType}',
          code: 'INVALID_CHILDREN_TYPE',
        ),
      );
    } else if (children is List) {
      for (var i = 0; i < children.length; i++) {
        final child = children[i];
        if (child is Map) {
          _validateNode(
            Map<String, Object?>.from(child),
            '$path/$i',
            errors,
            warnings,
            seenIds,
            isV2: isV2,
          );
        } else {
          errors.add(
            SduiValidationError(
              path: '$path/children[$i]',
              message: 'Child must be a JSON object.',
              code: 'INVALID_CHILD_TYPE',
            ),
          );
        }
      }
    }
  }
}
