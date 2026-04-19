import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../exceptions/sdui_exceptions.dart';
import '../models/sdui_node.dart';
import '../parser/sdui_parser.dart';
import '../registry/action_registry.dart';
import '../registry/widget_registry.dart';
import '../renderer/sdui_renderer.dart';
import 'sdui_scope.dart';

/// The primary developer-facing widget.
///
/// Fetches a JSON layout from [url], parses it, and renders the resulting
/// [SduiNode] tree as native Flutter widgets.
///
/// Minimum usage — 3 lines:
/// ```dart
/// SduiScreen(url: 'https://api.example.com/layouts/home')
/// ```
///
/// Full usage:
/// ```dart
/// SduiScreen(
///   url: 'https://api.example.com/layouts/home',
///   headers: {'Authorization': 'Bearer $token'},
///   refreshInterval: const Duration(minutes: 5),
///   loadingBuilder: (ctx) => const MyShimmer(),
///   errorBuilder: (ctx, err) => MyErrorWidget(err.toString()),
///   onEvent: (event, payload) => analytics.track(event, payload),
/// )
/// ```
class SduiScreen extends StatefulWidget {
  /// The URL of the JSON layout to render.
  final String url;

  /// Optional HTTP headers attached to every request (e.g. auth tokens).
  final Map<String, String>? headers;

  /// When set, the screen re-fetches and re-renders the layout at this interval.
  final Duration? refreshInterval;

  /// Replaces the default [CircularProgressIndicator] while loading.
  final WidgetBuilder? loadingBuilder;

  /// Replaces the default error card when a [SduiException] is thrown.
  final Widget Function(BuildContext, SduiException)? errorBuilder;

  /// Shown when the server returns an empty / null layout.
  final WidgetBuilder? emptyBuilder;

  /// When `true` (default), JSON parsing runs in a background [Isolate].
  final bool parseInIsolate;

  /// Called whenever a node dispatches an event, regardless of whether a
  /// handler is registered. Useful for analytics.
  final void Function(String event, Map<String, dynamic> payload)? onEvent;

  /// Optional HTTP client — override in tests to avoid real network calls.
  final http.Client? httpClient;

  /// Creates an [SduiScreen].
  const SduiScreen({
    super.key,
    required this.url,
    this.headers,
    this.refreshInterval,
    this.loadingBuilder,
    this.errorBuilder,
    this.emptyBuilder,
    this.parseInIsolate = true,
    this.onEvent,
    this.httpClient,
  });

  @override
  State<SduiScreen> createState() => _SduiScreenState();
}

class _SduiScreenState extends State<SduiScreen> {
  SduiNode? _node;
  SduiException? _error;
  bool _loading = true;
  Timer? _refreshTimer;
  late http.Client _client;

  @override
  void initState() {
    super.initState();
    _client = widget.httpClient ?? http.Client();
    _fetch();
    if (widget.refreshInterval != null) {
      _refreshTimer = Timer.periodic(widget.refreshInterval!, (_) => _fetch());
    }
  }

  @override
  void didUpdateWidget(SduiScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      setState(() {
        _loading = true;
        _error = null;
        _node = null;
      });
      _fetch();
    }
    if (oldWidget.refreshInterval != widget.refreshInterval) {
      _refreshTimer?.cancel();
      if (widget.refreshInterval != null) {
        _refreshTimer =
            Timer.periodic(widget.refreshInterval!, (_) => _fetch());
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (widget.httpClient == null) _client.close();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final response = await _client.get(
        Uri.parse(widget.url),
        headers: widget.headers,
      );

      if (response.statusCode != 200) {
        throw SduiNetworkException(
          url: widget.url,
          statusCode: response.statusCode,
          message: 'Server returned HTTP ${response.statusCode}.',
        );
      }

      final SduiNode node;
      if (widget.parseInIsolate) {
        node = await SduiParser.parseAsync(response.body);
      } else {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        node = SduiParser.parse(decoded);
      }

      if (mounted) {
        setState(() {
          _node = node;
          _error = null;
          _loading = false;
        });
      }
    } on SduiException catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = SduiNetworkException(
            url: widget.url,
            message: e.toString(),
          );
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator.adaptive());
    }

    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          _DefaultErrorWidget(error: _error!);
    }

    if (_node == null) {
      return widget.emptyBuilder?.call(context) ?? const SizedBox.shrink();
    }

    final scope = SduiScope.maybeOf(context);
    final registry = scope?.registry ?? SduiWidgetRegistry.instance;
    final actionRegistry = scope?.actionRegistry ?? SduiActionRegistry.instance;

    final sdCtx = SduiBuildContext(
      flutterContext: context,
      registry: registry,
      actionRegistry: actionRegistry,
      nodePath: 'root',
    );

    return RepaintBoundary(
      child: SduiRenderer.render(_node!, sdCtx),
    );
  }
}

class _DefaultErrorWidget extends StatelessWidget {
  const _DefaultErrorWidget({required this.error});
  final SduiException error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
