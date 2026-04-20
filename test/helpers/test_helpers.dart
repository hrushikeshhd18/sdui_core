import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

// ---------------------------------------------------------------------------
// Canonical test payloads
// ---------------------------------------------------------------------------

/// Minimal valid SDUI payload — column root, no children.
const kMinimalPayload = <String, Object?>{
  'sdui_version': '1.0',
  'root': <String, Object?>{
    'type': 'sdui:column',
    'id': 'root',
    'version': 1,
    'props': <String, Object?>{},
    'actions': <String, Object?>{},
    'children': <Object?>[],
  },
};

/// Payload with a single text leaf.
const kTextPayload = <String, Object?>{
  'sdui_version': '1.0',
  'root': <String, Object?>{
    'type': 'sdui:text',
    'id': 'txt1',
    'version': 1,
    'props': <String, Object?>{'text': 'Hello sdui_core'},
    'actions': <String, Object?>{},
  },
};

/// Three-level deep payload.
const kNestedPayload = <String, Object?>{
  'sdui_version': '1.0',
  'root': <String, Object?>{
    'type': 'sdui:column',
    'id': 'col',
    'version': 1,
    'props': <String, Object?>{},
    'actions': <String, Object?>{},
    'children': <Object?>[
      <String, Object?>{
        'type': 'sdui:row',
        'id': 'row1',
        'version': 1,
        'props': <String, Object?>{},
        'actions': <String, Object?>{},
        'children': <Object?>[
          <String, Object?>{
            'type': 'sdui:text',
            'id': 'deep_txt',
            'version': 2,
            'props': <String, Object?>{'text': 'Deep'},
            'actions': <String, Object?>{},
          },
        ],
      },
    ],
  },
};

/// 2×2 grid payload.
const kGridPayload = <String, Object?>{
  'sdui_version': '1.0',
  'root': <String, Object?>{
    'type': 'sdui:grid',
    'id': 'grid',
    'version': 1,
    'props': <String, Object?>{'columns': 2, 'spacing': 8, 'aspectRatio': 1.0},
    'actions': <String, Object?>{},
    'children': <Object?>[
      <String, Object?>{
        'type': 'sdui:text',
        'id': 'g1',
        'version': 1,
        'props': <String, Object?>{'text': 'Cell 1'},
        'actions': <String, Object?>{},
      },
      <String, Object?>{
        'type': 'sdui:text',
        'id': 'g2',
        'version': 1,
        'props': <String, Object?>{'text': 'Cell 2'},
        'actions': <String, Object?>{},
      },
      <String, Object?>{
        'type': 'sdui:text',
        'id': 'g3',
        'version': 1,
        'props': <String, Object?>{'text': 'Cell 3'},
        'actions': <String, Object?>{},
      },
      <String, Object?>{
        'type': 'sdui:text',
        'id': 'g4',
        'version': 1,
        'props': <String, Object?>{'text': 'Cell 4'},
        'actions': <String, Object?>{},
      },
    ],
  },
};

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// Creates a [SduiBuildContext] pre-wired for testing.
SduiBuildContext testBuildContext(
  BuildContext flutterCtx, {
  SduiWidgetRegistry? registry,
  SduiActionRegistry? actionRegistry,
}) =>
    SduiBuildContext(
      flutterContext: flutterCtx,
      registry:
          registry ?? (SduiWidgetRegistry()..registerAll(createCoreWidgets())),
      actionRegistry: actionRegistry ?? SduiActionRegistry(),
      nodePath: 'root',
    );

/// Pumps an [SduiWidget] inside a minimal [MaterialApp] for widget tests.
Future<void> pumpSduiWidget(
  WidgetTester tester,
  SduiNode node, {
  SduiWidgetRegistry? registry,
  SduiActionRegistry? actionRegistry,
}) async {
  final reg =
      registry ?? (SduiWidgetRegistry()..registerAll(createCoreWidgets()));
  final actions = actionRegistry ?? SduiActionRegistry();

  await tester.pumpWidget(
    MaterialApp(
      home: SduiScope(
        registry: reg,
        actionRegistry: actions,
        child: Scaffold(body: SduiWidget(node: node)),
      ),
    ),
  );
}

/// Builds a minimal leaf node for testing.
SduiLeafNode testLeaf({
  String id = 'leaf1',
  String type = 'sdui:text',
  int version = 1,
  Map<String, Object?> props = const {'text': 'Test'},
}) =>
    SduiLeafNode(id: id, type: type, version: version, props: props);
