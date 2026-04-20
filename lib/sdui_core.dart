/// sdui_core — A high-performance Server-Driven UI engine for Flutter.
///
/// Render dynamic, state-aware layouts from plain JSON payloads with zero
/// boilerplate and native Bloc/Riverpod integration.
///
/// ## Quick start
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///
///   // Optional: initialise the stale-while-revalidate cache.
///   await SduiCache.init();
///
///   // Register built-in widgets.
///   SduiWidgetRegistry.defaults.registerAll(createCoreWidgets());
///
///   runApp(const MyApp());
/// }
///
/// // Minimum usage — one widget, one URL.
/// SduiScreen(url: 'https://api.example.com/layouts/home')
/// ```
library sdui_core;

// Cache
export 'src/cache/sdui_cache.dart';
// Exceptions
export 'src/exceptions/sdui_exceptions.dart';
// Extensions
export 'src/extensions/color_extension.dart';
export 'src/extensions/context_extension.dart';
// Models
export 'src/models/sdui_action.dart';
export 'src/models/sdui_node.dart';
export 'src/models/sdui_props.dart';
// Parser
export 'src/parser/sdui_parser.dart';
export 'src/parser/sdui_validator.dart';
// Registry
export 'src/registry/action_registry.dart';
export 'src/registry/widget_registry.dart';
// Renderer
export 'src/renderer/key_manager.dart';
export 'src/renderer/sdui_differ.dart';
export 'src/renderer/sdui_renderer.dart';
// Transport
export 'src/transport/http_transport.dart';
export 'src/transport/sdui_transport.dart';
export 'src/transport/ws_transport.dart';
// Utilities
export 'src/utils/sdui_icons.dart';
export 'src/utils/sdui_logger.dart';
// Built-in widget builders
export 'src/widgets/builders/core_widgets.dart';
export 'src/widgets/builders/cupertino_widgets.dart';
export 'src/widgets/builders/material_widgets.dart';
// Widgets (public API)
export 'src/widgets/sdui_debug_overlay.dart';
export 'src/widgets/sdui_scope.dart';
export 'src/widgets/sdui_screen.dart';
export 'src/widgets/sdui_theme.dart';
export 'src/widgets/sdui_widget.dart';
