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

// Models
export 'src/models/sdui_action.dart';
export 'src/models/sdui_node.dart';
export 'src/models/sdui_props.dart';

// Registry
export 'src/registry/action_registry.dart';
export 'src/registry/widget_registry.dart';

// Parser
export 'src/parser/sdui_parser.dart';
export 'src/parser/sdui_validator.dart';

// Renderer
export 'src/renderer/key_manager.dart';
export 'src/renderer/sdui_differ.dart';
export 'src/renderer/sdui_renderer.dart';

// Transport
export 'src/transport/http_transport.dart';
export 'src/transport/sdui_transport.dart';
export 'src/transport/ws_transport.dart';

// Cache
export 'src/cache/sdui_cache.dart';

// Widgets (public API)
export 'src/widgets/sdui_scope.dart';
export 'src/widgets/sdui_screen.dart';
export 'src/widgets/sdui_widget.dart';

// Built-in widget builders
export 'src/widgets/builders/core_widgets.dart';
export 'src/widgets/builders/cupertino_widgets.dart';
export 'src/widgets/builders/material_widgets.dart';

// Extensions
export 'src/extensions/color_extension.dart';
export 'src/extensions/context_extension.dart';

// Utilities
export 'src/utils/sdui_icons.dart';
export 'src/utils/sdui_logger.dart';

// Exceptions
export 'src/exceptions/sdui_exceptions.dart';
