import 'package:flutter/cupertino.dart';

import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/models/sdui_props.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';

/// Returns Cupertino-style widget builders.
///
/// Register alongside `createCoreWidgets`:
/// ```dart
/// SduiWidgetRegistry.defaults
///   ..registerAll(createCoreWidgets())
///   ..registerAll(createCupertinoWidgets());
/// ```
Map<String, SduiWidgetBuilder> createCupertinoWidgets() => {
      'sdui:cupertino_button': _buildCupertinoButton,
      'sdui:cupertino_nav_bar': _buildCupertinoNavBar,
      'sdui:cupertino_list_tile': _buildCupertinoListTile,
      'sdui:cupertino_switch': _buildCupertinoSwitch,
      'sdui:cupertino_slider': _buildCupertinoSlider,
      'sdui:cupertino_activity': _buildCupertinoActivity,
      'sdui:cupertino_dialog': _buildCupertinoDialog,
    };

Future<void> _fire(String key, SduiNode node, SduiBuildContext ctx) async {
  final action = node.actions[key];
  if (action == null) return;
  final actionCtx = SduiActionContext(
    flutterContext: ctx.flutterContext,
    nodeProps: node.props,
    nodePath: ctx.nodePath,
  );
  await ctx.actionRegistry.dispatch(action.event, action, actionCtx);
}

Widget _buildCupertinoButton(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final filled = p.getString('variant') == 'filled';
  final child = Text(p.getString('label'));
  if (filled) {
    return CupertinoButton.filled(
      onPressed: () => _fire('onTap', node, ctx),
      child: child,
    );
  }
  return CupertinoButton(
    onPressed: () => _fire('onTap', node, ctx),
    child: child,
  );
}

Widget _buildCupertinoNavBar(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return CupertinoNavigationBar(
    middle: Text(p.getString('title')),
  );
}

Widget _buildCupertinoListTile(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return CupertinoListTile(
    title: Text(p.getString('title')),
    subtitle: p.getStringOrNull('subtitle') != null
        ? Text(p.getString('subtitle'))
        : null,
    onTap: node.actions.containsKey('onTap')
        ? () => _fire('onTap', node, ctx)
        : null,
  );
}

Widget _buildCupertinoSwitch(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return CupertinoSwitch(
    value: p.getBool('value'),
    onChanged: (_) => _fire('onChange', node, ctx),
    activeTrackColor:
        p.getColorOrNull('activeColor') ?? CupertinoColors.activeGreen,
  );
}

Widget _buildCupertinoSlider(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return CupertinoSlider(
    value: p.getDouble('value', fallback: 0.5).clamp(
          p.getDouble('min'),
          p.getDouble('max', fallback: 1.0),
        ),
    min: p.getDouble('min'),
    max: p.getDouble('max', fallback: 1.0),
    onChanged: (_) => _fire('onChange', node, ctx),
    activeColor: p.getColorOrNull('activeColor') ?? CupertinoColors.activeBlue,
  );
}

Widget _buildCupertinoActivity(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return CupertinoActivityIndicator(
    radius: p.getDouble('radius', fallback: 10),
    color: p.getColorOrNull('color'),
  );
}

Widget _buildCupertinoDialog(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return CupertinoAlertDialog(
    title:
        p.getStringOrNull('title') != null ? Text(p.getString('title')) : null,
    content: children.isNotEmpty ? children.first : null,
  );
}
