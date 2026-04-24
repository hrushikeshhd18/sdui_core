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

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/comparison.png" alt="sdui_core vs Traditional" width="700" />
</p>

---

## Installation

```yaml
dependencies:
  sdui_core: ^0.3.0
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

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/lifecycle.png" alt="SduiScreen Lifecycle" width="600" />
</p>

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

## SduiController

`SduiController` is the state machine behind every `SduiScreen`. In simple apps you never touch it — `SduiScreen` creates and owns one internally. In more complex apps you create it yourself and pass it to `SduiScreen.controlled()`, giving your state-management layer full control over the lifecycle.

```dart
// Create once — in initState, a Provider, or a Riverpod notifier
final controller = SduiController(
  url: 'https://api.example.com/layouts/home',
  headers: {'Authorization': 'Bearer $token'},
  enableCache: true,
  refreshInterval: const Duration(minutes: 10),
  onLoad: () => analytics.track('screen_ready'),
  onError: (e) => crashReporter.capture(e),
);

// Render with the controlled constructor
SduiScreen.controlled(controller: controller)
```

`SduiScreen.controlled` is a pure view — it renders whatever the controller holds and does not own the fetch lifecycle. The standard `SduiScreen(url: '...')` constructor is unchanged.

### State machine

| State | Description |
|---|---|
| `loading` | First load — no data, no cache. Shows loading builder. |
| `loadingWithCache` | Stale cache visible while fresh fetch is in flight. |
| `success` | Fresh data rendered. |
| `refreshing` | Re-fetching in the background; current data still visible. |
| `error` | Fetch failed, no cached fallback. Shows error builder. |
| `errorWithCache` | Fetch failed; stale cache visible with an error banner. |
| `empty` | Parsed successfully but the root node has no children. |

### Optimistic updates with patchNode

Apply prop overrides to any node instantly — without a network round-trip:

```dart
// Reflect new cart count before the API responds
controller.patchNode('cart_badge', {'count': '${cart.length}'});

// Restore server value
controller.clearPatch('cart_badge');

// Restore all nodes
controller.clearAllPatches();
```

`patchNode` triggers a synchronous rebuild via `notifyListeners`. The patched tree is available as `controller.effectiveNode`.

### Programmatic refresh

```dart
// Force re-fetch from anywhere — BLoC listener, timer, push notification handler
controller.refresh();
```

### Integrating with state-management frameworks

**BLoC**

```dart
// Drive headers from AuthBloc; patch nodes from CartBloc
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final SduiController _controller;

  @override
  void initState() {
    super.initState();
    final token = context.read<AuthBloc>().state.token;
    _controller = SduiController(
      url: 'https://api.example.com/layouts/home',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<CartBloc, CartState>(
        listener: (_, state) {
          _controller.patchNode('cart_badge', {'count': '${state.count}'});
        },
        child: SduiScreen.controlled(controller: _controller),
      );
}
```

**Provider**

```dart
// Store the controller in a ChangeNotifierProvider
ChangeNotifierProvider(
  create: (context) => SduiController(
    url: 'https://api.example.com/layouts/home',
    headers: context.read<AuthProvider>().headers,
  )..load(),
  child: Consumer<SduiController>(
    builder: (_, controller, __) => SduiScreen.controlled(controller: controller),
  ),
)
```

**Riverpod**

```dart
final homeControllerProvider = ChangeNotifierProvider.autoDispose((ref) {
  final token = ref.watch(authTokenProvider);
  return SduiController(
    url: 'https://api.example.com/layouts/home',
    headers: token != null ? {'Authorization': 'Bearer $token'} : const {},
  )..load();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(homeControllerProvider);
    // Cart changes → patch the badge instantly
    ref.listen(cartProvider, (_, cart) {
      controller.patchNode('cart_badge', {'count': '${cart.count}'});
    });
    return SduiScreen.controlled(controller: controller);
  }
}
```

---

## SduiBindings

`SduiBindings` lets your state layer push live values into the SDUI tree without a server round-trip. Any node whose `visible_if` prop starts with `binding.` will be shown or hidden based on the live value — and rebuilds automatically when it changes.

```dart
// 1. Create a notifier
final bindings = SduiBindingsNotifier({
  'user.isPremium': false,
  'feature.newCheckout': false,
});

// 2. Update from your state layer
authBloc.stream.listen((s) => bindings.put('user.isPremium', s.isPremium));
featureFlags.stream.listen((f) => bindings.put('feature.newCheckout', f.newCheckout));

// 3. Place above SduiScope
SduiBindings(
  notifier: bindings,
  child: SduiScope(
    child: MaterialApp(home: SduiScreen(url: '...')),
  ),
)
```

Server JSON references binding keys with the `binding.` prefix:

```json
{ "type": "sdui:container", "id": "premium_banner", "version": 1,
  "props": { "visible_if": "binding.user.isPremium" }, "actions": {} }

{ "type": "sdui:container", "id": "new_checkout", "version": 1,
  "props": { "visible_if": "binding.feature.newCheckout" }, "actions": {} }
```

The `visible_if` evaluator also supports the existing `"props.X"` form (resolved against the server-provided node props) and plain boolean literals.

### SduiBindingsNotifier API

| Method | Description |
|---|---|
| `put(key, value)` | Updates a single key; notifies if value changed. |
| `putAll(map)` | Merges a map; notifies once if anything changed. |
| `remove(key)` | Deletes a key; notifies if it existed. |
| `resolve(key)` | Returns the current value, or `null`. |
| `values` | Read-only view of all current bindings. |

---

## SduiScope.navigatorKey

Pass a `GlobalKey<NavigatorState>` to `SduiScope` for safe navigation from async action handlers. The key is propagated automatically through the entire renderer and action dispatch chain.

```dart
final _navigatorKey = GlobalKey<NavigatorState>();

SduiScope(
  navigatorKey: _navigatorKey,
  child: MaterialApp(
    navigatorKey: _navigatorKey,
    home: SduiScreen(url: '...'),
  ),
)
```

When `navigatorKey` is set, `SduiActionContext.navigator` resolves `navigatorKey.currentState` first, falling back to `Navigator.maybeOf(flutterContext)` only when the context is still mounted. This prevents crashes when a `navigate` action fires after an `await` gap.

```dart
// Action handlers get the safe navigator automatically — no boilerplate
SduiActionRegistry.defaults.register('navigate', (action, ctx) async {
  await someAsyncOperation(); // context may be unmounted after this
  // ctx.navigator is still safe — uses navigatorKey
  ctx.navigator?.pushNamed(action.payload['route'] as String);
  return const SduiActionResult.success();
});
```

---

## Use cases

### E-commerce — personalised product pages

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/usecase_ecommerce.png" alt="E-commerce use case" width="700" />
</p>

Your CMS or promo engine owns the layout. Inventory levels, personalised banners, sale pricing, and promoted products are injected server-side into the JSON. The Flutter app renders whatever the server sends.

```json
{
  "type": "sdui:button",
  "id": "buy_cta",
  "version": 5,
  "props": {
    "label": "Add to cart — $4.99",
    "variant": "filled",
    "visible_if": "props.inStock"
  },
  "actions": {
    "onTap": { "type": "dispatch", "event": "add_to_cart", "payload": { "sku": "APPLE-ORG-1KG" } }
  }
}
```

Flip `inStock` to `false` and the button disappears for every user within one deploy — no native release required.

---

### A/B testing layouts

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/usecase_ab_testing.png" alt="A/B testing use case" width="600" />
</p>

Your experiment service returns a different JSON tree per user cohort. `SduiScreen.onEvent` funnels all interactions to analytics so you can compare conversion without any native code changes.

```dart
SduiScreen(
  url: 'https://api.example.com/layouts/home?cohort=${user.experimentCohort}',
  onEvent: (event, payload) {
    analytics.track(event, {'cohort': user.experimentCohort, ...payload});
  },
)
```

---

### Feature flags — node-level visibility

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/usecase_feature_flags.png" alt="Feature flags use case" width="600" />
</p>

`visible_if` is evaluated by `SduiRenderer` before a builder is invoked. The node is excluded from the widget tree without touching native code.

```json
{
  "type": "sdui:container",
  "id": "new_checkout_banner",
  "version": 1,
  "props": { "visible_if": "props.newCheckoutEnabled" },
  "actions": {}
}
```

Toggle `newCheckoutEnabled` in your flag service and redeploy the API — every user sees the change immediately.

---

### White-labelling

Return a different JSON tree per `client_id` header. One Flutter binary. Unlimited branded shells.

```dart
SduiScreen(
  url: 'https://api.example.com/layouts/home',
  headers: {
    'Authorization': 'Bearer $token',
    'X-Client-Id': tenantConfig.clientId,
  },
)
```

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

## Integrations

`sdui_core` is transport-, state-management-, and navigation-agnostic. Below are copy-paste recipes for the most popular Flutter packages.

---

### bloc / flutter_bloc

> [pub.dev/packages/bloc](https://pub.dev/packages/bloc) — 1.6 B+ downloads

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/integration_bloc.png" alt="Bloc integration" width="700" />
</p>

Wire auth tokens from `AuthBloc` into `SduiScreen` headers. Route SDUI dispatch events back into your Bloc as events.

```dart
// 1. Read auth state from AuthBloc and pass as headers
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const LoginScreen();
        }
        return SduiScreen(
          url: 'https://api.example.com/layouts/home',
          headers: {'Authorization': 'Bearer ${authState.token}'},
          onError: (e) {
            if (e is SduiNetworkException && e.statusCode == 401) {
              context.read<AuthBloc>().add(AuthTokenExpired());
            }
          },
        );
      },
    );
  }
}

// 2. Route SDUI dispatch events into CartBloc
SduiActionRegistry()
  ..register('add_to_cart', (action, ctx) async {
    final sku = action.payload['sku'] as String;
    ctx.flutterContext.read<CartBloc>().add(CartItemAdded(sku: sku));
    return const SduiActionResult.success();
  })
  ..register('remove_from_cart', (action, ctx) async {
    final sku = action.payload['sku'] as String;
    ctx.flutterContext.read<CartBloc>().add(CartItemRemoved(sku: sku));
    return const SduiActionResult.success();
  });

// 3. Use SduiController to patch nodes instantly when CartBloc state changes
// See the SduiController section for the full pattern with patchNode
BlocListener<CartBloc, CartState>(
  listener: (context, state) {
    controller.patchNode('cart_badge', {'count': '${state.count}'});
  },
  child: SduiScreen.controlled(controller: controller),
)
```

---

### provider

> [pub.dev/packages/provider](https://pub.dev/packages/provider) — 1 B+ downloads

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/integration_state_mgmt.png" alt="State management integration" width="700" />
</p>

Inject auth tokens and theme styles from `Provider` into `sdui_core`.

```dart
// 1. Provide auth and theme at the top of the widget tree
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider()),
  ],
  child: Consumer2<AuthProvider, ThemeProvider>(
    builder: (context, auth, theme, _) {
      return SduiTheme(
        styles: theme.sduiStyles,   // ThemeProvider exposes Map<String, TextStyle>
        child: SduiScope(
          actionRegistry: _buildActionRegistry(context),
          child: MaterialApp(
            home: SduiScreen(
              url: 'https://api.example.com/layouts/home',
              headers: auth.isLoggedIn
                  ? {'Authorization': 'Bearer ${auth.token}'}
                  : const {},
            ),
          ),
        ),
      );
    },
  ),
)

// 2. Action handler that updates CartProvider
SduiActionRegistry _buildActionRegistry(BuildContext context) =>
    SduiActionRegistry()
      ..register('add_to_cart', (action, ctx) async {
        final cart = ctx.flutterContext.read<CartProvider>();
        cart.add(action.payload['sku'] as String);
        return const SduiActionResult.success();
      });
```

---

### riverpod / flutter_riverpod

> [pub.dev/packages/flutter_riverpod](https://pub.dev/packages/flutter_riverpod) — 600 M+ downloads

```dart
// 1. Define providers
final authTokenProvider = StateProvider<String?>((ref) => null);

final sduiHeadersProvider = Provider<Map<String, String>>((ref) {
  final token = ref.watch(authTokenProvider);
  return token != null ? {'Authorization': 'Bearer $token'} : const {};
});

// 2. Consume in a ConsumerWidget
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final headers = ref.watch(sduiHeadersProvider);
    return SduiScreen(
      url: 'https://api.example.com/layouts/home',
      headers: headers,
    );
  }
}

// 3. Cart notifier driven by SDUI dispatch actions
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

// Wire in main() or a setup function
SduiActionRegistry.defaults
  ..register('add_to_cart', (action, ctx) async {
    // ProviderScope.containerOf lets you read Riverpod providers from
    // a non-ConsumerWidget context such as an action handler.
    final container = ProviderScope.containerOf(ctx.flutterContext);
    container.read(cartProvider.notifier).add(
      action.payload['sku'] as String,
    );
    return const SduiActionResult.success();
  });
```

---

### go_router

> [pub.dev/packages/go_router](https://pub.dev/packages/go_router) — 500 M+ downloads

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/integration_go_router.png" alt="go_router integration" width="650" />
</p>

Replace the built-in `navigate` action handler with one that delegates to `GoRouter`.

```dart
// 1. Define routes
final router = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(path: '/product/:id', builder: (_, state) =>
        ProductScreen(id: state.pathParameters['id']!)),
    GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
    GoRoute(path: '/sale', builder: (_, __) => const SaleScreen()),
  ],
);

// 2. Override the navigate action to use go_router
SduiActionRegistry.defaults
  ..register('navigate', (action, ctx) async {
    final route = action.payload['route'] as String;
    ctx.flutterContext.go(route);
    return const SduiActionResult.success();
  });

// 3. Pass router to MaterialApp
MaterialApp.router(routerConfig: router)

// 4. JSON payload — route field maps directly to go_router path
// { "type": "navigate", "event": "open_product",
//   "payload": { "route": "/product/APPLE-ORG-1KG" } }
```

---

### get_it / injectable

> [pub.dev/packages/get_it](https://pub.dev/packages/get_it) — 500 M+ downloads

<p align="center">
  <img src="https://raw.githubusercontent.com/hrushikeshhd18/sdui_core/main/assets/integration_get_it.png" alt="get_it integration" width="650" />
</p>

Register `SduiWidgetRegistry`, `SduiActionRegistry`, and a custom transport in your service locator so they are shared across the entire app.

```dart
// 1. Register sdui_core components in GetIt
@module
abstract class SduiModule {
  @singleton
  SduiWidgetRegistry get widgetRegistry => SduiWidgetRegistry()
    ..registerAll(createCoreWidgets())
    ..registerAll(createMaterialWidgets())
    ..register('myapp:product_card', _buildProductCard);

  @singleton
  SduiActionRegistry get actionRegistry => SduiActionRegistry()
    ..register('add_to_cart', _handleAddToCart)
    ..register('navigate', _handleNavigate);

  @lazySingleton
  SduiTransport get transport => DioSduiTransport(
    dio: GetIt.I<Dio>(),
  );
}

// 2. Use injected registries wherever a SduiScope is needed
SduiScope(
  registry: GetIt.I<SduiWidgetRegistry>(),
  actionRegistry: GetIt.I<SduiActionRegistry>(),
  child: MaterialApp(
    home: SduiScreen(
      url: '...',
      transport: GetIt.I<SduiTransport>(),
    ),
  ),
)
```

---

### dio — custom transport

> [pub.dev/packages/dio](https://pub.dev/packages/dio) — 500 M+ downloads

Replace the built-in `HttpSduiTransport` with a `Dio`-based transport to get interceptors, auth token refresh, retry logic, and request cancellation.

```dart
class DioSduiTransport implements SduiTransport {
  DioSduiTransport({required this.dio});
  final Dio dio;

  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async {
    final response = await dio.get<Map<String, dynamic>>(
      url,
      options: Options(headers: headers),
    );
    return response.data!;
  }

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) =>
      Stream.fromFuture(fetch(url, headers: headers));

  @override
  Future<void> dispose() async {
    dio.close();
  }
}

// Wire up with interceptors for auth refresh and logging
final dio = Dio()
  ..interceptors.addAll([
    AuthInterceptor(tokenStorage),   // automatically refreshes expired tokens
    LogInterceptor(requestBody: true),
    RetryInterceptor(dio: dio, retries: 3),
  ]);

SduiScreen(
  url: '...',
  transport: DioSduiTransport(dio: dio),
)
```

---

### freezed — typed action payloads

> [pub.dev/packages/freezed](https://pub.dev/packages/freezed) — 300 M+ downloads

Parse action payloads into typed, immutable value objects instead of raw `Map<String, Object?>`.

```dart
// 1. Define typed payload models with freezed
@freezed
class AddToCartPayload with _$AddToCartPayload {
  const factory AddToCartPayload({
    required String sku,
    required int quantity,
    String? variantId,
  }) = _AddToCartPayload;

  factory AddToCartPayload.fromJson(Map<String, Object?> json) =>
      _$AddToCartPayloadFromJson(json);
}

// 2. Parse inside the action handler
SduiActionRegistry.defaults.register('add_to_cart', (action, ctx) async {
  final payload = AddToCartPayload.fromJson(action.payload);
  await CartRepository.instance.add(
    sku: payload.sku,
    quantity: payload.quantity,
    variantId: payload.variantId,
  );
  return const SduiActionResult.success();
});
```

---

### firebase_remote_config — dynamic layout URLs

> [pub.dev/packages/firebase_remote_config](https://pub.dev/packages/firebase_remote_config) — 400 M+ downloads

Use Remote Config to control which layout URL the app fetches — roll out new layouts gradually or roll back instantly.

```dart
Future<String> getLayoutUrl(String screenKey) async {
  final rc = FirebaseRemoteConfig.instance;
  await rc.fetchAndActivate();
  return rc.getString('sdui_url_$screenKey');
}

// In your widget
FutureBuilder<String>(
  future: getLayoutUrl('home'),
  builder: (context, snap) {
    if (!snap.hasData) return const SplashScreen();
    return SduiScreen(url: snap.data!);
  },
)
```

---

### shared_preferences — manual cache seeding

> [pub.dev/packages/shared_preferences](https://pub.dev/packages/shared_preferences) — 1.2 B+ downloads

`SduiCache` already uses `shared_preferences` internally. If you need to seed the cache at startup (e.g. from a bundled JSON asset), write directly to the same key format.

```dart
Future<void> seedCacheFromAsset(String url, String assetPath) async {
  final prefs = await SharedPreferences.getInstance();
  final json = await rootBundle.loadString(assetPath);
  // sdui_core stores cache under the key 'sdui_cache_<url>'
  await prefs.setString('sdui_cache_$url', json);
}

// Call before SduiCache.init() in main()
await seedCacheFromAsset(
  'https://api.example.com/layouts/home',
  'assets/seed/home.json',
);
await SduiCache.init();
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
| `sdui:image` | `Image.network` | `url`, `fit`, `width`, `height` |
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
