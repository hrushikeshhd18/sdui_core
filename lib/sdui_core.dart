/// sdui_core — A high-performance Server-Driven UI engine for Flutter.
///
/// Render dynamic, state-aware layouts from JSON payloads with zero boilerplate.
///
/// Quick start:
/// ```dart
/// // 1. Register built-in widgets once (e.g. in main).
/// SduiWidgetRegistry.instance.registerAll(createCoreWidgets());
///
/// // 2. Drop the screen into your widget tree.
/// SduiScreen(url: 'https://api.example.com/layouts/home')
/// ```
library sdui_core;

// Models
export 'src/models/sdui_node.dart';
export 'src/models/sdui_action.dart';

// Registry
export 'src/registry/widget_registry.dart';
export 'src/registry/action_registry.dart';

// Parser
export 'src/parser/sdui_parser.dart';

// Renderer
export 'src/renderer/sdui_renderer.dart';
export 'src/renderer/key_manager.dart';

// Widgets (public API)
export 'src/widgets/sdui_scope.dart';
export 'src/widgets/sdui_screen.dart';

// Built-in widgets
export 'src/widgets/builders/core_widgets.dart';

// Exceptions
export 'src/exceptions/sdui_exceptions.dart';
