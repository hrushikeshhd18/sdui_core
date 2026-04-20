# sdui_core

[![pub.dev](https://img.shields.io/pub/v/sdui_core.svg)](https://pub.dev/packages/sdui_core)
[![CI](https://github.com/yourusername/sdui_core/actions/workflows/ci.yml/badge.svg)](https://github.com/yourusername/sdui_core/actions)
[![codecov](https://codecov.io/gh/yourusername/sdui_core/branch/main/graph/badge.svg)](https://codecov.io/gh/yourusername/sdui_core)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](LICENSE)

A high-performance **Server-Driven UI** engine for Flutter. Render dynamic, state-aware layouts from plain JSON payloads at runtime — no App Store review needed for UI changes.

---

## Features

- **Zero-config rendering** — one line to render a full screen from a URL
- **28+ built-in widget types** — text, image, button, grid, list, card, icon, and more
- **Material 3 + Cupertino** widget sets included out of the box
- **Abstract transport layer** — swap HTTP for WebSocket with a single line
- **Stale-while-revalidate cache** — instant cached render while fresh data loads
- **7-state screen machine** — loading, loadingWithCache, success, refreshing, error, errorWithCache, empty
- **Incremental differ** — only rebuilds nodes that changed (by id + version)
- **Action middleware** — intercept, log, or transform any action
- **Action debouncing** — built-in double-tap protection
- **Isolate-based parsing** — JSON decoded off the UI thread by default
- **Type-safe prop accessors** — `SduiProps` with color, edge-insets, alignment helpers
- **Sealed exception hierarchy** — every error has a code, message, and actionable hint
- **Fully testable** — non-singleton registries, mock transport helpers included

---

## Quick start

```yaml
# pubspec.yaml
dependencies:
  sdui_core: ^0.1.0
```

```dart
// main.dart
void main() {
  runApp(
    SduiScope(
      registry: SduiWidgetRegistry()..registerAll(createCoreWidgets()),
      child: MaterialApp(home: SduiScreen(url: 'https://api.example.com/home')),
    ),
  );
}
```

That's it. `SduiScreen` fetches, parses, caches, and renders the JSON layout automatically.

---

## JSON payload format

```json
{
  "sdui_version": "1.0",
  "root": {
    "type": "sdui:column",
    "id": "root",
    "version": 1,
    "props": {},
    "actions": {},
    "children": [
      {
        "type": "sdui:text",
        "id": "headline",
        "version": 1,
        "props": { "text": "Hello from the server!", "style": "h1" },
        "actions": {}
      },
      {
        "type": "sdui:button",
        "id": "cta",
        "version": 1,
        "props": { "label": "Shop now" },
        "actions": {
          "onTap": {
            "type": "navigate",
            "event": "go_shop",
            "payload": { "route": "/shop" }
          }
        }
      }
    ]
  }
}
```

---

## Built-in widget types

### Core (`createCoreWidgets()`)

| Type | Description |
|------|-------------|
| `sdui:text` | `Text` with style mapping |
| `sdui:image` | `Image.network` with fit/size props |
| `sdui:button` | `ElevatedButton` / `OutlinedButton` / `FilledButton` |
| `sdui:icon` | `Icon` from name string |
| `sdui:divider` | `Divider` / `VerticalDivider` |
| `sdui:spacer` | `Spacer` |
| `sdui:column` | `Column` with alignment props |
| `sdui:row` | `Row` with alignment props |
| `sdui:stack` | `Stack` with alignment props |
| `sdui:grid` | `GridView` with columns/spacing/aspectRatio |
| `sdui:list` | `ListView` / `ListView.builder` |
| `sdui:card` | `Card` with elevation/color props |
| `sdui:container` | `Container` with color/padding/border-radius |
| `sdui:padding` | `Padding` with directional props |
| `sdui:center` | `Center` |
| `sdui:expanded` | `Expanded` with flex prop |
| `sdui:visibility` | Show/hide based on `visible` prop |
| `sdui:inkwell` | `InkWell` tap wrapper |
| `sdui:safe_area` | `SafeArea` |
| `sdui:aspect_ratio` | `AspectRatio` |
| `sdui:opacity` | `AnimatedOpacity` |
| `sdui:clip_r_rect` | `ClipRRect` with borderRadius |
| `sdui:hero` | `Hero` with tag |
| `sdui:badge` | `Badge` overlay |
| `sdui:chip` | `ActionChip` / `FilterChip` |
| `sdui:placeholder` | `Placeholder` widget |

### Material 3 (`createMaterialWidgets()`)

`sdui:list_tile`, `sdui:switch_tile`, `sdui:progress`, `sdui:fab`, `sdui:bottom_nav`, `sdui:nav_rail`, `sdui:drawer`, `sdui:app_bar`, `sdui:search_bar`, `sdui:tab_bar`, `sdui:bottom_sheet`, `sdui:dialog`

### Cupertino (`createCupertinoWidgets()`)

`sdui:cupertino_button`, `sdui:cupertino_nav_bar`, `sdui:cupertino_list_tile`, `sdui:cupertino_switch`, `sdui:cupertino_slider`, `sdui:cupertino_activity`, `sdui:cupertino_dialog`

---

## Custom widgets

```dart
SduiScope(
  registry: SduiWidgetRegistry()
    ..registerAll(createCoreWidgets())
    ..register('myapp:banner', (node, ctx) {
      final p = SduiProps(node.props);
      return Container(
        color: p.getColor('color', fallback: Colors.blue),
        padding: p.getEdgeInsets('padding'),
        child: Text(p.getString('title')),
      );
    }),
  child: ...,
)
```

---

## Custom actions

```dart
SduiScope(
  actionRegistry: SduiActionRegistry()
    ..register('add_to_cart', (action, ctx) async {
      final productId = action.payload['productId'] as String;
      await cartRepository.add(productId);
      return const SduiActionResult.success();
    }),
  child: ...,
)
```

### Built-in action types

| Type | Behaviour |
|------|-----------|
| `navigate` | `Navigator.pushNamed` with `payload.route` |
| `open_url` | `launchUrl` with `payload.url` |
| `show_snackbar` | `ScaffoldMessenger.showSnackBar` with `payload.message` |
| `copy_to_clipboard` | `Clipboard.setData` with `payload.text` |
| `dispatch` | Calls a registered custom handler |

### Action middleware

```dart
registry.addMiddleware((action, ctx, next) async {
  analytics.log('sdui_action', {'event': action.event});
  return next();
});
```

---

## Transport layer

```dart
// HTTP (default)
SduiScreen(url: 'https://api.example.com/home')

// WebSocket (live updates)
SduiScreen(
  url: 'wss://api.example.com/home/live',
  transport: WebSocketSduiTransport(),
)

// Custom transport (mock, gRPC, etc.)
SduiScreen(
  url: 'my-key',
  transport: MyCustomTransport(),
)
```

---

## Screen configuration

```dart
SduiScreen(
  url: 'https://api.example.com/home',
  headers: {'Authorization': 'Bearer $token'},
  enableCache: true,              // stale-while-revalidate (default: true)
  parseInIsolate: true,           // parse JSON off the UI thread (default: true)
  refreshInterval: Duration(minutes: 5),
  pullToRefresh: true,
  loadingBuilder: (_) => const MyLoadingWidget(),
  errorBuilder: (_, error) => MyErrorWidget(error: error),
  emptyBuilder: (_) => const MyEmptyState(),
  onLoad: () => print('First render complete'),
  onError: (e) => Sentry.captureException(e),
  onEvent: (event, payload) => analytics.track(event, payload),
  onRefresh: () => print('Pull-to-refresh triggered'),
)
```

---

## Render a pre-parsed node

```dart
final node = SduiParser.parse(myMap);

// Embed in any existing screen — no network request
SduiWidget(node: node)
```

---

## Incremental diffing

```dart
final result = SduiDiffer.diff(oldTree, newTree);
if (result.hasDiffs) {
  print('${result.changedCount} nodes changed');
  setState(() => _node = result.updatedTree);
}
```

---

## Validation

```dart
final result = SduiParser.validate(myMap);
if (!result.isValid) {
  for (final error in result.errors) {
    print('[${error.code}] ${error.path}: ${error.message}');
  }
}
```

---

## Testing

```dart
// Fresh per-test registry — no global state pollution
final reg = SduiWidgetRegistry()
  ..register('sdui:text', myStubBuilder);

// Mock transport
final transport = MockSduiTransport(kMinimalPayload);
await tester.pumpWidget(
  SduiScreen(
    url: 'https://test.example.com',
    transport: transport,
    enableCache: false,
    parseInIsolate: false,
  ),
);
await tester.pumpAndSettle();
```

---

## Exception codes

| Code | Class | Description |
|------|-------|-------------|
| `SDUI_001` | `SduiParseException` | JSON parsing failed |
| `SDUI_002` | `SduiVersionException` | Unsupported `sdui_version` |
| `SDUI_003` | `SduiNetworkException` | HTTP/network failure |
| `SDUI_004` | `SduiUnknownWidgetException` | No builder for widget type |
| `SDUI_005` | `SduiActionException` | No handler for action event |
| `SDUI_006` | `SduiCacheException` | Cache read/write failure |

---

## License

MIT — see [LICENSE](LICENSE).
