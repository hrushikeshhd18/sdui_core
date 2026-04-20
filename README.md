<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/logo.png" alt="sdui_core" height="120" />
</p>

<p align="center">
  <a href="https://pub.dev/packages/sdui_core"><img src="https://img.shields.io/pub/v/sdui_core.svg" alt="pub version"></a>
  <a href="https://github.com/hrushikeshhd18/sdui_core/actions"><img src="https://github.com/hrushikeshhd18/sdui_core/actions/workflows/ci.yml/badge.svg" alt="build"></a>
  <a href="https://codecov.io/gh/hrushikeshhd18/sdui_core"><img src="https://codecov.io/gh/hrushikeshhd18/sdui_core/branch/main/graph/badge.svg" alt="codecov"></a>
  <a href="https://github.com/hrushikeshhd18/sdui_core/stargazers"><img src="https://img.shields.io/github/stars/hrushikeshhd18/sdui_core.svg?style=flat&logo=github&colorB=deeppink&label=stars" alt="stars"></a>
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Platform-Flutter-02569B?logo=flutter" alt="Flutter Platform"></a>
  <a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-purple.svg" alt="License: MIT"></a>
</p>

---

A production-grade **Server-Driven UI** engine for Flutter. Render dynamic, state-aware layouts from plain JSON payloads at runtime — no WebView, no code generation, no App Store review for UI changes.

**Learn more at [github.com/hrushikeshhd18/sdui_core](https://github.com/hrushikeshhd18/sdui_core)**

---

## Overview

In a traditional Flutter app, every UI change requires a native release cycle: code, build, review, rollout, and then wait for users to update. `sdui_core` breaks that cycle.

Your backend emits a JSON document that describes the layout. `sdui_core` fetches it, validates it, parses it off the UI thread, caches it, diffs it against the current tree, and renders a fully native Flutter widget tree — all automatically.

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/architecture.png" alt="sdui_core Architecture" width="800" />
</p>

**The full lifecycle:**

```
JSON payload (server)
       │
       ▼
 SduiTransport        ← HTTP with retry / WebSocket with auto-reconnect
       │
       ▼
 SduiValidator        ← full-tree validation before parse (structured error codes)
       │
       ▼
 SduiParser           ← decodes JSON on a background isolate
       │
       ├──► SduiCache ← stale-while-revalidate (SharedPreferences)
       │
       ▼
 SduiDiffer           ← compares new tree to current tree by id + version
       │
       ▼
 SduiRenderer         ← resolves builders, evaluates visible_if, wraps keys
       │
       ▼
 Native Flutter widget tree
       │
       ▼
 SduiActionRegistry   ← dispatches gestures through middleware to handlers
```

**When it pays off:**
- Ship UI changes in minutes, not App Store review cycles
- A/B test layouts server-side without a native release
- Feature flags that control visibility at the node level
- White-label the same app shell with different layouts per client
- Fix a production UI bug without waiting for users to update

---

## Installation

```yaml
dependencies:
  sdui_core: ^0.2.0
```

```sh
flutter pub get
```

---

## Quick start

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SduiCache.init(); // one-time cache initialisation

  runApp(
    SduiScope(
      child: MaterialApp(
        home: SduiScreen(url: 'https://api.example.com/layouts/home'),
      ),
    ),
  );
}
```

`SduiScope` exposes the default registries (28 core widgets pre-registered) to the entire widget tree.  
`SduiScreen` runs the full fetch → validate → parse → cache → diff → render lifecycle automatically.

---

## JSON payload

Every node carries four fields: `id` (stable diffing key), `version` (bump to force rebuild), `props` (widget config), and `actions` (gesture handlers).

```json
{
  "sdui_version": "1.0",
  "root": {
    "type": "sdui:column",
    "id": "home_root",
    "version": 3,
    "props": { "padding": 16 },
    "actions": {},
    "children": [
      {
        "type": "sdui:text",
        "id": "headline",
        "version": 1,
        "props": { "text": "Welcome back, Alex", "style": "h1", "color": "#1A1A2E" },
        "actions": {}
      },
      {
        "type": "sdui:button",
        "id": "cta",
        "version": 2,
        "props": { "label": "Shop the sale", "variant": "filled", "visible_if": "props.isSaleActive" },
        "actions": {
          "onTap": { "type": "navigate", "event": "open_sale", "payload": { "route": "/sale" } }
        }
      }
    ]
  }
}
```

> `visible_if` — resolved against the node's own props before any builder runs. Set `"isSaleActive": false` server-side to hide the button. No native release needed.

---

## SduiScreen

`SduiScreen` is a 7-state machine: `loading` → `loadingWithCache` → `success` → `refreshing` → `error` → `errorWithCache` → `empty`.

```dart
SduiScreen(
  url: 'https://api.example.com/layouts/home',

  // Auth
  headers: {'Authorization': 'Bearer $token'},

  // Transport — default: HttpSduiTransport (retry + back-off)
  // Swap for WebSocket live updates:
  // transport: WebSocketSduiTransport(),

  // Cache: serves stale layout instantly while fresh data loads (default: true)
  enableCache: true,

  // Parses JSON on a background isolate (default: true)
  parseInIsolate: true,

  // Gestures
  pullToRefresh: true,
  refreshInterval: const Duration(minutes: 10),

  // Custom states
  loadingBuilder: (_) => const MySkeletonScreen(),
  errorBuilder: (_, error) => MyErrorWidget(error: error),
  emptyBuilder: (_) => const MyEmptyState(),

  // Lifecycle
  onLoad: () => analytics.track('screen_ready'),
  onRefresh: () => analytics.track('pull_to_refresh'),
  onError: (e) => crashReporter.capture(e),

  // Analytics — fires for every action regardless of handler
  onEvent: (event, payload) => analytics.track(event, payload),
)
```

### Creating a SduiScreen

The minimum is a URL. Every other parameter is opt-in.

```dart
SduiScreen(url: 'https://api.example.com/layouts/home')
```

### Observing events

`onEvent` fires for every action dispatched anywhere in the tree — use it to wire analytics once at the screen level rather than inside every action handler.

```dart
SduiScreen(
  url: '...',
  onEvent: (event, payload) {
    // Fires for navigate, dispatch, show_snackbar — everything
    FirebaseAnalytics.instance.logEvent(name: event, parameters: payload);
  },
)
```

### Live updates over WebSocket

```dart
SduiScreen(
  url: 'wss://api.example.com/layouts/dashboard/live',
  transport: WebSocketSduiTransport(
    reconnectDelay: const Duration(seconds: 3),
    maxReconnectAttempts: 10,
    pingInterval: const Duration(seconds: 25),
  ),
  enableCache: false,
)
```

The server pushes a new JSON payload on every change. `SduiDiffer` compares by `id + version` and rebuilds only the changed nodes.

---

## SduiWidgetRegistry

`SduiWidgetRegistry` maps type strings to Flutter widget builders. Unlike a singleton, each instance is fully isolated — safe to use per-test.

### Registering widgets

```dart
final registry = SduiWidgetRegistry()
  ..registerAll(createCoreWidgets())
  ..registerAll(createMaterialWidgets())
  ..register('myapp:product_card', _buildProductCard)
  ..register('myapp:rating_bar', _buildRatingBar);
```

### Creating a custom builder

```dart
Widget _buildProductCard(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return ProductCard(
    title: p.getString('title'),
    price: p.getDouble('price'),
    imageUrl: p.getString('imageUrl'),
    badge: p.getStringOrNull('badge'),        // null → no badge
    rating: p.getDouble('rating', fallback: 0),
    onTap: () => _fireAction('onTap', node, ctx),
  );
}
```

`SduiProps` replaces raw `Map` access with typed helpers: `getString`, `getBool`, `getDouble`, `getInt`, `getColor`, `getEdgeInsets`, `getAlignment`, and more.

### Namespace wildcard

Register one builder for every type in a namespace:

```dart
registry.registerNamespaceWildcard('myapp', _myFallbackBuilder);
// Matches myapp:anything not explicitly registered
```

---

## SduiActionRegistry

`SduiActionRegistry` maps event names to async handlers. Every action also passes through the middleware chain before reaching its handler.

### Registering a handler

```dart
final actionRegistry = SduiActionRegistry()
  ..register('add_to_cart', (action, ctx) async {
    final productId = action.payload['productId'] as String;
    await CartRepository.instance.add(productId);
    ScaffoldMessenger.of(ctx.flutterContext)
        .showSnackBar(const SnackBar(content: Text('Added to cart')));
    return const SduiActionResult.success();
  });
```

### Adding middleware

Middleware runs on every action — ideal for logging and analytics.

```dart
actionRegistry.addMiddleware((action, ctx, next) async {
  // Before
  analytics.log(action.event, action.payload);

  final result = await next();   // call the actual handler

  // After
  if (result.isFailure) crashReporter.capture('Action failed: ${action.event}');
  return result;
});
```

Middleware chains compose — add as many as needed. Each must call `next()` to continue.

### Using withEventInterceptor

A convenience shorthand when you only need to observe events without modifying them:

```dart
SduiScope(
  actionRegistry: SduiActionRegistry()
    ..register('open_sale', myHandler)
    ..withEventInterceptor((event, payload) {
      analytics.track(event, payload);
    }),
  child: ...,
)
```

---

## SduiTheme

`SduiTheme` is an `InheritedWidget` that holds a named `TextStyle` registry. The `sdui:text` builder checks it before the built-in Material `TextTheme` mappings — the server can control brand typography by name without a native release.

```dart
SduiTheme(
  styles: {
    'display':    TextStyle(fontSize: 40, fontWeight: FontWeight.w900, height: 1.1),
    'promo':      TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFFE63946)),
    'section':    TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    'fine_print': TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
  },
  child: SduiScope(
    child: MaterialApp(home: SduiScreen(url: '...')),
  ),
)
```

Server JSON references the key directly:

```json
{ "type": "sdui:text", "id": "hero", "version": 1,
  "props": { "text": "Summer Sale", "style": "promo" }, "actions": {} }
```

---

## SduiDiffer

`SduiDiffer` compares two trees by `id + version` and returns changed, added, removed, and moved node sets. Feed `updatedTree` into `setState` — Flutter reconciles only the changed subtrees.

```dart
final diff = SduiDiffer.diff(currentTree, newTree);

if (diff.hasDiffs) {
  debugPrint('${diff.changedCount} changed, ${diff.addedCount} added, '
      '${diff.removedCount} removed, ${diff.movedCount} moved');
  setState(() => _tree = diff.updatedTree);
}
```

---

## SduiDebugOverlay

Enable during development. Long-press any SDUI node to open an inspector panel showing its `id`, `type`, `version`, tree path, prop count, and action count.

```dart
void main() {
  // Stripped from release builds automatically
  assert(() {
    SduiDebugOverlay.enabled = true;
    return true;
  }());

  runApp(const MyApp());
}
```

---

## Testing

Registries are plain objects, not singletons. Create fresh instances per test — no global state pollution between tests.

```dart
void main() {
  group('ProductCard', () {
    late SduiWidgetRegistry registry;
    late SduiActionRegistry actionRegistry;

    setUp(() {
      registry = SduiWidgetRegistry()
        ..registerAll(createCoreWidgets())
        ..register('myapp:product_card', _buildProductCard);

      actionRegistry = SduiActionRegistry()
        ..register('add_to_cart', (_, __) async => const SduiActionResult.success());
    });

    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        SduiScope(
          registry: registry,
          actionRegistry: actionRegistry,
          child: MaterialApp(
            home: Scaffold(
              body: SduiScreen(
                url: 'ignored',
                transport: MockSduiTransport({
                  'sdui_version': '1.0',
                  'root': {
                    'type': 'myapp:product_card',
                    'id': 'p1',
                    'version': 1,
                    'props': {'title': 'Headphones', 'price': 99.99},
                    'actions': {},
                  },
                }),
                enableCache: false,
                parseInIsolate: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Headphones'), findsOneWidget);
    });
  });
}
```

### Observing a SduiScreen in tests

Use `onEvent` to assert that the correct actions fire without coupling to internal state:

```dart
final events = <String>[];

await tester.pumpWidget(
  SduiScreen(
    url: '...',
    transport: MockSduiTransport(myPayload),
    onEvent: events.add,
    enableCache: false,
    parseInIsolate: false,
  ),
);

await tester.tap(find.text('Shop now'));
await tester.pumpAndSettle();

expect(events, contains('open_sale'));
```

---

## Built-in widgets

### Core — `createCoreWidgets()`

| Type | Flutter widget | Key props |
|---|---|---|
| `sdui:text` | `Text` | `text`, `style`, `color`, `fontSize`, `fontWeight`, `maxLines`, `overflow` |
| `sdui:image` | `CachedNetworkImage` | `url`, `fit`, `width`, `height` |
| `sdui:button` | `ElevatedButton` / `OutlinedButton` / `FilledButton` | `label`, `variant`, `icon`, `color` |
| `sdui:icon` | `Icon` | `name`, `size`, `color` |
| `sdui:container` | `Container` | `color`, `padding`, `margin`, `borderRadius`, `width`, `height` |
| `sdui:column` | `Column` | `mainAxisAlignment`, `crossAxisAlignment`, `spacing` |
| `sdui:row` | `Row` | `mainAxisAlignment`, `crossAxisAlignment`, `spacing` |
| `sdui:stack` | `Stack` | `alignment`, `fit` |
| `sdui:grid` | `GridView` | `columns`, `spacing`, `aspectRatio` |
| `sdui:list` | `ListView` | `shrinkWrap`, `scrollDirection`, `separator` |
| `sdui:card` | `Card` | `elevation`, `color`, `borderRadius` |
| `sdui:padding` | `Padding` | `all`, `horizontal`, `vertical`, `top`, `left`, `bottom`, `right` |
| `sdui:center` | `Center` | — |
| `sdui:expanded` | `Expanded` | `flex` |
| `sdui:divider` | `Divider` / `VerticalDivider` | `thickness`, `color` |
| `sdui:spacer` | `Spacer` | `flex` |
| `sdui:visibility` | show / hide | `visible` |
| `sdui:inkwell` | `InkWell` | — |
| `sdui:safe_area` | `SafeArea` | `top`, `bottom`, `left`, `right` |
| `sdui:aspect_ratio` | `AspectRatio` | `ratio` |
| `sdui:fitted_box` | `FittedBox` | `fit`, `alignment` |
| `sdui:clip_r_rect` | `ClipRRect` | `borderRadius` |
| `sdui:opacity` | `AnimatedOpacity` | `opacity`, `duration` |
| `sdui:transform_scale` | `Transform.scale` | `scale`, `alignment` |
| `sdui:hero` | `Hero` | `tag` |
| `sdui:badge` | `Badge` | `label`, `backgroundColor` |
| `sdui:chip` | `ActionChip` / `FilterChip` | `label`, `selected`, `variant` |
| `sdui:placeholder` | `Placeholder` | `color`, `strokeWidth` |

### Material 3 — `createMaterialWidgets()`

`sdui:list_tile` · `sdui:switch_tile` · `sdui:progress` · `sdui:fab` · `sdui:bottom_nav` · `sdui:nav_rail` · `sdui:drawer` · `sdui:app_bar` · `sdui:search_bar` · `sdui:tab_bar` · `sdui:bottom_sheet` · `sdui:dialog`

### Cupertino — `createCupertinoWidgets()`

`sdui:cupertino_button` · `sdui:cupertino_nav_bar` · `sdui:cupertino_list_tile` · `sdui:cupertino_switch` · `sdui:cupertino_slider` · `sdui:cupertino_activity` · `sdui:cupertino_dialog`

---

## Built-in actions

| Type | Behaviour | Required payload |
|---|---|---|
| `navigate` | `Navigator.pushNamed` | `route` |
| `open_url` | `launchUrl` | `url` |
| `show_snackbar` | `ScaffoldMessenger.showSnackBar` | `message` |
| `copy_to_clipboard` | `Clipboard.setData` | `text` |
| `dispatch` | Calls a registered Dart handler | _(handler-defined)_ |

---

## Exception codes

Every `sdui_core` exception is sealed and carries a machine-readable code, a human-readable message, and an actionable hint.

| Code | Class | When thrown |
|---|---|---|
| `SDUI_001` | `SduiParseException` | JSON structure is invalid |
| `SDUI_002` | `SduiVersionException` | `sdui_version` is absent or unsupported |
| `SDUI_003` | `SduiNetworkException` | HTTP / network failure after all retries |
| `SDUI_004` | `SduiUnknownWidgetException` | No builder registered for the type |
| `SDUI_005` | `SduiActionException` | No handler registered for the event |
| `SDUI_006` | `SduiCacheException` | `shared_preferences` read / write failure |

```dart
try {
  final node = SduiParser.parse(map);
} on SduiException catch (e) {
  logger.error('[${e.code}] ${e.message}', hint: e.hint);
}
```

---

## Dart & Flutter versions

- Dart: `>=3.3.0`
- Flutter: `>=3.22.0`

---

## Examples

- [Full example app](https://github.com/hrushikeshhd18/sdui_core/tree/main/example) — a complete Flutter app with custom widgets, custom actions, WebSocket transport, and `SduiDebugOverlay` enabled.

---

## Maintainers

- [Hrushikesh Desai](https://github.com/hrushikeshhd18)

---

## License

MIT — see [LICENSE](LICENSE).
