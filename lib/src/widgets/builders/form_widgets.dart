import 'package:flutter/material.dart';

import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/models/sdui_props.dart';
import 'package:sdui_core/src/registry/action_registry.dart';
import 'package:sdui_core/src/registry/widget_registry.dart';

/// Returns form-related widget builders for text input, selection, and feedback.
///
/// Register in addition to `createCoreWidgets`:
/// ```dart
/// SduiWidgetRegistry.defaults
///   ..registerAll(createCoreWidgets())
///   ..registerAll(createFormWidgets());
/// ```
Map<String, SduiWidgetBuilder> createFormWidgets() => {
      'sdui:text_field': _buildTextField,
      'sdui:checkbox': _buildCheckbox,
      'sdui:checkbox_list_tile': _buildCheckboxListTile,
      'sdui:radio': _buildRadio,
      'sdui:radio_list_tile': _buildRadioListTile,
      'sdui:slider': _buildSlider,
      'sdui:range_slider': _buildRangeSlider,
      'sdui:switch': _buildSwitch,
      'sdui:dropdown': _buildDropdown,
    };

Future<void> _fire(String key, SduiNode node, SduiBuildContext ctx) async {
  final action = node.actions[key];
  if (action == null) return;
  final actionCtx = SduiActionContext(
    flutterContext: ctx.flutterContext,
    nodeProps: node.props,
    nodePath: ctx.nodePath,
    navigatorKey: ctx.navigatorKey,
  );
  await ctx.actionRegistry.dispatch(action.event, action, actionCtx);
}

/// Builds a [TextField] widget.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:text_field",
///   "id": "email_input",
///   "version": 1,
///   "props": {
///     "label": "Email Address",
///     "hint": "user@example.com",
///     "variant": "outlined",
///     "enabled": true,
///     "obscureText": false,
///     "minLines": 1,
///     "maxLines": 1,
///     "maxLength": 254,
///     "keyboardType": "email",
///     "textAlign": "start"
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "validate_email", "payload": {} },
///     "onSubmitted": { "type": "dispatch", "event": "submit_form", "payload": {} }
///   }
/// }
/// ```
Widget _buildTextField(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final label = p.getStringOrNull('label');
  final hint = p.getStringOrNull('hint');
  final enabled = p.getBool('enabled', fallback: true);
  final obscureText = p.getBool('obscureText');
  final readOnly = p.getBool('readOnly');
  final maxLines = p.getInt('maxLines', fallback: 1);
  final minLines = p.getInt('minLines', fallback: 1);
  final maxLength = p.getInt('maxLength');
  final textAlign = p.getString('textAlign', fallback: 'start');
  final variant = p.getString('variant', fallback: 'outlined');
  final keyboardTypeStr = p.getString('keyboardType', fallback: 'text');

  final keyboardType = _parseKeyboardType(keyboardTypeStr);
  final textAlignValue = _parseTextAlign(textAlign);

  final decoration = InputDecoration(
    labelText: label,
    hintText: hint,
    border: variant == 'filled'
        ? const OutlineInputBorder()
        : variant == 'underline'
            ? const UnderlineInputBorder()
            : const OutlineInputBorder(),
    enabled: enabled,
  );

  return TextField(
    enabled: enabled && !readOnly,
    obscureText: obscureText,
    readOnly: readOnly,
    maxLines: obscureText ? 1 : maxLines,
    minLines: minLines,
    maxLength: maxLength > 0 ? maxLength : null,
    textAlign: textAlignValue,
    keyboardType: keyboardType,
    decoration: decoration,
    onChanged: (_) => _fire('onChange', node, ctx),
    onSubmitted: (_) => _fire('onSubmitted', node, ctx),
  );
}

/// Builds a standalone [Checkbox] widget.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:checkbox",
///   "id": "terms_check",
///   "version": 1,
///   "props": {
///     "value": false,
///     "tristate": false,
///     "enabled": true
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "toggle_terms", "payload": {} }
///   }
/// }
/// ```
Widget _buildCheckbox(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final value = p.getBool('value');
  final tristate = p.getBool('tristate');
  final enabled = p.getBool('enabled', fallback: true);

  return Checkbox(
    value: value,
    tristate: tristate,
    onChanged: enabled ? (_) => _fire('onChange', node, ctx) : null,
  );
}

/// Builds a [CheckboxListTile] with label.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:checkbox_list_tile",
///   "id": "subscribe_check",
///   "version": 1,
///   "props": {
///     "title": "Subscribe to newsletter",
///     "subtitle": "Receive weekly updates",
///     "value": false,
///     "enabled": true
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "toggle_subscription", "payload": {} }
///   }
/// }
/// ```
Widget _buildCheckboxListTile(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final title = p.getString('title');
  final subtitle = p.getStringOrNull('subtitle');
  final value = p.getBool('value');
  final enabled = p.getBool('enabled', fallback: true);

  return CheckboxListTile(
    title: Text(title),
    subtitle: subtitle != null ? Text(subtitle) : null,
    value: value,
    onChanged: enabled ? (_) => _fire('onChange', node, ctx) : null,
  );
}

/// Builds a standalone [Radio] widget.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:radio",
///   "id": "shipping_standard",
///   "version": 1,
///   "props": {
///     "value": "standard",
///     "groupValue": "express",
///     "enabled": true
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "select_shipping", "payload": {} }
///   }
/// }
/// ```
Widget _buildRadio(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final value = p.getString('value');
  final groupValue = p.getString('groupValue');
  final enabled = p.getBool('enabled', fallback: true);

  // ignore: deprecated_member_use
  return Radio<String>(
    value: value,
    // ignore: deprecated_member_use
    groupValue: groupValue,
    // ignore: deprecated_member_use
    onChanged: enabled ? (_) => _fire('onChange', node, ctx) : null,
  );
}

/// Builds a [RadioListTile] with label.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:radio_list_tile",
///   "id": "payment_credit_card",
///   "version": 1,
///   "props": {
///     "title": "Credit Card",
///     "subtitle": "Visa, Mastercard, Amex",
///     "value": "credit_card",
///     "groupValue": "paypal",
///     "enabled": true
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "select_payment", "payload": {} }
///   }
/// }
/// ```
Widget _buildRadioListTile(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final title = p.getString('title');
  final subtitle = p.getStringOrNull('subtitle');
  final value = p.getString('value');
  final groupValue = p.getString('groupValue');
  final enabled = p.getBool('enabled', fallback: true);

  // ignore: deprecated_member_use
  return RadioListTile<String>(
    title: Text(title),
    subtitle: subtitle != null ? Text(subtitle) : null,
    value: value,
    // ignore: deprecated_member_use
    groupValue: groupValue,
    // ignore: deprecated_member_use
    onChanged: enabled ? (_) => _fire('onChange', node, ctx) : null,
  );
}

/// Builds a [Slider] widget for numeric range selection.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:slider",
///   "id": "price_slider",
///   "version": 1,
///   "props": {
///     "value": 50.0,
///     "min": 0.0,
///     "max": 100.0,
///     "divisions": 10,
///     "label": "Price: \$50",
///     "enabled": true
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "filter_by_price", "payload": {} }
///   }
/// }
/// ```
Widget _buildSlider(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final value = p.getDouble('value');
  final min = p.getDouble('min');
  final max = p.getDouble('max', fallback: 100.0);
  final divisions = p.getInt('divisions');
  final label = p.getStringOrNull('label');
  final enabled = p.getBool('enabled', fallback: true);

  return Slider(
    value: value.clamp(min, max),
    min: min,
    max: max,
    divisions: divisions > 0 ? divisions : null,
    label: label,
    onChanged: enabled ? (_) => _fire('onChange', node, ctx) : null,
  );
}

/// Builds a [RangeSlider] widget for selecting a range of numeric values.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:range_slider",
///   "id": "date_range",
///   "version": 1,
///   "props": {
///     "startValue": 10.0,
///     "endValue": 90.0,
///     "min": 0.0,
///     "max": 100.0,
///     "divisions": 10,
///     "startLabel": "Min: 10",
///     "endLabel": "Max: 90",
///     "enabled": true
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "filter_date_range", "payload": {} }
///   }
/// }
/// ```
Widget _buildRangeSlider(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final startValue = p.getDouble('startValue');
  final endValue = p.getDouble('endValue', fallback: 100.0);
  final min = p.getDouble('min');
  final max = p.getDouble('max', fallback: 100.0);
  final divisions = p.getInt('divisions');
  final startLabel = p.getStringOrNull('startLabel');
  final endLabel = p.getStringOrNull('endLabel');
  final enabled = p.getBool('enabled', fallback: true);

  return RangeSlider(
    values: RangeValues(
      startValue.clamp(min, max),
      endValue.clamp(min, max),
    ),
    min: min,
    max: max,
    divisions: divisions > 0 ? divisions : null,
    labels: RangeLabels(startLabel ?? '', endLabel ?? ''),
    onChanged: enabled ? (_) => _fire('onChange', node, ctx) : null,
  );
}

/// Builds a [Switch] widget for boolean toggles.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:switch",
///   "id": "dark_mode_toggle",
///   "version": 1,
///   "props": {
///     "value": false,
///     "enabled": true
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "toggle_dark_mode", "payload": {} }
///   }
/// }
/// ```
Widget _buildSwitch(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final value = p.getBool('value');
  final enabled = p.getBool('enabled', fallback: true);

  return Switch.adaptive(
    value: value,
    onChanged: enabled ? (_) => _fire('onChange', node, ctx) : null,
  );
}

/// Builds a [DropdownButton] widget for single selection.
///
/// **JSON example:**
/// ```json
/// {
///   "type": "sdui:dropdown",
///   "id": "country_select",
///   "version": 1,
///   "props": {
///     "value": "us",
///     "hint": "Select a country",
///     "enabled": true,
///     "items": [
///       { "label": "United States", "value": "us" },
///       { "label": "Canada", "value": "ca" },
///       { "label": "Mexico", "value": "mx" }
///     ]
///   },
///   "actions": {
///     "onChange": { "type": "dispatch", "event": "select_country", "payload": {} }
///   }
/// }
/// ```
Widget _buildDropdown(SduiNode node, SduiBuildContext ctx) {
  final p = SduiProps(node.props);
  final value = p.getStringOrNull('value');
  final hint = p.getStringOrNull('hint');
  final enabled = p.getBool('enabled', fallback: true);

  final items = <DropdownMenuItem<String>>[];
  final itemsRaw = p['items'] as List?;

  if (itemsRaw != null) {
    for (final itemObj in itemsRaw) {
      if (itemObj is Map) {
        final itemMap = Map<String, Object?>.from(itemObj);
        final label = (itemMap['label'] ?? '') as String;
        final itemValue = (itemMap['value'] ?? '') as String;
        items.add(
          DropdownMenuItem<String>(
            value: itemValue,
            child: Text(label),
          ),
        );
      }
    }
  }

  return DropdownButton<String>(
    value: value,
    hint: hint != null ? Text(hint) : null,
    items: items,
    onChanged: enabled
        ? (selected) {
            if (selected != null) {
              _fire('onChange', node, ctx);
            }
          }
        : null,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

TextInputType _parseKeyboardType(String keyboardType) {
  switch (keyboardType) {
    case 'email':
      return TextInputType.emailAddress;
    case 'phone':
      return TextInputType.phone;
    case 'url':
      return TextInputType.url;
    case 'number':
      return TextInputType.number;
    case 'decimal':
      return const TextInputType.numberWithOptions(decimal: true);
    case 'multiline':
      return TextInputType.multiline;
    case 'name':
      return TextInputType.name;
    case 'datetime':
      return TextInputType.datetime;
    default:
      return TextInputType.text;
  }
}

TextAlign _parseTextAlign(String align) {
  switch (align) {
    case 'center':
      return TextAlign.center;
    case 'end':
      return TextAlign.end;
    case 'justify':
      return TextAlign.justify;
    case 'right':
      return TextAlign.right;
    case 'left':
      return TextAlign.left;
    default:
      return TextAlign.start;
  }
}
