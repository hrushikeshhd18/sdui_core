/// A production-grade Server-Driven UI engine for Flutter.
///
/// `sdui_core` renders dynamic, state-aware layouts from plain JSON payloads
/// at runtime — no WebView, no code generation, no App Store review for UI
/// changes.
///
/// ## Core concepts
///
/// | Class | Responsibility |
/// |---|---|
/// | `SduiScreen` | Fetch → validate → parse → cache → diff → render lifecycle |
/// | `SduiWidgetRegistry` | Maps type strings to Flutter widget builders |
/// | `SduiActionRegistry` | Maps event names to async action handlers |
/// | `SduiTransport` | Pluggable fetch layer (HTTP, WebSocket, or custom) |
/// | `SduiCache` | Stale-while-revalidate cache backed by SharedPreferences |
/// | `SduiDiffer` | Incremental tree diff by `id + version` |
/// | `SduiParser` | JSON → `SduiNode` tree, optionally on a background isolate |
/// | `SduiValidator` | Full-tree structural validation before parsing |
/// | `SduiProps` | Type-safe prop accessor wrapping `Map<String, Object?>` |
/// | `SduiTheme` | Named `TextStyle` registry for server-controlled typography |
/// | `SduiDebugOverlay` | Long-press node inspector (debug builds only) |
///
/// ## Quick start
///
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await SduiCache.init(); // enables stale-while-revalidate persistence
///
///   runApp(
///     SduiScope(
///       child: MaterialApp(
///         home: SduiScreen(url: 'https://api.example.com/layouts/home'),
///       ),
///     ),
///   );
/// }
/// ```
///
/// ## Registering custom widgets
///
/// ```dart
/// final registry = SduiWidgetRegistry()
///   ..registerAll(createCoreWidgets())
///   ..register('myapp:banner', (node, ctx) {
///     final p = SduiProps(node.props);
///     return Container(
///       color: p.getColor('color', fallback: Colors.blue),
///       child: Text(p.getString('title')),
///     );
///   });
/// ```
///
/// ## Registering custom actions
///
/// ```dart
/// final actionRegistry = SduiActionRegistry()
///   ..register('add_to_cart', (action, ctx) async {
///     await CartRepository.instance.add(action.payload['productId'] as String);
///     return const SduiActionResult.success();
///   });
/// ```
///
/// ## Exception codes
///
/// Every exception is sealed and carries a `code` string:
///
/// - `SDUI_001` — `SduiParseException`: JSON structure is invalid.
/// - `SDUI_002` — `SduiVersionException`: unsupported `sdui_version`.
/// - `SDUI_003` — `SduiNetworkException`: network failure after all retries.
/// - `SDUI_004` — `SduiUnknownWidgetException`: no builder for widget type.
/// - `SDUI_005` — `SduiActionException`: no handler for action event.
/// - `SDUI_006` — `SduiCacheException`: cache read/write failure.
library sdui_core;

// Cache
export 'src/cache/sdui_cache.dart';
// Controller — state machine + SduiScreenState enum
export 'src/controller/sdui_controller.dart';
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
export 'src/widgets/sdui_bindings.dart';
export 'src/widgets/sdui_debug_overlay.dart';
export 'src/widgets/sdui_scope.dart';
export 'src/widgets/sdui_screen.dart' hide SduiScreenState;
export 'src/widgets/sdui_theme.dart';
export 'src/widgets/sdui_widget.dart';
