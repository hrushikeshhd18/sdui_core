import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../models/sdui_node.dart';
import '../../registry/action_registry.dart';
import '../../registry/widget_registry.dart';

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Returns a map of all built-in widget builders.
///
/// Register once at startup:
/// ```dart
/// SduiWidgetRegistry.instance.registerAll(createCoreWidgets());
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
    };

// ---------------------------------------------------------------------------
// Helper utilities
// ---------------------------------------------------------------------------

Color? _color(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return Color(raw);
  if (raw is String) {
    final hex = raw.replaceFirst('#', '');
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    if (hex.length == 8) return Color(int.parse(hex, radix: 16));
  }
  return null;
}

EdgeInsets _padding(Map<String, dynamic> props) {
  final all = (props['padding'] as num?)?.toDouble() ??
      (props['all'] as num?)?.toDouble();
  if (all != null) return EdgeInsets.all(all);
  return EdgeInsets.only(
    left: (props['left'] as num?)?.toDouble() ??
        (props['horizontal'] as num?)?.toDouble() ??
        0,
    right: (props['right'] as num?)?.toDouble() ??
        (props['horizontal'] as num?)?.toDouble() ??
        0,
    top: (props['top'] as num?)?.toDouble() ??
        (props['vertical'] as num?)?.toDouble() ??
        0,
    bottom: (props['bottom'] as num?)?.toDouble() ??
        (props['vertical'] as num?)?.toDouble() ??
        0,
  );
}

EdgeInsets _margin(Map<String, dynamic> props) {
  final raw = (props['margin'] as num?)?.toDouble();
  if (raw != null) return EdgeInsets.all(raw);
  return EdgeInsets.only(
    left: (props['marginLeft'] as num?)?.toDouble() ?? 0,
    right: (props['marginRight'] as num?)?.toDouble() ?? 0,
    top: (props['marginTop'] as num?)?.toDouble() ?? 0,
    bottom: (props['marginBottom'] as num?)?.toDouble() ?? 0,
  );
}

MainAxisAlignment _mainAxis(String? raw) => switch (raw) {
      'center' => MainAxisAlignment.center,
      'end' => MainAxisAlignment.end,
      'spaceBetween' => MainAxisAlignment.spaceBetween,
      'spaceAround' => MainAxisAlignment.spaceAround,
      'spaceEvenly' => MainAxisAlignment.spaceEvenly,
      _ => MainAxisAlignment.start,
    };

CrossAxisAlignment _crossAxis(String? raw) => switch (raw) {
      'center' => CrossAxisAlignment.center,
      'end' => CrossAxisAlignment.end,
      'stretch' => CrossAxisAlignment.stretch,
      'baseline' => CrossAxisAlignment.baseline,
      _ => CrossAxisAlignment.start,
    };

TextAlign _textAlign(String? raw) => switch (raw) {
      'center' => TextAlign.center,
      'right' || 'end' => TextAlign.right,
      'justify' => TextAlign.justify,
      _ => TextAlign.left,
    };

TextOverflow _overflow(String? raw) => switch (raw) {
      'ellipsis' => TextOverflow.ellipsis,
      'fade' => TextOverflow.fade,
      'clip' => TextOverflow.clip,
      _ => TextOverflow.clip,
    };

BoxFit _fit(String? raw) => switch (raw) {
      'cover' => BoxFit.cover,
      'contain' => BoxFit.contain,
      'fill' => BoxFit.fill,
      'fitWidth' => BoxFit.fitWidth,
      'fitHeight' => BoxFit.fitHeight,
      'none' => BoxFit.none,
      _ => BoxFit.cover,
    };

Alignment _alignment(String? raw) => switch (raw) {
      'center' => Alignment.center,
      'topLeft' => Alignment.topLeft,
      'topCenter' => Alignment.topCenter,
      'topRight' => Alignment.topRight,
      'bottomLeft' => Alignment.bottomLeft,
      'bottomCenter' => Alignment.bottomCenter,
      'bottomRight' => Alignment.bottomRight,
      'centerLeft' => Alignment.centerLeft,
      'centerRight' => Alignment.centerRight,
      _ => Alignment.center,
    };

TextStyle _textStyle(Map<String, dynamic> props, BuildContext ctx) {
  final named = props['style'] as String?;
  final theme = Theme.of(ctx).textTheme;
  TextStyle base = switch (named) {
    'h1' => theme.headlineLarge ?? const TextStyle(),
    'h2' => theme.headlineMedium ?? const TextStyle(),
    'h3' => theme.headlineSmall ?? const TextStyle(),
    'subtitle' || 'subtitle1' => theme.titleMedium ?? const TextStyle(),
    'body' || 'body1' => theme.bodyLarge ?? const TextStyle(),
    'body2' => theme.bodyMedium ?? const TextStyle(),
    'caption' => theme.bodySmall ?? const TextStyle(),
    'label' => theme.labelMedium ?? const TextStyle(),
    _ => const TextStyle(),
  };

  final color = _color(props['color']);
  final fontSize = (props['fontSize'] as num?)?.toDouble();
  final fontWeight = switch (props['fontWeight'] as String?) {
    'bold' => FontWeight.bold,
    'w100' => FontWeight.w100,
    'w200' => FontWeight.w200,
    'w300' => FontWeight.w300,
    'w400' => FontWeight.w400,
    'w500' => FontWeight.w500,
    'w600' => FontWeight.w600,
    'w700' => FontWeight.w700,
    'w800' => FontWeight.w800,
    'w900' => FontWeight.w900,
    _ => null,
  };

  return base.copyWith(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
  );
}

BorderRadius? _borderRadius(dynamic raw) {
  if (raw == null) return null;
  final r = (raw as num).toDouble();
  return BorderRadius.circular(r);
}

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
// 50 most-used Material icons by name
// ---------------------------------------------------------------------------

const Map<String, IconData> _iconMap = {
  'home': Icons.home,
  'search': Icons.search,
  'person': Icons.person,
  'settings': Icons.settings,
  'favorite': Icons.favorite,
  'favorite_border': Icons.favorite_border,
  'star': Icons.star,
  'star_border': Icons.star_border,
  'shopping_cart': Icons.shopping_cart,
  'add': Icons.add,
  'remove': Icons.remove,
  'close': Icons.close,
  'check': Icons.check,
  'arrow_back': Icons.arrow_back,
  'arrow_forward': Icons.arrow_forward,
  'chevron_right': Icons.chevron_right,
  'chevron_left': Icons.chevron_left,
  'expand_more': Icons.expand_more,
  'expand_less': Icons.expand_less,
  'menu': Icons.menu,
  'more_vert': Icons.more_vert,
  'more_horiz': Icons.more_horiz,
  'edit': Icons.edit,
  'delete': Icons.delete,
  'share': Icons.share,
  'copy': Icons.copy,
  'camera': Icons.camera_alt,
  'image': Icons.image,
  'phone': Icons.phone,
  'email': Icons.email,
  'location': Icons.location_on,
  'map': Icons.map,
  'calendar': Icons.calendar_today,
  'clock': Icons.access_time,
  'notifications': Icons.notifications,
  'lock': Icons.lock,
  'lock_open': Icons.lock_open,
  'visibility': Icons.visibility,
  'visibility_off': Icons.visibility_off,
  'info': Icons.info,
  'warning': Icons.warning,
  'error': Icons.error,
  'help': Icons.help,
  'refresh': Icons.refresh,
  'upload': Icons.upload,
  'download': Icons.download,
  'filter': Icons.filter_list,
  'sort': Icons.sort,
  'check_circle': Icons.check_circle,
  'cancel': Icons.cancel,
};

// ---------------------------------------------------------------------------
// Widget builders (18 types)
// ---------------------------------------------------------------------------

Widget _buildText(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final text = props['text'] as String? ?? '';
  final maxLines = (props['maxLines'] as num?)?.toInt();
  final style = _textStyle(props, ctx.flutterContext);
  return Text(
    text,
    style: style,
    maxLines: maxLines,
    overflow: _overflow(props['overflow'] as String?),
    textAlign: _textAlign(props['textAlign'] as String?),
  );
}

Widget _buildImage(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final url = props['url'] as String? ?? '';
  final width = (props['width'] as num?)?.toDouble();
  final height = (props['height'] as num?)?.toDouble();
  final fit = _fit(props['fit'] as String?);
  final radius = _borderRadius(props['borderRadius']);

  Widget img = CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
  );

  if (radius != null) {
    img = ClipRRect(borderRadius: radius, child: img);
  }
  return img;
}

Widget _buildContainer(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final children = ctx.childWidgets(node);

  return Container(
    width: (props['width'] as num?)?.toDouble(),
    height: (props['height'] as num?)?.toDouble(),
    padding: _padding(props),
    margin: _margin(props),
    decoration: BoxDecoration(
      color: _color(props['color']),
      borderRadius: _borderRadius(props['borderRadius']),
    ),
    child: children.isNotEmpty ? children.first : null,
  );
}

Widget _buildColumn(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final children = ctx.childWidgets(node);
  final spacing = (props['spacing'] as num?)?.toDouble() ?? 0;

  final spaced =
      spacing > 0 ? _interleave(children, SizedBox(height: spacing)) : children;

  return Column(
    mainAxisAlignment: _mainAxis(props['mainAxisAlignment'] as String?),
    crossAxisAlignment: _crossAxis(props['crossAxisAlignment'] as String?),
    mainAxisSize:
        props['mainAxisSize'] == 'min' ? MainAxisSize.min : MainAxisSize.max,
    children: spaced,
  );
}

Widget _buildRow(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final children = ctx.childWidgets(node);
  final spacing = (props['spacing'] as num?)?.toDouble() ?? 0;

  final spaced =
      spacing > 0 ? _interleave(children, SizedBox(width: spacing)) : children;

  return Row(
    mainAxisAlignment: _mainAxis(props['mainAxisAlignment'] as String?),
    crossAxisAlignment: _crossAxis(props['crossAxisAlignment'] as String?),
    mainAxisSize:
        props['mainAxisSize'] == 'min' ? MainAxisSize.min : MainAxisSize.max,
    children: spaced,
  );
}

List<Widget> _interleave(List<Widget> items, Widget separator) {
  if (items.isEmpty) return items;
  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(items[i]);
    if (i < items.length - 1) result.add(separator);
  }
  return result;
}

Widget _buildStack(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final children = ctx.childWidgets(node);
  return Stack(
    alignment: _alignment(props['alignment'] as String?),
    children: children,
  );
}

Widget _buildButton(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final label = props['label'] as String? ?? '';
  final variant = props['variant'] as String? ?? 'elevated';

  void handleTap() => _fireAction('onTap', node, ctx);

  final child = Text(label);
  return switch (variant) {
    'outlined' => OutlinedButton(onPressed: handleTap, child: child),
    'text' => TextButton(onPressed: handleTap, child: child),
    _ => ElevatedButton(onPressed: handleTap, child: child),
  };
}

Widget _buildIcon(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final name = props['name'] as String? ?? '';
  final size = (props['size'] as num?)?.toDouble();
  final color = _color(props['color']);
  final iconData = _iconMap[name] ?? Icons.help_outline;
  return Icon(iconData, size: size, color: color);
}

Widget _buildDivider(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  return Divider(
    height: (props['height'] as num?)?.toDouble(),
    thickness: (props['thickness'] as num?)?.toDouble(),
    color: _color(props['color']),
  );
}

Widget _buildSpacer(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final w = (props['width'] as num?)?.toDouble();
  final h = (props['height'] as num?)?.toDouble();
  if (w != null || h != null) return SizedBox(width: w, height: h);
  return const Spacer();
}

Widget _buildGrid(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final children = ctx.childWidgets(node);
  final columns = (props['columns'] as num?)?.toInt() ?? 2;
  final spacing = (props['spacing'] as num?)?.toDouble() ?? 8;
  final ratio = (props['aspectRatio'] as num?)?.toDouble() ?? 1.0;

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
  final props = node.props;
  final children = ctx.childWidgets(node);
  final horizontal = props['scrollDirection'] == 'horizontal';

  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
    itemCount: children.length,
    itemBuilder: (_, i) => children[i],
  );
}

Widget _buildCard(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final children = ctx.childWidgets(node);
  final radius = _borderRadius(props['borderRadius']);

  return Card(
    elevation: (props['elevation'] as num?)?.toDouble(),
    color: _color(props['color']),
    shape: radius != null
        ? RoundedRectangleBorder(borderRadius: radius)
        : null,
    child: children.isNotEmpty ? children.first : null,
  );
}

Widget _buildPaddingWidget(SduiNode node, SduiBuildContext ctx) {
  final children = ctx.childWidgets(node);
  return Padding(
    padding: _padding(node.props),
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
  final props = node.props;
  final flex = (props['flex'] as num?)?.toInt() ?? 1;
  final children = ctx.childWidgets(node);
  return Expanded(
    flex: flex,
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildVisibility(SduiNode node, SduiBuildContext ctx) {
  final visible = node.props['visible'] as bool? ?? true;
  final children = ctx.childWidgets(node);
  return Visibility(
    visible: visible,
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}

Widget _buildInkWell(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final children = ctx.childWidgets(node);
  final radius = _borderRadius(props['borderRadius']);

  return InkWell(
    onTap: () => _fireAction('onTap', node, ctx),
    borderRadius: radius,
    child: children.isNotEmpty ? children.first : const SizedBox.shrink(),
  );
}
