import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:sdui_core/src/models/sdui_node.dart';

/// A debug-only widget that wraps a rendered SDUI node and shows an inspector
/// overlay on long-press.
///
/// Enable globally before runApp:
/// ```dart
/// SduiDebugOverlay.enabled = true; // no-op in release builds
/// ```
///
/// The overlay displays the node id, type, version, tree path, and prop/action
/// counts — useful when debugging custom widgets or unexpected layouts.
///
/// In release builds ([kReleaseMode]) this widget always passes through the
/// child unchanged, regardless of [enabled].
class SduiDebugOverlay extends StatefulWidget {
  /// Creates a [SduiDebugOverlay].
  const SduiDebugOverlay({
    super.key,
    required this.node,
    required this.nodePath,
    required this.child,
  });

  final SduiNode node;
  final String nodePath;
  final Widget child;

  /// Whether the debug overlay is active.  Flipped to `false` in release
  /// mode unconditionally.
  static bool enabled = false;

  @override
  State<SduiDebugOverlay> createState() => _SduiDebugOverlayState();
}

class _SduiDebugOverlayState extends State<SduiDebugOverlay> {
  OverlayEntry? _entry;

  void _showInspector() {
    _entry?.remove();
    final node = widget.node;
    _entry = OverlayEntry(
      builder: (ctx) => _InspectorPanel(
        node: node,
        nodePath: widget.nodePath,
        onDismiss: _dismiss,
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _dismiss() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _dismiss();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode || !SduiDebugOverlay.enabled) return widget.child;
    return GestureDetector(
      onLongPress: _showInspector,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

class _InspectorPanel extends StatelessWidget {
  const _InspectorPanel({
    required this.node,
    required this.nodePath,
    required this.onDismiss,
  });

  final SduiNode node;
  final String nodePath;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final childCount =
        node is SduiParentNode ? (node as SduiParentNode).children.length : 0;

    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Positioned(
            bottom: 40,
            left: 16,
            right: 16,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF1E1E2E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'SDUI Inspector',
                          style: TextStyle(
                            color: Color(0xFF89B4FA),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: onDismiss,
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFCDD6F4),
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _row('id', node.id),
                    _row('type', node.type),
                    _row('version', '${node.version}'),
                    _row('path', nodePath),
                    _row('props', '${node.props.length}'),
                    _row('actions', '${node.actions.length}'),
                    if (childCount > 0) _row('children', '$childCount'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6C7086),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFCDD6F4),
                  fontSize: 11,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
}
