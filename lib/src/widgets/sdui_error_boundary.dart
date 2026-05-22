import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/models/sdui_node.dart';

/// Wraps an SDUI widget subtree with error handling.
///
/// If the wrapped widget throws an exception during build, this widget catches
/// it and displays an error tile instead of crashing the entire screen.
///
/// Used internally by `SduiRenderer` when rendering nodes, and can be manually
/// applied by custom widget builders for extra safety.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:error_boundary",
///   "id": "safe_container",
///   "version": 1,
///   "props": {},
///   "actions": {},
///   "children": [
///     {
///       "type": "some:risky_widget",
///       "id": "risky",
///       "version": 1,
///       "props": {},
///       "actions": {}
///     }
///   ]
/// }
/// ```
///
/// Example (programmatic usage):
/// ```dart
/// Widget myComplexBuilder(SduiNode node, SduiBuildContext ctx) {
///   return SduiErrorBoundary(
///     node: node,
///     child: MyComplexWidget(data: node.props),
///     onError: (e, stack) => crashReporter.capture(e, stackTrace: stack),
///   );
/// }
/// ```
class SduiErrorBoundary extends StatefulWidget {
  /// Creates an [SduiErrorBoundary].
  const SduiErrorBoundary({
    super.key,
    required this.node,
    required this.child,
    this.onError,
  });

  /// The SDUI node being rendered (for error context).
  final SduiNode node;

  /// The widget to wrap and protect.
  final Widget child;

  /// Optional callback fired when an exception is caught.
  ///
  /// Useful for logging, analytics, or crash reporting:
  /// ```dart
  /// onError: (e, stack) => crashReporter.capture(e, stackTrace: stack),
  /// ```
  final void Function(Object error, StackTrace stack)? onError;

  @override
  State<SduiErrorBoundary> createState() => _SduiErrorBoundaryState();
}

class _SduiErrorBoundaryState extends State<SduiErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorTile(
        node: widget.node,
        error: _error!,
        stackTrace: _stackTrace,
      );
    }

    return _ErrorCapture(
      onError: _handleError,
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stack) {
    setState(() {
      _error = error;
      _stackTrace = stack;
    });
    widget.onError?.call(error, stack);
  }
}

/// Captures render errors from child widgets.
///
/// Uses a custom [ErrorWidget] builder to intercept exceptions.
class _ErrorCapture extends StatefulWidget {
  const _ErrorCapture({
    required this.onError,
    required this.child,
  });

  final void Function(Object, StackTrace) onError;
  final Widget child;

  @override
  State<_ErrorCapture> createState() => _ErrorCaptureState();
}

class _ErrorCaptureState extends State<_ErrorCapture> {
  late ErrorWidgetBuilder _previousErrorBuilder;

  @override
  void initState() {
    super.initState();
    // Store the current error builder
    _previousErrorBuilder = ErrorWidget.builder;
    // Set our custom error builder
    ErrorWidget.builder = (FlutterErrorDetails details) {
      widget.onError(details.exception, details.stack ?? StackTrace.current);
      return _ErrorWidget(details: details);
    };
  }

  @override
  void dispose() {
    ErrorWidget.builder = _previousErrorBuilder;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Minimal error display widget.
class _ErrorWidget extends StatelessWidget {
  const _ErrorWidget({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 100,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Material(
            color: Colors.red[50],
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(Icons.error_outline, color: Colors.red[700]),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Widget Error',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        details.exception.toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.red[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// Error tile displayed when a node fails to render.
///
/// Shows the node type, ID, error message, and (in debug mode) a stack trace.
class _ErrorTile extends StatefulWidget {
  const _ErrorTile({
    required this.node,
    required this.error,
    this.stackTrace,
  });

  final SduiNode node;
  final Object error;
  final StackTrace? stackTrace;

  @override
  State<_ErrorTile> createState() => _ErrorTileState();
}

class _ErrorTileState extends State<_ErrorTile> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;
    final errorColor = isDarkMode ? const Color(0xFFEF5350) : Colors.red[600]!;
    final bgColor = isDarkMode
        ? const Color(0xFF1A1A1A).withValues(alpha: 0.8)
        : Colors.red[50]!;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: errorColor, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: errorColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'SDUI Error: ${widget.node.type}',
                  style: TextStyle(
                    color: errorColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ID: ${widget.node.id}',
            style: TextStyle(
              color: errorColor.withValues(alpha: 0.8),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getErrorMessage(widget.error),
              style: TextStyle(
                color: errorColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (kDebugMode && widget.stackTrace != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => setState(() => _showDetails = !_showDetails),
              child: Row(
                children: [
                  Icon(
                    _showDetails ? Icons.expand_less : Icons.expand_more,
                    color: errorColor,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _showDetails ? 'Hide details' : 'Show details',
                    style: TextStyle(
                      color: errorColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (_showDetails) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: errorColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.stackTrace.toString(),
                  style: TextStyle(
                    color: errorColor,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 10,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is SduiException) {
      return '[${error.code}] ${error.message}';
    }
    return error.toString();
  }
}
