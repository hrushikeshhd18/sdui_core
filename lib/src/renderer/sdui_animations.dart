import 'package:flutter/widgets.dart';

import 'package:sdui_core/src/models/sdui_node.dart';

/// Applies transition animations to SDUI nodes.
///
/// Inspired by DivKit's `transition_in`, `transition_out`, and
/// `transition_change` system. Nodes can declare animations in their props:
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:column",
///   "id": "animated_col",
///   "version": 1,
///   "props": {
///     "transition_in": {
///       "type": "fade",
///       "duration": 300,
///       "delay": 0
///     },
///     "transition_change": {
///       "type": "slide",
///       "duration": 200,
///       "direction": "right"
///     }
///   },
///   "actions": {},
///   "children": [...]
/// }
/// ```
///
/// Supported transition types: `fade`, `slide`, `scale`, `size`.
abstract final class SduiAnimations {
  /// Wraps [child] in an animated transition based on [node]'s props.
  ///
  /// Returns the child wrapped in the appropriate transition widget, or the
  /// child directly if no animations are configured.
  static Widget wrapWithTransition({
    required Widget child,
    required SduiNode node,
    required Key key,
  }) {
    final props = node.props;

    // Check for transition_in
    final transitionIn = props['transition_in'];
    if (transitionIn is Map) {
      return _buildTransition(
        child: child,
        config: Map<String, Object?>.from(transitionIn),
        key: key,
      );
    }

    // Check for transition_change
    final transitionChange = props['transition_change'];
    if (transitionChange is Map) {
      return _buildTransition(
        child: child,
        config: Map<String, Object?>.from(transitionChange),
        key: key,
      );
    }

    // Check for transition_out
    final transitionOut = props['transition_out'];
    if (transitionOut is Map) {
      return _buildTransition(
        child: child,
        config: Map<String, Object?>.from(transitionOut),
        key: key,
      );
    }

    return child;
  }

  static Widget _buildTransition({
    required Widget child,
    required Map<String, Object?> config,
    required Key key,
  }) {
    final type = (config['type'] as String?) ?? 'fade';
    final durationMs = (config['duration'] as num?)?.toInt() ?? 300;
    final delayMs = (config['delay'] as num?)?.toInt() ?? 0;
    final direction = (config['direction'] as String?) ?? 'left';

    final duration = Duration(milliseconds: durationMs);
    final delay = Duration(milliseconds: delayMs);

    switch (type) {
      case 'fade':
        return _FadeTransition(
          key: key,
          duration: duration,
          delay: delay,
          child: child,
        );
      case 'slide':
        return _SlideTransition(
          key: key,
          duration: duration,
          delay: delay,
          direction: direction,
          child: child,
        );
      case 'scale':
        return _ScaleTransition(
          key: key,
          duration: duration,
          delay: delay,
          child: child,
        );
      case 'size':
        return _SizeTransition(
          key: key,
          duration: duration,
          delay: delay,
          child: child,
        );
      default:
        return child;
    }
  }
}

// ---------------------------------------------------------------------------
// Transition implementations
// ---------------------------------------------------------------------------

class _FadeTransition extends StatefulWidget {
  const _FadeTransition({
    super.key,
    required this.duration,
    required this.delay,
    required this.child,
  });

  final Duration duration;
  final Duration delay;
  final Widget child;

  @override
  State<_FadeTransition> createState() => _FadeTransitionState();
}

class _FadeTransitionState extends State<_FadeTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    Future.delayed(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _animation, child: widget.child);
}

class _SlideTransition extends StatefulWidget {
  const _SlideTransition({
    super.key,
    required this.duration,
    required this.delay,
    required this.direction,
    required this.child,
  });

  final Duration duration;
  final Duration delay;
  final String direction;
  final Widget child;

  @override
  State<_SlideTransition> createState() => _SlideTransitionState();
}

class _SlideTransitionState extends State<_SlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    final begin = switch (widget.direction) {
      'left' => const Offset(-1.0, 0.0),
      'right' => const Offset(1.0, 0.0),
      'top' => const Offset(0.0, -1.0),
      'bottom' => const Offset(0.0, 1.0),
      _ => const Offset(-1.0, 0.0),
    };
    _animation = Tween<Offset>(begin: begin, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    Future.delayed(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SlideTransition(position: _animation, child: widget.child);
}

class _ScaleTransition extends StatefulWidget {
  const _ScaleTransition({
    super.key,
    required this.duration,
    required this.delay,
    required this.child,
  });

  final Duration duration;
  final Duration delay;
  final Widget child;

  @override
  State<_ScaleTransition> createState() => _ScaleTransitionState();
}

class _ScaleTransitionState extends State<_ScaleTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    Future.delayed(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _animation, child: widget.child);
}

class _SizeTransition extends StatefulWidget {
  const _SizeTransition({
    super.key,
    required this.duration,
    required this.delay,
    required this.child,
  });

  final Duration duration;
  final Duration delay;
  final Widget child;

  @override
  State<_SizeTransition> createState() => _SizeTransitionState();
}

class _SizeTransitionState extends State<_SizeTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    Future.delayed(widget.delay, _controller.forward);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SizeTransition(sizeFactor: _animation, child: widget.child);
}
