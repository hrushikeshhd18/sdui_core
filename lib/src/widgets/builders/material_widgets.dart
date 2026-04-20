import 'package:flutter/material.dart';

import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/models/sdui_props.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';
import 'package:sdui_core/src/utils/sdui_icons.dart';

/// Returns Material 3 widget builders.
///
/// Register in addition to `createCoreWidgets`:
/// ```dart
/// SduiWidgetRegistry.defaults
///   ..registerAll(createCoreWidgets())
///   ..registerAll(createMaterialWidgets());
/// ```
Map<String, SduiWidgetBuilder> createMaterialWidgets() => {
      'sdui:list_tile': _buildListTile,
      'sdui:switch_tile': _buildSwitchTile,
      'sdui:progress': _buildProgress,
      'sdui:fab': _buildFab,
      'sdui:bottom_nav': _buildBottomNav,
      'sdui:nav_rail': _buildNavRail,
      'sdui:drawer': _buildDrawer,
      'sdui:app_bar': _buildAppBar,
      'sdui:search_bar': _buildSearchBar,
      'sdui:tab_bar': _buildTabBar,
      'sdui:bottom_sheet': _buildBottomSheetPlaceholder,
      'sdui:dialog': _buildDialogPlaceholder,
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

Widget _buildListTile(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return ListTile(
    title: Text(p.getString('title')),
    subtitle: p.getStringOrNull('subtitle') != null
        ? Text(p.getString('subtitle'))
        : null,
    leading: p.getStringOrNull('icon') != null
        ? Icon(SduiIcons.fromName(p.getString('icon')))
        : null,
    trailing: p.getStringOrNull('trailing') != null
        ? Icon(SduiIcons.fromName(p.getString('trailing')))
        : null,
    onTap: node.actions.containsKey('onTap')
        ? () => _fire('onTap', node, ctx)
        : null,
  );
}

Widget _buildSwitchTile(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return SwitchListTile.adaptive(
    title: Text(p.getString('title')),
    subtitle: p.getStringOrNull('subtitle') != null
        ? Text(p.getString('subtitle'))
        : null,
    value: p.getBool('value'),
    onChanged: (_) => _fire('onChange', node, ctx),
  );
}

Widget _buildProgress(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final circular = p.getString('variant') == 'circular';
  final value = p.getDoubleOrNull('value');
  if (circular) {
    return CircularProgressIndicator.adaptive(value: value);
  }
  return LinearProgressIndicator(value: value);
}

Widget _buildFab(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final label = p.getStringOrNull('label');
  final iconName = p.getString('icon', fallback: 'add');

  if (label != null) {
    return FloatingActionButton.extended(
      onPressed: () => _fire('onTap', node, ctx),
      label: Text(label),
      icon: Icon(SduiIcons.fromName(iconName)),
    );
  }
  return FloatingActionButton(
    onPressed: () => _fire('onTap', node, ctx),
    child: Icon(SduiIcons.fromName(iconName)),
  );
}

Widget _buildBottomNav(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final items = p.getList<NavigationDestination>(
    'items',
    (v) {
      if (v is! Map) {
        return const NavigationDestination(icon: Icon(Icons.home), label: '');
      }
      final m = SduiProps(Map<String, Object?>.from(v));
      return NavigationDestination(
        icon: Icon(SduiIcons.fromName(m.getString('icon', fallback: 'home'))),
        label: m.getString('label'),
      );
    },
  );
  return NavigationBar(
    selectedIndex: p.getInt('selectedIndex'),
    destinations: items,
    onDestinationSelected: (_) => _fire('onSelect', node, ctx),
  );
}

Widget _buildNavRail(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final items = p.getList<NavigationRailDestination>(
    'items',
    (v) {
      if (v is! Map) {
        return const NavigationRailDestination(
          icon: Icon(Icons.home),
          label: Text(''),
        );
      }
      final m = SduiProps(Map<String, Object?>.from(v));
      return NavigationRailDestination(
        icon: Icon(SduiIcons.fromName(m.getString('icon', fallback: 'home'))),
        label: Text(m.getString('label')),
      );
    },
  );
  return NavigationRail(
    destinations: items,
    selectedIndex: p.getInt('selectedIndex'),
    onDestinationSelected: (_) => _fire('onSelect', node, ctx),
  );
}

Widget _buildDrawer(SduiNode node, SduiBuildContext ctx) {
  final children = ctx.childWidgets(node);
  return Drawer(
    child: ListView(children: children),
  );
}

Widget _buildAppBar(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return AppBar(
    title: Text(p.getString('title')),
    backgroundColor: p.getColorOrNull('backgroundColor'),
    foregroundColor: p.getColorOrNull('foregroundColor'),
    elevation: p.getDoubleOrNull('elevation'),
    actions: children,
  );
}

Widget _buildSearchBar(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  return SearchBar(
    hintText: p.getString('hint', fallback: 'Search'),
    leading: const Icon(Icons.search),
  );
}

Widget _buildTabBar(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final tabs = p.getList<Tab>(
    'tabs',
    (v) {
      if (v is! Map) return const Tab(text: '');
      final m = SduiProps(Map<String, Object?>.from(v));
      return Tab(text: m.getString('label'));
    },
  );
  final children = ctx.childWidgets(node);
  return DefaultTabController(
    length: tabs.length,
    child: Column(
      children: [
        TabBar(tabs: tabs),
        if (children.isNotEmpty)
          Expanded(child: TabBarView(children: children)),
      ],
    ),
  );
}

Widget _buildBottomSheetPlaceholder(SduiNode node, SduiBuildContext ctx) {
  final children = ctx.childWidgets(node);
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: children,
  );
}

Widget _buildDialogPlaceholder(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final children = ctx.childWidgets(node);
  return AlertDialog(
    title:
        p.getStringOrNull('title') != null ? Text(p.getString('title')) : null,
    content: children.isNotEmpty ? children.first : null,
  );
}
