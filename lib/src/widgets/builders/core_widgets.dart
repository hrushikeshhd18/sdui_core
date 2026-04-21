import 'package:flutter/material.dart';

import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/models/sdui_props.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/utils/sdui_icons.dart';
import 'package:sdui_core/src/widgets/sdui_theme.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Returns all 28 built-in core widget builders.
///
/// Register once at startup:
/// ```dart
/// SduiWidgetRegistry.defaults.registerAll(createCoreWidgets());
/// ```
Map<String, SduiWidgetBuilder> createCoreWidgets() => {
      'sdui:text': _buildText,
      'sdui:image': _buildImage,
      'sdui:container': _buildContainer,
      'sdui:column': _buildColumn,
      'sdui:row': _buildRow,
      'sdui:stack': _buildStack,
      'sdui:button': _buildButton,
      'sdui:icon': _buildIcon,
      'sdui:divider': _buildDivider,
      'sdui:spacer': _buildSpacer,
      'sdui:grid': _buildGrid,
      'sdui:list': _buildList,
      'sdui:card': _buildCard,
      'sdui:padding': _buildPaddingWidget,
      'sdui:center': _buildCenter,
      'sdui:expanded': _buildExpanded,
      'sdui:visibility': _buildVisibility,
      'sdui:inkwell': _buildInkWell,
      // New in v0.1.0
      'sdui:safe_area': _buildSafeArea,
      'sdui:aspect_ratio': _buildAspectRatio,
      'sdui:fitted_box': _buildFittedBox,
      'sdui:clip_r_rect': _buildClipRRect,
      'sdui:opacity': _buildOpacity,
      'sdui:transform_scale': _buildTransformScale,
      'sdui:hero': _buildHero,
      'sdui:placeholder': _buildPlaceholder,
      'sdui:badge': _buildBadge,
      'sdui:chip': _buildChip,
    };

// ---------------------------------------------------------------------------
// Action helper
// ---------------------------------------------------------------------------

Future<void> _fireAction(
  String actionKey,
  SduiNode node,
  SduiBuildContext ctx,
) async {
  final action = node.actions[actionKey];
  if (action == null) return;
  final actionCtx = SduiActionContext(
    flutterContext: ctx.flutterContext,
    nodeProps: node.props,
    nodePath: ctx.nodePath,
  );
  await ctx.actionRegistry.dispatch(action.event, action, actionCtx);
}

// ---------------------------------------------------------------------------
// Text style helper
// ---------------------------------------------------------------------------

TextStyle _textStyle(SduiProps p, BuildContext ctx) {
  final named = p.getString('style');

  // Check SduiTheme first — allows server-controlled brand/custom text styles.
  final sduiTheme = SduiTheme.maybeOf(ctx);
  if (named.isNotEmpty && sduiTheme != null) {
    final custom = sduiTheme.resolve(named);
    if (custom != null) {
      return custom.copyWith(
        color: p.getColorOrNull('color'),
        fontSize: p.getDoubleOrNull('fontSize'),
        letterSpacing: p.getDoubleOrNull('letterSpacing'),
        height: p.getDoubleOrNull('lineHeight'),
      );
    }
  }

  final theme = Theme.of(ctx).textTheme;
  final base = switch (named) {
    'display1' || 'displayLarge' => theme.displayLarge ?? const TextStyle(),
    'h1' || 'headlineLarge' => theme.headlineLarge ?? const TextStyle(),
    'h2' || 'headlineMedium' => theme.headlineMedium ?? const TextStyle(),
    'h3' || 'headlineSmall' => theme.headlineSmall ?? const TextStyle(),
    'subtitle' || 'titleMedium' => theme.titleMedium ?? const TextStyle(),
    'body' || 'body1' || 'bodyLarge' => theme.bodyLarge ?? const TextStyle(),
    'body2' || 'bodyMedium' => theme.bodyMedium ?? const TextStyle(),
    'caption' || 'bodySmall' => theme.bodySmall ?? const TextStyle(),
    'label' || 'labelMedium' => theme.labelMedium ?? const TextStyle(),
    'labelSmall' => theme.labelSmall ?? const TextStyle(),
    _ => const TextStyle(),
  };

  final fontWeight = switch (p.getString('fontWeight')) {
    'bold' || 'w700' => FontWeight.w700,
    'w100' => FontWeight.w100,
    'w200' => FontWeight.w200,
    'w300' => FontWeight.w300,
    'w400' => FontWeight.w400,
    'w500' => FontWeight.w500,
    'w600' => FontWeight.w600,
    'w800' => FontWeight.w800,
    'w900' => FontWeight.w900,
    _ => null,
  };

  final overflow = switch (p.getString('overflow')) {
    'ellipsis' => TextOverflow.ellipsis,
    'fade' => TextOverflow.fade,
    _ => TextOverflow.clip,
  };

  return base.copyWith(
    color: p.getColorOrNull('color'),
    fontSize: p.getDoubleOrNull('fontSize'),
    fontWeight: fontWeight,
    overflow: overflow,
    letterSpacing: p.getDoubleOrNull('letterSpacing'),
    height: p.getDoubleOrNull('lineHeight'),
    decoration: p.getBool('underline') ? TextDecoration.underline : null,
  );
}

// ---------------------------------------------------------------------------
// 28 widget builders
// ---------------------------------------------------------------------------

Widget _buildText(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return Text(
    p.getString('text'),
    style: _textStyle(p, ctx.flutterContext),
    maxLines: p.getDoubleOrNull('maxLines')?.toInt(),
    textAlign: p.getTextAlign('textAlign'),
    softWrap: p.getBool('softWrap', fallback: true),
  );
}

Widget _buildImage(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final url = p.getString('url');
  final radius = p.getBorderRadius('borderRadius');

  Widget img = Image.network(
    url,
    width: p.getDoubleOrNull('width'),
    height: p.getDoubleOrNull('height'),
    fit: p.getBoxFit('fit'),
    loadingBuilder: (_, child, progress) => progress == null
        ? child
        : const Center(
            child: SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator.adaptive(strokeWidth: 2),
            ),
          ),
    errorBuilder: (_, __, ___) =>
        const Icon(Icons.broken_image, color: Colors.grey),
  );

  if (radius != BorderRadius.zero) {
    img = ClipRRect(borderRadius: radius, child: img);
  }
  return img;
}

Widget _buildContainer(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return Container(
    width: p.getDoubleOrNull('width'),
    height: p.getDoubleOrNull('height'),
    padding: p.getEdgeInsets('padding'),
    margin: p.getEdgeInsets('margin'),
    decoration: BoxDecoration(
      color: p.getColorOrNull('color'),
      borderRadius: p.getBorderRadius(
                'borderRadius',
              ) ==
              BorderRadius.zero
          ? null
          : p.getBorderRadius('borderRadius'),
    ),
    child: children.isNotEmpty ? children.first : null,
  );
}

Widget _buildColumn(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  final spacing = p.getDouble('spacing');
  return Column(
    mainAxisAlignment: p.getMainAxisAlignment('mainAxisAlignment'),
    crossAxisAlignment: p.getCrossAxisAlignment(
      'crossAxisAlignment',
      fallback: CrossAxisAlignment.start,
    ),
    mainAxisSize: p.getMainAxisSize('mainAxisSize'),
    children: spacing > 0
        ? _intersperse(children, SizedBox(height: spacing))
        : children,
  );
}

Widget _buildRow(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  final spacing = p.getDouble('spacing');
  return Row(
    mainAxisAlignment: p.getMainAxisAlignment('mainAxisAlignment'),
    crossAxisAlignment: p.getCrossAxisAlignment(
      'crossAxisAlignment',
    ),
    mainAxisSize: p.getMainAxisSize('mainAxisSize'),
    children: spacing > 0
        ? _intersperse(children, SizedBox(width: spacing))
        : children,
  );
}

List<Widget> _intersperse(List<Widget> items, Widget sep) {
  if (items.length <= 1) return items;
  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(items[i]);
    if (i < items.length - 1) result.add(sep);
  }
  return result;
}

Widget _buildStack(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return Stack(
    alignment: p.getAlignment('alignment'),
    children: ctx.childWidgets(node),
  );
}

Widget _buildButton(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final label = p.getString('label');
  final variant = p.getString('variant', fallback: 'elevated');
  final platform = p.getString('platform');
  void onTap() => _fireAction('onTap', node, ctx);

  if (platform == 'adaptive') {
    // Fall through to Material on non-Apple platforms.
  }

  final child = Text(label);
  return switch (variant) {
    'outlined' => OutlinedButton(onPressed: onTap, child: child),
    'text' || 'flat' => TextButton(onPressed: onTap, child: child),
    'filled' => FilledButton(onPressed: onTap, child: child),
    'tonal' => FilledButton.tonal(onPressed: onTap, child: child),
    _ => ElevatedButton(onPressed: onTap, child: child),
  };
}

Widget _buildIcon(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return Icon(
    SduiIcons.fromName(p.getString('name')),
    size: p.getDoubleOrNull('size'),
    color: p.getColorOrNull('color'),
  );
}

Widget _buildDivider(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return Divider(
    height: p.getDoubleOrNull('height'),
    thickness: p.getDoubleOrNull('thickness'),
    color: p.getColorOrNull('color'),
  );
}

Widget _buildSpacer(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final w = p.getDoubleOrNull('width');
  final h = p.getDoubleOrNull('height');
  if (w != null || h != null) return SizedBox(width: w, height: h);
  return Spacer(flex: p.getInt('flex', fallback: 1));
}

Widget _buildGrid(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  final columns = p.getInt('columns', fallback: 2);
  final spacing = p.getDouble('spacing', fallback: 8);
  final ratio = p.getDouble('aspectRatio', fallback: 1.0);
  return GridView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: ratio,
    ),
    itemCount: children.length,
    itemBuilder: (_, i) => children[i],
  );
}

Widget _buildList(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  final axis = p.getAxis('scrollDirection');
  final height = p.getDoubleOrNull('height');
  Widget list = ListView.builder(
    shrinkWrap: axis == Axis.vertical,
    physics: const ClampingScrollPhysics(),
    scrollDirection: axis,
    itemCount: children.length,
    itemBuilder: (_, i) => children[i],
  );
  if (axis == Axis.horizontal && height != null) {
    list = SizedBox(height: height, child: list);
  }
  return list;
}

Widget _buildCard(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  final radius = p.getBorderRadius('borderRadius');
  return Card(
    elevation: p.getDoubleOrNull('elevation'),
    color: p.getColorOrNull('color'),
    shape: radius != BorderRadius.zero
        ? RoundedRectangleBorder(borderRadius: radius)
        : null,
    child: children.isNotEmpty ? children.first : null,
  );
}

Widget _buildPaddingWidget(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return Padding(
    padding: p.getEdgeInsets('padding'),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildCenter(SduiNode node, SduiBuildContext ctx) {
  final children = ctx.childWidgets(node);
  return Center(
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildExpanded(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return Expanded(
    flex: p.getInt('flex', fallback: 1),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildVisibility(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return Visibility(
    visible: p.getBool('visible', fallback: true),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildInkWell(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return InkWell(
    onTap: () => _fireAction('onTap', node, ctx),
    borderRadius: p.getBorderRadius('borderRadius'),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildSafeArea(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return SafeArea(
    top: p.getBool('top', fallback: true),
    bottom: p.getBool('bottom', fallback: true),
    left: p.getBool('left', fallback: true),
    right: p.getBool('right', fallback: true),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildAspectRatio(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return AspectRatio(
    aspectRatio: p.getDouble('ratio', fallback: 1.0),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildFittedBox(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return FittedBox(
    fit: p.getBoxFit('fit', fallback: BoxFit.contain),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildClipRRect(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return ClipRRect(
    borderRadius: p.getBorderRadius('borderRadius'),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildOpacity(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  final opacity = p.getDouble('opacity', fallback: 1.0).clamp(0.0, 1.0);
  final duration = Duration(
    milliseconds: p.getInt('duration', fallback: 300),
  );
  return AnimatedOpacity(
    opacity: opacity,
    duration: duration,
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildTransformScale(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return Transform.scale(
    scale: p.getDouble('scale', fallback: 1.0),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildHero(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return Hero(
    tag: p.getString('tag', fallback: node.id),
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildPlaceholder(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return Placeholder(
    color: p.getColor('color', fallback: Colors.grey),
    strokeWidth: p.getDouble('strokeWidth', fallback: 2.0),
    fallbackWidth: p.getDouble('width', fallback: 400),
    fallbackHeight: p.getDouble('height', fallback: 400),
  );
}

Widget _buildBadge(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  final label = p.getStringOrNull('label');
  return Badge(
    label: label != null ? Text(label) : null,
    child: children.isNotEmpty ? children.first : null,
  );
}

Widget _buildChip(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final label = p.getString('label');
  final hasAction = node.actions.containsKey('onTap');

  if (hasAction) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _fireAction('onTap', node, ctx),
    );
  }

  return Chip(
    label: Text(label),
    backgroundColor: p.getColorOrNull('backgroundColor'),
  );
}
