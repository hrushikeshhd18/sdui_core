import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('SduiValidator — version checks', () {
    test('valid payload returns isValid true', () {
      final result = SduiValidator.validate(kMinimalPayload);
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('missing sdui_version emits MISSING_VERSION', () {
      final result = SduiValidator.validate({
        'root': {'type': 'sdui:text', 'id': 'x'},
      });
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'MISSING_VERSION'), isTrue);
    });

    test('unsupported sdui_version emits INVALID_VERSION', () {
      final result = SduiValidator.validate({
        'sdui_version': '99.0',
        'root': {'type': 'sdui:text', 'id': 'x'},
      });
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'INVALID_VERSION'), isTrue);
    });

    test('custom supported versions are respected', () {
      final result = SduiValidator.validate(
        {
          'sdui_version': '2.0',
          'root': {
            'type': 'sdui:text',
            'id': 'x',
            'version': 1, // required in v2
            'props': {},
            'actions': {},
          },
        },
        supportedVersions: ['2.0'],
      );
      expect(result.isValid, isTrue);
    });
  });

  group('SduiValidator — node field checks', () {
    test('missing type emits MISSING_TYPE', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {'id': 'x', 'version': 1},
      });
      expect(result.errors.any((e) => e.code == 'MISSING_TYPE'), isTrue);
    });

    test('missing id emits MISSING_ID', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {'type': 'sdui:text', 'version': 1},
      });
      expect(result.errors.any((e) => e.code == 'MISSING_ID'), isTrue);
    });

    test('invalid version type emits INVALID_VERSION_TYPE', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {'type': 'sdui:text', 'id': 'x', 'version': 'not_int'},
      });
      expect(
        result.errors.any((e) => e.code == 'INVALID_VERSION_TYPE'),
        isTrue,
      );
    });

    test('id with spaces emits a warning', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {'type': 'sdui:text', 'id': 'my id', 'version': 1},
      });
      expect(result.isValid, isTrue);
      expect(result.warnings, isNotEmpty);
    });
  });

  group('SduiValidator — duplicate id detection', () {
    test('duplicate id across parent and child emits DUPLICATE_ID', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:column',
          'id': 'col',
          'version': 1,
          'children': [
            {'type': 'sdui:text', 'id': 'col', 'version': 1},
          ],
        },
      });
      expect(result.errors.any((e) => e.code == 'DUPLICATE_ID'), isTrue);
    });

    test('unique ids across siblings are valid', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:column',
          'id': 'col',
          'version': 1,
          'children': [
            {'type': 'sdui:text', 'id': 'c1', 'version': 1},
            {'type': 'sdui:text', 'id': 'c2', 'version': 1},
          ],
        },
      });
      expect(result.isValid, isTrue);
    });
  });

  group('SduiValidator — action validation', () {
    test('action missing type emits MISSING_ACTION_TYPE', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:text',
          'id': 'x',
          'version': 1,
          'actions': {
            'onTap': {'event': 'go_home'},
          },
        },
      });
      expect(result.errors.any((e) => e.code == 'MISSING_ACTION_TYPE'), isTrue);
    });

    test('action missing event emits MISSING_ACTION_EVENT', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:text',
          'id': 'x',
          'version': 1,
          'actions': {
            'onTap': {'type': 'navigate'},
          },
        },
      });
      expect(
        result.errors.any((e) => e.code == 'MISSING_ACTION_EVENT'),
        isTrue,
      );
    });

    test('valid action passes without errors', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:text',
          'id': 'x',
          'version': 1,
          'actions': {
            'onTap': {'type': 'navigate', 'event': 'go_home'},
          },
        },
      });
      expect(result.isValid, isTrue);
    });
  });

  group('SduiValidator — children validation', () {
    test('invalid children type emits INVALID_CHILDREN_TYPE', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:column',
          'id': 'col',
          'version': 1,
          'children': 'not_a_list',
        },
      });
      expect(
        result.errors.any((e) => e.code == 'INVALID_CHILDREN_TYPE'),
        isTrue,
      );
    });

    test('non-object child emits INVALID_CHILD_TYPE', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:column',
          'id': 'col',
          'version': 1,
          'children': [42],
        },
      });
      expect(result.errors.any((e) => e.code == 'INVALID_CHILD_TYPE'), isTrue);
    });
  });

  group('SduiValidator — result structure', () {
    test('toString includes error and warning counts', () {
      final result = SduiValidator.validate({'root': {}});
      expect(result.toString(), contains('errors'));
    });

    test('SduiValidationError toString includes code and path', () {
      const err = SduiValidationError(
        path: 'root/child',
        message: 'Test error',
        code: 'TEST_CODE',
      );
      expect(err.toString(), contains('TEST_CODE'));
      expect(err.toString(), contains('root/child'));
    });
  });

  group('SduiValidator — props/actions type checks', () {
    test('non-map props emits INVALID_PROPS_TYPE', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:text',
          'id': 'x',
          'version': 1,
          'props': 'not_a_map',
        },
      });
      expect(result.errors.any((e) => e.code == 'INVALID_PROPS_TYPE'), isTrue);
    });

    test('non-map actions emits INVALID_ACTIONS_TYPE', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:text',
          'id': 'x',
          'version': 1,
          'actions': 'not_a_map',
        },
      });
      expect(
        result.errors.any((e) => e.code == 'INVALID_ACTIONS_TYPE'),
        isTrue,
      );
    });

    test('valid props and actions pass without errors', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:text',
          'id': 'x',
          'version': 1,
          'props': {'text': 'hi'},
          'actions': {},
        },
      });
      expect(result.isValid, isTrue);
    });
  });

  group('SduiValidator — v2.0 schema', () {
    test('valid v2.0 payload passes', () {
      final result = SduiValidator.validate({
        'sdui_version': '2.0',
        'metadata': {'experiment': 'control'},
        'root': {
          'type': 'sdui:text',
          'id': 'txt',
          'version': 1,
          'props': {'text': 'Hello'},
          'actions': {},
        },
      });
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('v2.0 node missing version emits MISSING_NODE_VERSION', () {
      final result = SduiValidator.validate({
        'sdui_version': '2.0',
        'root': {
          'type': 'sdui:text',
          'id': 'txt',
          // no version
          'props': {},
          'actions': {},
        },
      });
      expect(result.isValid, isFalse);
      expect(
        result.errors.any((e) => e.code == 'MISSING_NODE_VERSION'),
        isTrue,
      );
    });

    test('v2.0 child node missing version emits MISSING_NODE_VERSION', () {
      final result = SduiValidator.validate({
        'sdui_version': '2.0',
        'root': {
          'type': 'sdui:column',
          'id': 'col',
          'version': 1,
          'props': {},
          'actions': {},
          'children': [
            {
              'type': 'sdui:text',
              'id': 'child',
              // no version on child
              'props': {},
              'actions': {},
            },
          ],
        },
      });
      expect(
        result.errors.any((e) => e.code == 'MISSING_NODE_VERSION'),
        isTrue,
      );
    });

    test('v1.0 node missing version does NOT emit MISSING_NODE_VERSION', () {
      final result = SduiValidator.validate({
        'sdui_version': '1.0',
        'root': {
          'type': 'sdui:text',
          'id': 'txt',
          // no version — valid in v1
          'props': {},
          'actions': {},
        },
      });
      expect(result.isValid, isTrue);
      expect(
        result.errors.any((e) => e.code == 'MISSING_NODE_VERSION'),
        isFalse,
      );
    });

    test('v2.0 root metadata that is not a map emits a warning', () {
      final result = SduiValidator.validate({
        'sdui_version': '2.0',
        'metadata': 'invalid',
        'root': {
          'type': 'sdui:text',
          'id': 'txt',
          'version': 1,
          'props': {},
          'actions': {},
        },
      });
      expect(result.isValid, isTrue); // warning, not error
      expect(result.warnings, isNotEmpty);
    });

    test('v2.0 without metadata is still valid (metadata is optional)', () {
      final result = SduiValidator.validate({
        'sdui_version': '2.0',
        'root': {
          'type': 'sdui:text',
          'id': 'txt',
          'version': 1,
          'props': {},
          'actions': {},
        },
      });
      expect(result.isValid, isTrue);
    });

    test('v2.0 reported as unsupported when not in supportedVersions list', () {
      final result = SduiValidator.validate(
        {
          'sdui_version': '2.0',
          'root': {'type': 'sdui:text', 'id': 'x', 'version': 1},
        },
        supportedVersions: ['1.0'],
      );
      expect(result.isValid, isFalse);
      expect(result.errors.any((e) => e.code == 'INVALID_VERSION'), isTrue);
    });
  });
}
