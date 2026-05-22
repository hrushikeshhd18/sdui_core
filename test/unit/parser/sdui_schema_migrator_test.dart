import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

const _kV1Minimal = <String, Object?>{
  'sdui_version': '1.0',
  'root': <String, Object?>{
    'type': 'sdui:text',
    'id': 'txt',
    'version': 1,
    'props': <String, Object?>{'text': 'Hello'},
    'actions': <String, Object?>{},
  },
};

const _kV1NoVersion = <String, Object?>{
  'sdui_version': '1.0',
  'root': <String, Object?>{
    'type': 'sdui:text',
    'id': 'txt',
    // no version field
    'props': <String, Object?>{'text': 'Hello'},
    'actions': <String, Object?>{},
  },
};

const _kV1Nested = <String, Object?>{
  'sdui_version': '1.0',
  'root': <String, Object?>{
    'type': 'sdui:column',
    'id': 'col',
    // no version
    'children': <Object?>[
      <String, Object?>{
        'type': 'sdui:text',
        'id': 'child_txt',
        // no version, no props, no actions
      },
    ],
  },
};

const _kV2Already = <String, Object?>{
  'sdui_version': '2.0',
  'metadata': <String, Object?>{'experiment': 'control'},
  'root': <String, Object?>{
    'type': 'sdui:text',
    'id': 'txt',
    'version': 1,
    'props': <String, Object?>{},
    'actions': <String, Object?>{},
  },
};

void main() {
  group('SduiSchemaMigrator.schemaVersion', () {
    test('returns version string when present', () {
      expect(SduiSchemaMigrator.schemaVersion(_kV1Minimal), '1.0');
      expect(SduiSchemaMigrator.schemaVersion(_kV2Already), '2.0');
    });

    test('returns null when sdui_version is absent', () {
      expect(SduiSchemaMigrator.schemaVersion({}), isNull);
    });
  });

  group('SduiSchemaMigrator.needsMigration', () {
    test('returns true for v1.0 payload', () {
      expect(SduiSchemaMigrator.needsMigration(_kV1Minimal), isTrue);
    });

    test('returns false for v2.0 payload', () {
      expect(SduiSchemaMigrator.needsMigration(_kV2Already), isFalse);
    });

    test('returns false when sdui_version is absent', () {
      expect(SduiSchemaMigrator.needsMigration({}), isFalse);
    });
  });

  group('SduiSchemaMigrator.migrate — v1 → v2', () {
    test('bumps sdui_version to 2.0', () {
      final result = SduiSchemaMigrator.migrate(_kV1Minimal);
      expect(result['sdui_version'], '2.0');
    });

    test('adds empty metadata when absent', () {
      final result = SduiSchemaMigrator.migrate(_kV1Minimal);
      expect(result.containsKey('metadata'), isTrue);
      expect(result['metadata'], isA<Map>());
    });

    test('preserves existing metadata when present', () {
      final v1WithMeta = <String, Object?>{
        ..._kV1Minimal,
        'metadata': <String, Object?>{'custom': 'value'},
      };
      final result = SduiSchemaMigrator.migrate(v1WithMeta);
      expect((result['metadata'] as Map)['custom'], 'value');
    });

    test('defaults missing node version to 0', () {
      final result = SduiSchemaMigrator.migrate(_kV1NoVersion);
      final root = result['root'] as Map;
      expect(root['version'], 0);
    });

    test('preserves existing node version', () {
      final result = SduiSchemaMigrator.migrate(_kV1Minimal);
      final root = result['root'] as Map;
      expect(root['version'], 1);
    });

    test('adds empty props when absent', () {
      final result = SduiSchemaMigrator.migrate(_kV1Nested);
      final col = result['root'] as Map;
      expect(col.containsKey('props'), isTrue);
      expect(col['props'], isA<Map>());
    });

    test('adds empty actions when absent', () {
      final result = SduiSchemaMigrator.migrate(_kV1Nested);
      final col = result['root'] as Map;
      expect(col.containsKey('actions'), isTrue);
      expect(col['actions'], isA<Map>());
    });

    test('migrates nested children recursively', () {
      final result = SduiSchemaMigrator.migrate(_kV1Nested);
      final col = result['root'] as Map;
      final children = col['children'] as List;
      final child = children.first as Map;
      expect(child['version'], 0);
      expect(child['props'], isA<Map>());
      expect(child['actions'], isA<Map>());
    });

    test('does not mutate the original payload', () {
      final original = Map<String, Object?>.from(_kV1NoVersion);
      SduiSchemaMigrator.migrate(original);
      final root = original['root'] as Map;
      expect(root.containsKey('version'), isFalse);
    });

    test('migrated payload passes SduiParser.validate with v2 rules', () {
      final migrated = SduiSchemaMigrator.migrate(_kV1Nested);
      final result = SduiParser.validate(migrated);
      expect(result.isValid, isTrue);
    });
  });

  group('SduiSchemaMigrator.migrate — v2 idempotency', () {
    test('returns the same map reference for v2.0 payload', () {
      final result = SduiSchemaMigrator.migrate(_kV2Already);
      expect(identical(result, _kV2Already), isTrue);
    });
  });

  group('SduiSchemaMigrator.migrate — error cases', () {
    test('throws ArgumentError for missing sdui_version', () {
      expect(
        () => SduiSchemaMigrator.migrate({'root': {}}),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws ArgumentError for unknown schema version', () {
      expect(
        () => SduiSchemaMigrator.migrate({
          'sdui_version': '99.0',
          'root': {},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SduiSchemaMigrator constants', () {
    test('latestVersion is 2.0', () {
      expect(SduiSchemaMigrator.latestVersion, '2.0');
    });

    test('readableVersions contains v1.0 and v2.0', () {
      expect(SduiSchemaMigrator.readableVersions, containsAll(['1.0', '2.0']));
    });
  });
}
