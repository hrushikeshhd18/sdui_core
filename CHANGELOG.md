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
