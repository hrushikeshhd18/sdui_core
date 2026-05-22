import 'package:meta/meta.dart';

/// Migrates SDUI JSON payloads between schema versions.
///
/// The migrator is stateless and never mutates its input — every method
/// returns a new map. Call `SduiParser.validate` on the result separately
/// to confirm the migrated payload is structurally valid.
///
/// ## v1.0 → v2.0 migration
///
/// | Field | v1.0 | v2.0 after migration |
/// |---|---|---|
/// | `sdui_version` | `"1.0"` | `"2.0"` |
/// | Root `metadata` | Absent | `{}` added if missing |
/// | Node `version` | Optional | `0` added if missing |
/// | Node `props` | Optional | `{}` added if missing |
/// | Node `actions` | Optional | `{}` added if missing |
///
/// Migration is idempotent — calling [migrate] on a v2.0 payload returns it
/// unchanged.
///
/// ```dart
/// final v1Payload = {'sdui_version': '1.0', 'root': {'type': 'sdui:text', 'id': 'h'}};
/// final v2Payload = SduiSchemaMigrator.migrate(v1Payload);
/// // v2Payload['sdui_version'] == '2.0'
/// // (v2Payload['root'] as Map)['version'] == 0
/// ```
@immutable
abstract final class SduiSchemaMigrator {
  /// The schema version this migrator targets.
  static const String latestVersion = '2.0';

  /// All schema versions the migrator can read.
  static const List<String> readableVersions = ['1.0', '2.0'];

  /// Returns the `sdui_version` string from [payload], or `null` if absent.
  static String? schemaVersion(Map<String, Object?> payload) =>
      payload['sdui_version'] as String?;

  /// Returns `true` when [payload] uses an older schema version than
  /// [latestVersion].
  ///
  /// Returns `false` if the version is already latest or not present.
  static bool needsMigration(Map<String, Object?> payload) {
    final version = schemaVersion(payload);
    return version != null && version != latestVersion;
  }

  /// Migrates [payload] to the [latestVersion] schema.
  ///
  /// Returns the original map reference unchanged when already at the latest
  /// version. For all other versions a fresh map is returned.
  ///
  /// Throws [ArgumentError] when `sdui_version` is absent or unrecognised.
  static Map<String, Object?> migrate(Map<String, Object?> payload) {
    final version = schemaVersion(payload);
    if (version == null) {
      throw ArgumentError.value(
        payload,
        'payload',
        'Missing "sdui_version" field — cannot determine migration path.',
      );
    }
    switch (version) {
      case '1.0':
        return _migrateV1ToV2(payload);
      case '2.0':
        return payload;
      default:
        throw ArgumentError.value(
          version,
          'sdui_version',
          'Unknown schema version "$version". '
              'Readable versions: ${readableVersions.join(', ')}.',
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  static Map<String, Object?> _migrateV1ToV2(
    Map<String, Object?> payload,
  ) {
    final rawRoot = payload['root'];
    final migratedRoot = rawRoot is Map
        ? _migrateNode(Map<String, Object?>.from(rawRoot))
        : rawRoot;

    return <String, Object?>{
      ...payload,
      'sdui_version': latestVersion,
      if (!payload.containsKey('metadata'))
        'metadata': const <String, Object?>{},
      'root': migratedRoot,
    };
  }

  static Map<String, Object?> _migrateNode(Map<String, Object?> node) {
    final migrated = <String, Object?>{
      ...node,
      if (!node.containsKey('version')) 'version': 0,
      if (!node.containsKey('props')) 'props': const <String, Object?>{},
      if (!node.containsKey('actions')) 'actions': const <String, Object?>{},
    };

    final rawChildren = node['children'];
    if (rawChildren is List) {
      migrated['children'] = rawChildren.map((child) {
        if (child is Map) return _migrateNode(Map<String, Object?>.from(child));
        return child;
      }).toList(growable: false);
    }

    return migrated;
  }
}
