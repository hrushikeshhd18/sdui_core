# sdui_core

[![pub.dev](https://img.shields.io/pub/v/sdui_core.svg)](https://pub.dev/packages/sdui_core)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-%3E%3D3.22-blue.svg)](https://flutter.dev)

**A high-performance Server-Driven UI engine for Flutter.** Render dynamic,
state-aware layouts from plain JSON payloads — no custom language, zero boilerplate,
native Bloc/Riverpod integration.

---

## Why sdui_core vs rfw?

| | sdui_core | rfw |
|---|---|---|
| Payload format | **Plain JSON** | Custom `.rfwtxt` binary format |
| Learning curve | None — standard JSON | New domain language |
| Integration | 3 lines | Boilerplate setup |
| Bloc / Riverpod | **Native bridges** | Manual wiring |
| Diffing | **Node id + version** | Full rebuild |
| Isolate parsing | **Built-in** | Manual |
| Error handling | **Typed exceptions** | Generic |

---

## Quick start

```dart
// 1. Register built-in widgets once (e.g. in main.dart before runApp).
SduiWidgetRegistry.instance.registerAll(createCoreWidgets());

// 2. Drop anywhere in your widget tree.
SduiScreen(url: 'https://api.example.com/layouts/home')

// That's it.
```

---

## JSON schema

Every payload must declare `"sdui_version"` and contain a `"root"` node:

```json
{
  "sdui_version": "1.0",
  "root": {
    "type": "sdui:column",
    "id": "home_root",
    "version": 3,
    "props": {
      "mainAxisAlignment": "start"
    },
    "actions": {},
    "children": [
      {
        "type": "sdui:text",
        "id": "hero_title",
        "version": 1,
        "props": {
          "text": "Flash Sale — 50% off",
          "style": "h1",
          "color": "#E53935"
        },
        "actions": {}
      },
      {
        "type": "sdui:button",
        "id": "shop_cta",
        "version": 2,
        "props": { "label": "Shop now", "variant": "elevated" },
        "actions": {
          "onTap": {
            "type": "dispatch",
            "event": "open_flash_sale",
            "payload": { "campaign_id": "fs_42" }
          }
        }
      }
    ]
  }
}
```

### Node fields

| Field | Required | Default | Description |
|-------|----------|---------|-------------|
| `type` | ✅ | — | Widget type string |
| `id` | ✅ | — | Stable server-assigned ID |
| `version` | | `0` | Increment to force rebuild |
| `props` | | `{}` | Widget-specific properties |
| `actions` | | `{}` | Gesture → action mappings |
| `children` | | `[]` | Ordered child nodes |

---

## Built-in widget reference

| Type | Flutter Widget | Key props |
|------|---------------|-----------|
| `sdui:text` | `Text` | `text`, `style`, `maxLines`, `overflow`, `textAlign`, `color`, `fontSize`, `fontWeight` |
| `sdui:image` | `CachedNetworkImage` | `url`, `width`, `height`, `fit`, `borderRadius` |
| `sdui:container` | `Container` | `color`, `padding`, `margin`, `width`, `height`, `borderRadius` |
| `sdui:column` | `Column` | `mainAxisAlignment`, `crossAxisAlignment`, `spacing`, `mainAxisSize` |
| `sdui:row` | `Row` | `mainAxisAlignment`, `crossAxisAlignment`, `spacing`, `mainAxisSize` |
| `sdui:stack` | `Stack` | `alignment`, `children` |
| `sdui:button` | `ElevatedButton` / `OutlinedButton` / `TextButton` | `label`, `variant` (`elevated`\|`outlined`\|`text`), `onTap` action |
| `sdui:icon` | `Icon` | `name` (string), `size`, `color` |
| `sdui:divider` | `Divider` | `height`, `thickness`, `color` |
| `sdui:spacer` | `SizedBox` / `Spacer` | `width`, `height` |
| `sdui:grid` | `GridView.builder` | `columns`, `spacing`, `aspectRatio`, `children` |
| `sdui:list` | `ListView.builder` | `scrollDirection`, `children` |
| `sdui:card` | `Card` | `elevation`, `color`, `borderRadius`, `child` |
| `sdui:padding` | `Padding` | `all`, `horizontal`, `vertical`, `left`, `top`, `right`, `bottom` |
| `sdui:center` | `Center` | `child` |
| `sdui:expanded` | `Expanded` | `flex`, `child` |
| `sdui:visibility` | `Visibility` | `visible` (bool), `child` |
| `sdui:inkwell` | `InkWell` | `onTap` action, `borderRadius`, `child` |

### Color formats
Accept either `"#RRGGBB"`, `"#AARRGGBB"`, or an integer `0xFFRRGGBB`.

### Named text styles
`"h1"`, `"h2"`, `"h3"`, `"subtitle"`, `"body"`, `"body2"`, `"caption"`, `"label"` — resolved from the ambient `Theme.textTheme`.

---

## Custom widget registration

```dart
SduiWidgetRegistry.instance.register('myapp:banner', (node, ctx) {
  final url = node.props['imageUrl'] as String;
  return HeroBanner(imageUrl: url);
});
```

---

## Custom action handlers

```dart
SduiActionRegistry.instance.register('add_to_cart', (action, ctx) async {
  final productId = action.payload['product_id'] as String;
  ctx.flutterContext.read<CartCubit>().add(productId);
});
```

Built-in action types (`dispatch`, `navigate`, `open_url`, `copy_to_clipboard`,
`show_snackbar`) are handled automatically — no registration needed.

---

## State management integration

### Bloc

```dart
SduiActionRegistry.instance.register('add_to_cart', (action, ctx) async {
  BlocProvider.of<CartBloc>(ctx.flutterContext)
      .add(CartItemAdded(action.payload['sku'] as String));
});
```

### Riverpod

```dart
SduiActionRegistry.instance.register('add_to_cart', (action, ctx) async {
  final container = ProviderScope.containerOf(ctx.flutterContext);
  container.read(cartProvider.notifier).add(action.payload['sku'] as String);
});
```

---

## Full SduiScreen API

```dart
SduiScreen(
  url: 'https://api.example.com/layouts/home',
  headers: {'Authorization': 'Bearer $token'},
  refreshInterval: const Duration(minutes: 5),
  parseInIsolate: true,            // default: true — never blocks UI thread
  loadingBuilder: (_) => MyShimmer(),
  errorBuilder: (_, err) => MyErrorWidget(err.toString()),
  emptyBuilder: (_) => const EmptyState(),
  onEvent: (event, payload) => analytics.track(event, payload),
)
```

---

## Performance notes

- **Isolate parsing** — `SduiParser.parseAsync` runs in a background `Isolate` so large payloads never jank the raster thread.
- **Incremental diffing** — increment a node's `version` field on the server; only that subtree rebuilds. Unchanged nodes are keyed and skipped.
- **RepaintBoundary** — every `SduiScreen` root is automatically wrapped. Add `"isolateRepaint": true` to any node's props to isolate its subtree further.
- **Deterministic keys** — `SduiKeyManager` assigns keys from `id + version`, never list indices, so reordering children doesn't cause unnecessary rebuilds.

---

## Roadmap (v0.2.0)

- [ ] Conditional rendering via `"visible_if"` expression DSL
- [ ] Animation support (`"sdui:animated_container"`, transition props)
- [ ] WebSocket / SSE live-update transport
- [ ] Offline cache with stale-while-revalidate
- [ ] Form widgets (`sdui:text_field`, `sdui:checkbox`, `sdui:radio`)
- [ ] A/B testing hooks
- [ ] Dart DevTools extension for inspecting the live SDUI tree
