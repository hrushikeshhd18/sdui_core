## 0.2.0

* **Breaking**: `SduiWidgetRegistry` and `SduiActionRegistry` are no longer singletons. Use `SduiWidgetRegistry()` for fresh instances; `SduiWidgetRegistry.defaults` / `SduiActionRegistry.defaults` for shared defaults.
* **Breaking**: `SduiParser.parseAsync` renamed to `SduiParser.parseString`.
* **Breaking**: `SduiWidgetRegistry.resolve` now requires named parameter `nodePath`.
* **New**: Abstract `SduiTransport` interface with `HttpSduiTransport` (retry/backoff) and `WebSocketSduiTransport` (auto-reconnect).
* **New**: `SduiCache` — stale-while-revalidate caching backed by `shared_preferences`.
* **New**: `SduiValidator` — full-tree validation with structured error codes before parsing.
* **New**: `SduiDiffer` — incremental tree diff by node id+version with move detection.
* **New**: `SduiProps` — type-safe prop accessor with color, edge-insets, alignment helpers.
* **New**: `SduiWidget` — render a pre-parsed node directly without a network request.
* **New**: 7-state `SduiScreen` machine with `transport`, `pullToRefresh`, `onLoad`, `onError`, `onEvent`, `onRefresh` parameters.
* **New**: Action middleware chain via `SduiActionRegistry.addMiddleware`.
* **New**: Action debouncing via `SduiAction.debounceMs`.
* **New**: Namespace wildcard resolution (`myapp:*`) in `SduiWidgetRegistry`.
* **New**: Material 3 widget builders (`createMaterialWidgets()`): list_tile, switch_tile, progress, fab, bottom_nav, nav_rail, drawer, app_bar, search_bar, tab_bar, bottom_sheet, dialog.
* **New**: Cupertino widget builders (`createCupertinoWidgets()`): button, nav_bar, list_tile, switch, slider, activity_indicator, dialog.
* **New**: 10 additional core widget types: safe_area, aspect_ratio, fitted_box, clip_r_rect, opacity, transform_scale, hero, badge, chip, placeholder.
* **New**: `SduiLogger` with category-based debug logging.
* **New**: `SduiIcons` with 100+ icon name mappings.
* **New**: Color and context extensions (`SduiColorParsing`, `SduiContextExtension`).
* **New**: `SduiCacheException` (SDUI_006) in the sealed exception hierarchy.
* **New**: `SduiActionRegistry.withEventInterceptor` for analytics via `SduiScreen.onEvent`.
* All node types are `@immutable` with `copyWith`, `==`, `hashCode`, and `debugFillProperties`.
* 171 tests across unit, widget, and integration suites.
* GitHub Actions CI matrix (stable + beta, 3 OS).

## 0.1.0

* Initial release of `sdui_core`.
* JSON-in, native-Flutter-out rendering engine.
* 18 built-in widget types: text, image, container, column, row, stack, button, icon, divider, spacer, grid, list, card, padding, center, expanded, visibility, inkwell.
* `SduiScreen` — 3-line minimum integration.
* `SduiWidgetRegistry` and `SduiActionRegistry` singletons with custom extension points.
* `SduiParser` with background isolate support via `parseAsync`.
* `SduiKeyManager` for deterministic keying and version-based diffing.
* `SduiScope` InheritedWidget for zero-prop-drilling.
* 5 built-in action types: dispatch, navigate, open_url, copy_to_clipboard, show_snackbar.
* Typed exception hierarchy: `SduiParseException`, `SduiNetworkException`, `SduiVersionException`, `SduiUnknownWidgetException`, `SduiActionException`.
* RepaintBoundary at every `SduiScreen` root; opt-in isolation per-subtree via `"isolateRepaint": true`.
* Auto-refresh support via `refreshInterval`.
