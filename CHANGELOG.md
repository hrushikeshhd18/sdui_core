## 0.2.2

* Replaced `cached_network_image` with Flutter's built-in `Image.network` to achieve full WASM compatibility. The `sdui:image` builder preserves the same loading spinner and broken-image error icon.
* Removed `cached_network_image` from `pubspec.yaml`; no API changes for consumers.

## 0.2.1

* Documentation updates, branding improvements, and README overhaul for pub.dev structure.

## 0.2.0
### Breaking changes

* `SduiWidgetRegistry` and `SduiActionRegistry` are no longer singletons. The
  `.instance` accessor has been removed. Use `SduiWidgetRegistry()` to create a
  fresh instance or `SduiWidgetRegistry.defaults` for the shared default. Pass
  registries via `SduiScope` rather than relying on global state — this makes
  tests and multi-tenant apps trivially correct.
* `SduiParser.parseAsync` renamed to `SduiParser.parseString` to reflect that
  the method accepts a raw JSON string (not a `Future`). The background-isolate
  behaviour is unchanged.
* `SduiWidgetRegistry.resolve` now requires the named parameter `nodePath:`.
  Previously the tree path was positional and easy to omit accidentally.

### New features

**Transport layer**
* Abstract `SduiTransport` interface. Swap HTTP for WebSocket — or a custom
  gRPC/mock transport — with a single constructor argument.
* `HttpSduiTransport` — default HTTP transport with exponential back-off retry.
  Configurable `maxRetries`, `retryDelay`, `timeout`, and custom `headers`.
* `WebSocketSduiTransport` — streams every server message as a fresh layout.
  Auto-reconnects with exponential back-off; configurable `maxReconnectAttempts`
  and `pingInterval` to keep the connection alive.

**Caching**
* `SduiCache` — stale-while-revalidate cache backed by `shared_preferences`.
  Serves the last-known layout instantly on app launch while a fresh fetch runs
  in the background. Enabled by default on `SduiScreen`; opt out with
  `enableCache: false`.
* `SduiCacheException` (code `SDUI_006`) added to the sealed exception
  hierarchy for cache read/write failures.

**Validation**
* `SduiValidator` — full-tree pre-parse validation with structured error codes.
  Reports `MISSING_VERSION`, `INVALID_VERSION`, `MISSING_TYPE`, `MISSING_ID`,
  `DUPLICATE_ID`, `MISSING_ACTION_TYPE`, `MISSING_ACTION_EVENT`, and more.
  Call `SduiParser.validate(map)` before parsing to surface user-friendly errors
  without catching parse exceptions.

**Diffing**
* `SduiDiffer` — incremental tree diff by `id + version`. Returns changed,
  added, removed, and moved node sets. Feed the `updatedTree` into `setState`
  to let Flutter reconcile only the changed subtrees.

**Props**
* `SduiProps` — type-safe prop accessor wrapping `Map<String, Object?>`.
  Helpers: `getString`, `getBool`, `getDouble`, `getInt`, `getColor`,
  `getColorOrNull`, `getEdgeInsets`, `getAlignment`, `getDoubleOrNull`.

**Conditional rendering**
* `"visible_if"` prop — evaluated by the renderer before any builder is called.
  Accepts `bool` literals, `"props.X"` expressions (resolved against the node's
  own props), and plain truthy strings. Returns `SizedBox.shrink()` when false.
  The single most-requested SDUI feature; enables A/B testing, feature flags,
  and role-based layout without a native release.

**Theming**
* `SduiTheme` — `InheritedWidget` holding a `Map<String, TextStyle>` named
  style registry. The `sdui:text` builder checks `SduiTheme` before the built-in
  Material `TextTheme` mappings, so the server can control brand typography
  (`'promo'`, `'fine_print'`, etc.) without a native release.

**Debug tooling**
* `SduiDebugOverlay` — wraps every rendered node in debug builds. Long-pressing
  any node opens a floating inspector panel showing the node id, type, version,
  tree path, prop count, action count, and child count. Enable with
  `SduiDebugOverlay.enabled = true`. No-op in release builds.

**Screen machine**
* `SduiScreen` is now a 7-state machine:
  `loading`, `loadingWithCache`, `success`, `refreshing`, `error`,
  `errorWithCache`, `empty`.
* New constructor parameters: `transport`, `pullToRefresh`, `onLoad`,
  `onError`, `onEvent`, `onRefresh`, `emptyBuilder`.

**Rendering**
* `SduiWidget` — renders a pre-parsed `SduiNode` directly without a network
  request. Embed dynamic sub-trees anywhere in an existing screen.

**Action system**
* `SduiActionRegistry.addMiddleware` — middleware chain for logging, analytics,
  and action transformation. Each middleware receives the action and a `next`
  callback.
* `SduiActionRegistry.withEventInterceptor` — convenience factory for wiring
  `SduiScreen.onEvent` into the registry without subclassing.
* `SduiAction.debounceMs` — built-in double-tap protection; debounces repeated
  triggers at the action definition level, not the call site.

**Widget builders**
* Namespace wildcard resolution: `register('myapp:*', builder)` matches any
  type in the `myapp:` namespace that has no more-specific registration.
* `createMaterialWidgets()` — 12 Material 3 builders: `sdui:list_tile`,
  `sdui:switch_tile`, `sdui:progress`, `sdui:fab`, `sdui:bottom_nav`,
  `sdui:nav_rail`, `sdui:drawer`, `sdui:app_bar`, `sdui:search_bar`,
  `sdui:tab_bar`, `sdui:bottom_sheet`, `sdui:dialog`.
* `createCupertinoWidgets()` — 7 Cupertino builders: `sdui:cupertino_button`,
  `sdui:cupertino_nav_bar`, `sdui:cupertino_list_tile`, `sdui:cupertino_switch`,
  `sdui:cupertino_slider`, `sdui:cupertino_activity`, `sdui:cupertino_dialog`.
* 10 additional core types: `sdui:safe_area`, `sdui:aspect_ratio`,
  `sdui:fitted_box`, `sdui:clip_r_rect`, `sdui:opacity`, `sdui:transform_scale`,
  `sdui:hero`, `sdui:badge`, `sdui:chip`, `sdui:placeholder`.

**Utilities**
* `SduiLogger` — category-based debug logging with `network`, `render`,
  `action`, `cache`, and `warn` channels. Silenced in release builds.
* `SduiIcons` — 100+ icon name → `IconData` mappings for use in `sdui:icon`.
* `SduiColorParsing` extension — `"#RRGGBB"` / `"#AARRGGBB"` / named color
  string → `Color` parsing.
* `SduiContextExtension` — convenience methods on `BuildContext` for accessing
  `SduiScope` data inline.

**Quality**
* All node types are `@immutable` with `copyWith`, `==`, `hashCode`, and
  `debugFillProperties` for the Flutter widget inspector.
* 171 tests across unit, widget, and integration suites.
* GitHub Actions CI matrix (stable + beta channel, ubuntu/macOS/Windows).
* OIDC-based automated publish workflow on `v*.*.*` tags.

---

## 0.1.0

Initial release of `sdui_core`.

### Rendering engine

* JSON-in, native-Flutter-out rendering engine. A JSON payload from any server
  is parsed once and rendered as a real Flutter widget tree — no `eval`, no
  WebView, no code generation.
* Isolate-based JSON parsing via `SduiParser.parseAsync`. The JSON decode and
  node tree construction run on a background isolate, keeping the UI thread
  free during heavy payloads.
* `RepaintBoundary` at every `SduiScreen` root. Per-subtree opt-in via
  `"isolateRepaint": true` in any node's props.
* `SduiKeyManager` — deterministic `ValueKey` generation from `id + parentPath`.
  Ensures Flutter's reconciler reuses element state across rebuilds rather than
  tearing down and re-mounting subtrees on every refresh.
* `SduiScope` — `InheritedWidget` that makes the widget registry and action
  registry available to every builder without prop-drilling.

### Built-in widget types (18)

`sdui:text` (`Text` with style mapping), `sdui:image` (`Image.network` with
fit/width/height), `sdui:container` (color, padding, border-radius),
`sdui:column`, `sdui:row`, `sdui:stack` (alignment props), `sdui:button`
(elevated / outlined / filled variants), `sdui:icon` (icon name → `IconData`),
`sdui:divider` / `sdui:spacer`, `sdui:grid` (`GridView` with columns, spacing,
aspectRatio), `sdui:list` (`ListView` / `ListView.builder`), `sdui:card`
(elevation, color), `sdui:padding` (directional), `sdui:center`,
`sdui:expanded` (flex prop), `sdui:visibility` (show/hide on `visible` bool),
`sdui:inkwell` (`InkWell` tap wrapper).

### Actions (5 built-in types)

`navigate` (`Navigator.pushNamed` with `payload.route`), `open_url`
(`launchUrl` with `payload.url`), `show_snackbar` (`ScaffoldMessenger` with
`payload.message`), `copy_to_clipboard` (`Clipboard.setData` with
`payload.text`), `dispatch` (calls a registered custom handler).

### Registries (singletons in 0.1.0, replaced in 0.2.0)

`SduiWidgetRegistry.instance` — global widget builder registry with `register`,
`registerAll`, `resolve`, and wildcard resolution.  
`SduiActionRegistry.instance` — global action handler registry with `register`,
`dispatch`, and middleware support.

### Exception hierarchy

Typed, sealed exception hierarchy — every error includes a code, a human-readable
message, and an actionable hint string:

* `SduiParseException` (`SDUI_001`) — JSON parsing failed.
* `SduiVersionException` (`SDUI_002`) — unsupported `sdui_version` field.
* `SduiNetworkException` (`SDUI_003`) — HTTP / network failure.
* `SduiUnknownWidgetException` (`SDUI_004`) — no builder registered for type.
* `SduiActionException` (`SDUI_005`) — no handler registered for event.

### Auto-refresh

`SduiScreen(refreshInterval: Duration(minutes: 5))` — polls the server on a
timer and re-renders on change without any application code.
