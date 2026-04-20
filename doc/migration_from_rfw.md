# Migrating from `rfw` to `sdui_core`

This guide maps `rfw` (Remote Flutter Widgets) concepts to their `sdui_core`
equivalents. The conceptual models are similar — both render dynamic UI from an
external source at runtime — but the wire format, registration API, and
execution model differ significantly.

---

## Concept map

| `rfw` concept | `sdui_core` equivalent | Notes |
|---|---|---|
| `Runtime` | `SduiWidgetRegistry` | Widget builder registry |
| `DynamicContent` | JSON `props` map | Props are plain `Map<String, Object?>` |
| `RemoteWidget` | `SduiScreen` | Full fetch-parse-render lifecycle |
| `LocalWidgetBuilder` | `SduiWidgetBuilder` typedef | `(SduiNode, SduiBuildContext) → Widget` |
| `FullyQualifiedWidgetName` | `"sdui:type"` string key | Namespaced, e.g. `"myapp:banner"` |
| Custom event handlers | `SduiActionRegistry` | Named handlers dispatched by server |
| `rfw` binary format / `.rfw` files | JSON (any transport) | HTTP, WebSocket, or custom |
| `RemoteWidget` widget tree state | `SduiScreen` 7-state machine | `loading`, `success`, `error`, etc. |

---

## Registration

### rfw

```dart
final runtime = Runtime();
runtime.update(
  const LibraryName(['local']),
  LocalWidgetLibrary({
    'Banner': (ctx, source) => Container(
      color: ArgumentDecoders.color(source, ['color']),
      child: Text(source.v<String>(['title']) ?? ''),
    ),
  }),
);
```

### sdui_core

```dart
final registry = SduiWidgetRegistry()
  ..register('myapp:banner', (node, ctx) {
    final p = SduiProps(node.props);
    return Container(
      color: p.getColor('color', fallback: Colors.blue),
      child: Text(p.getString('title')),
    );
  });
```

Key differences:
- No `LibraryName` — namespacing is the prefix before `:` in the type string.
- `SduiProps` replaces `ArgumentDecoders` with typed helpers: `getColor`,
  `getEdgeInsets`, `getAlignment`, `getBool`, `getDouble`, etc.
- Registries are plain objects, not singletons. Pass via `SduiScope` or
  `SduiScreen`'s constructor.

---

## Rendering

### rfw

```dart
RemoteWidget(
  runtime: runtime,
  data: DynamicContent(dataMap),
  widget: const FullyQualifiedWidgetName(['remote', ''], 'home'),
)
```

### sdui_core

```dart
SduiScreen(url: 'https://api.example.com/layouts/home')
```

Or with explicit config:

```dart
SduiScope(
  registry: SduiWidgetRegistry()..registerAll(createCoreWidgets()),
  child: SduiScreen(
    url: 'https://api.example.com/layouts/home',
    headers: {'Authorization': 'Bearer $token'},
    enableCache: true,
    pullToRefresh: true,
  ),
)
```

---

## JSON payload vs. RFW binary

`rfw` uses a binary format (`.rfw`) or a custom text format (`.rfwtxt`).
`sdui_core` uses plain JSON:

```json
{
  "sdui_version": "1.0",
  "root": {
    "type": "myapp:banner",
    "id": "hero_banner",
    "version": 1,
    "props": { "title": "Summer Sale", "color": "#FF5733" },
    "actions": {
      "onTap": { "type": "navigate", "event": "open_sale", "payload": { "route": "/sale" } }
    },
    "children": []
  }
}
```

---

## Event handling / actions

### rfw

`rfw` doesn't have a built-in action system. Interactions are handled by
passing Dart callbacks through `DynamicContent`:

```dart
DynamicContent({'onTap': () => Navigator.pushNamed(context, '/sale')})
```

### sdui_core

Actions are declared server-side and dispatched to named handlers:

```dart
SduiScope(
  actionRegistry: SduiActionRegistry()
    ..register('open_sale', (action, ctx) async {
      Navigator.pushNamed(ctx.flutterContext, action.payload['route'] as String);
      return const SduiActionResult.success();
    }),
  child: ...,
)
```

Built-in types (`navigate`, `open_url`, `show_snackbar`, `copy_to_clipboard`)
require zero registration.

---

## Props access

### rfw

```dart
// rfw ArgumentDecoders
final color = ArgumentDecoders.color(source, ['color']);
final label = source.v<String>(['label']) ?? 'Default';
```

### sdui_core

```dart
final p = SduiProps(node.props);
final color = p.getColor('color', fallback: Colors.blue);
final label = p.getString('label', fallback: 'Default');
```

Available helpers: `getString`, `getBool`, `getDouble`, `getInt`, `getColor`,
`getColorOrNull`, `getEdgeInsets`, `getAlignment`.

---

## Caching

`rfw` has no built-in caching. `sdui_core` ships stale-while-revalidate cache
backed by `shared_preferences`, enabled by default:

```dart
// Opt out per screen:
SduiScreen(url: '...', enableCache: false)

// Initialize once at app start (required for cache to persist across sessions):
await SduiCache.init();
```

---

## Transports

`rfw` fetches `.rfw` binaries over HTTP. `sdui_core` supports:

| Transport | Usage |
|---|---|
| `HttpSduiTransport` (default) | `SduiScreen(url: 'https://...')` |
| `WebSocketSduiTransport` | `SduiScreen(url: 'wss://...', transport: WebSocketSduiTransport())` |
| Custom | Implement `SduiTransport` interface |

---

## Testing

### rfw

Testing requires constructing a full `Runtime` + `DynamicContent` in each test.

### sdui_core

Use `MockSduiTransport` to inject JSON payloads directly:

```dart
final transport = MockSduiTransport({
  'sdui_version': '1.0',
  'root': {'type': 'sdui:text', 'id': 'msg', 'version': 1,
           'props': {'text': 'Hello'}, 'actions': {}},
});

await tester.pumpWidget(SduiScreen(
  url: 'ignored',
  transport: transport,
  enableCache: false,
  parseInIsolate: false,
));
await tester.pumpAndSettle();
expect(find.text('Hello'), findsOneWidget);
```

Registries are non-singletons — create a fresh `SduiWidgetRegistry()` per test
to avoid global state pollution.

---

## Feature comparison

| Feature | `rfw` | `sdui_core` |
|---|---|---|
| Wire format | Binary / text DSL | JSON |
| Built-in widgets | None (all custom) | 28 core + 12 Material 3 + 7 Cupertino |
| Caching | None | Stale-while-revalidate |
| WebSocket transport | None | Built-in |
| Action system | Dart callbacks via DynamicContent | Named registry + middleware |
| Conditional rendering | None | `"visible_if"` prop |
| Tree diffing | None | `SduiDiffer` by id + version |
| Named text themes | None | `SduiTheme` |
| Isolate parsing | None | Default-on |
| Debug overlay | None | `SduiDebugOverlay` |
| Exception hierarchy | None | Sealed + error codes |
