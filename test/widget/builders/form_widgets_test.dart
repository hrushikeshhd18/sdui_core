import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

import '../../helpers/test_helpers.dart';

void main() {
  group('Form Widgets', () {
    group('sdui:text_field', () {
      testWidgets('renders TextField with label and hint', (tester) async {
        const node = SduiLeafNode(
          id: 'email_input',
          type: 'sdui:text_field',
          version: 1,
          props: {
            'label': 'Email',
            'hint': 'user@example.com',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Email'), findsWidgets); // label
      });

      testWidgets('renders disabled TextField', (tester) async {
        const node = SduiLeafNode(
          id: 'disabled_input',
          type: 'sdui:text_field',
          version: 1,
          props: {
            'enabled': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders obscured TextField for passwords', (tester) async {
        const node = SduiLeafNode(
          id: 'password_input',
          type: 'sdui:text_field',
          version: 1,
          props: {
            'obscureText': true,
            'label': 'Password',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders TextField with email keyboard type', (tester) async {
        const node = SduiLeafNode(
          id: 'email_field',
          type: 'sdui:text_field',
          version: 1,
          props: {
            'keyboardType': 'email',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(TextField), findsOneWidget);
      });

      testWidgets('renders TextField with multiline support', (tester) async {
        const node = SduiLeafNode(
          id: 'textarea',
          type: 'sdui:text_field',
          version: 1,
          props: {
            'maxLines': 5,
            'label': 'Description',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(TextField), findsOneWidget);
      });
    });

    group('sdui:checkbox', () {
      testWidgets('renders standalone Checkbox', (tester) async {
        const node = SduiLeafNode(
          id: 'terms_check',
          type: 'sdui:checkbox',
          version: 1,
          props: {
            'value': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Checkbox), findsOneWidget);
      });

      testWidgets('renders checked Checkbox', (tester) async {
        const node = SduiLeafNode(
          id: 'checked_check',
          type: 'sdui:checkbox',
          version: 1,
          props: {
            'value': true,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Checkbox), findsOneWidget);
      });

      testWidgets('renders disabled Checkbox', (tester) async {
        const node = SduiLeafNode(
          id: 'disabled_check',
          type: 'sdui:checkbox',
          version: 1,
          props: {
            'value': false,
            'enabled': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Checkbox), findsOneWidget);
      });
    });

    group('sdui:checkbox_list_tile', () {
      testWidgets('renders CheckboxListTile with title', (tester) async {
        const node = SduiLeafNode(
          id: 'subscribe_check',
          type: 'sdui:checkbox_list_tile',
          version: 1,
          props: {
            'title': 'Subscribe to newsletter',
            'value': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(CheckboxListTile), findsOneWidget);
        expect(find.text('Subscribe to newsletter'), findsOneWidget);
      });

      testWidgets('renders CheckboxListTile with subtitle', (tester) async {
        const node = SduiLeafNode(
          id: 'subscribe_check',
          type: 'sdui:checkbox_list_tile',
          version: 1,
          props: {
            'title': 'Subscribe',
            'subtitle': 'Receive weekly updates',
            'value': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(CheckboxListTile), findsOneWidget);
        expect(find.text('Subscribe'), findsOneWidget);
        expect(find.text('Receive weekly updates'), findsOneWidget);
      });
    });

    group('sdui:radio', () {
      testWidgets('renders standalone Radio', (tester) async {
        const node = SduiLeafNode(
          id: 'shipping_standard',
          type: 'sdui:radio',
          version: 1,
          props: {
            'value': 'standard',
            'groupValue': 'express',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Radio<String>), findsOneWidget);
      });

      testWidgets('renders selected Radio', (tester) async {
        const node = SduiLeafNode(
          id: 'shipping_express',
          type: 'sdui:radio',
          version: 1,
          props: {
            'value': 'express',
            'groupValue': 'express',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Radio<String>), findsOneWidget);
      });

      testWidgets('renders disabled Radio', (tester) async {
        const node = SduiLeafNode(
          id: 'radio_disabled',
          type: 'sdui:radio',
          version: 1,
          props: {
            'value': 'option1',
            'groupValue': 'option2',
            'enabled': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Radio<String>), findsOneWidget);
      });
    });

    group('sdui:radio_list_tile', () {
      testWidgets('renders RadioListTile with title', (tester) async {
        const node = SduiLeafNode(
          id: 'payment_credit',
          type: 'sdui:radio_list_tile',
          version: 1,
          props: {
            'title': 'Credit Card',
            'value': 'credit_card',
            'groupValue': 'paypal',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(RadioListTile<String>), findsOneWidget);
        expect(find.text('Credit Card'), findsOneWidget);
      });

      testWidgets('renders RadioListTile with subtitle', (tester) async {
        const node = SduiLeafNode(
          id: 'payment_credit',
          type: 'sdui:radio_list_tile',
          version: 1,
          props: {
            'title': 'Credit Card',
            'subtitle': 'Visa, Mastercard, Amex',
            'value': 'credit_card',
            'groupValue': 'paypal',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(RadioListTile<String>), findsOneWidget);
        expect(find.text('Credit Card'), findsOneWidget);
        expect(find.text('Visa, Mastercard, Amex'), findsOneWidget);
      });
    });

    group('sdui:slider', () {
      testWidgets('renders Slider widget', (tester) async {
        const node = SduiLeafNode(
          id: 'price_slider',
          type: 'sdui:slider',
          version: 1,
          props: {
            'value': 50.0,
            'min': 0.0,
            'max': 100.0,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Slider), findsOneWidget);
      });

      testWidgets('renders Slider with divisions', (tester) async {
        const node = SduiLeafNode(
          id: 'quality_slider',
          type: 'sdui:slider',
          version: 1,
          props: {
            'value': 5.0,
            'min': 0.0,
            'max': 10.0,
            'divisions': 10,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Slider), findsOneWidget);
      });

      testWidgets('renders disabled Slider', (tester) async {
        const node = SduiLeafNode(
          id: 'disabled_slider',
          type: 'sdui:slider',
          version: 1,
          props: {
            'value': 50.0,
            'min': 0.0,
            'max': 100.0,
            'enabled': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Slider), findsOneWidget);
      });
    });

    group('sdui:range_slider', () {
      testWidgets('renders RangeSlider widget', (tester) async {
        const node = SduiLeafNode(
          id: 'date_range',
          type: 'sdui:range_slider',
          version: 1,
          props: {
            'startValue': 10.0,
            'endValue': 90.0,
            'min': 0.0,
            'max': 100.0,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(RangeSlider), findsOneWidget);
      });

      testWidgets('renders RangeSlider with labels', (tester) async {
        const node = SduiLeafNode(
          id: 'price_range',
          type: 'sdui:range_slider',
          version: 1,
          props: {
            'startValue': 10.0,
            'endValue': 90.0,
            'min': 0.0,
            'max': 100.0,
            'startLabel': 'Min: 10',
            'endLabel': 'Max: 90',
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(RangeSlider), findsOneWidget);
      });

      testWidgets('renders disabled RangeSlider', (tester) async {
        const node = SduiLeafNode(
          id: 'disabled_range',
          type: 'sdui:range_slider',
          version: 1,
          props: {
            'startValue': 20.0,
            'endValue': 80.0,
            'min': 0.0,
            'max': 100.0,
            'enabled': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(RangeSlider), findsOneWidget);
      });
    });

    group('sdui:switch', () {
      testWidgets('renders Switch widget', (tester) async {
        const node = SduiLeafNode(
          id: 'dark_mode_toggle',
          type: 'sdui:switch',
          version: 1,
          props: {
            'value': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Switch), findsOneWidget);
      });

      testWidgets('renders enabled Switch', (tester) async {
        const node = SduiLeafNode(
          id: 'notification_toggle',
          type: 'sdui:switch',
          version: 1,
          props: {
            'value': true,
            'enabled': true,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Switch), findsOneWidget);
      });

      testWidgets('renders disabled Switch', (tester) async {
        const node = SduiLeafNode(
          id: 'disabled_switch',
          type: 'sdui:switch',
          version: 1,
          props: {
            'value': false,
            'enabled': false,
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(Switch), findsOneWidget);
      });
    });

    group('sdui:dropdown', () {
      testWidgets('renders DropdownButton with items', (tester) async {
        const node = SduiLeafNode(
          id: 'country_select',
          type: 'sdui:dropdown',
          version: 1,
          props: {
            'value': 'us',
            'hint': 'Select a country',
            'items': [
              {'label': 'United States', 'value': 'us'},
              {'label': 'Canada', 'value': 'ca'},
              {'label': 'Mexico', 'value': 'mx'},
            ],
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });

      testWidgets('renders DropdownButton with hint', (tester) async {
        const node = SduiLeafNode(
          id: 'category_select',
          type: 'sdui:dropdown',
          version: 1,
          props: {
            'hint': 'Choose category',
            'items': [
              {'label': 'Electronics', 'value': 'electronics'},
              {'label': 'Clothing', 'value': 'clothing'},
            ],
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });

      testWidgets('renders disabled DropdownButton', (tester) async {
        const node = SduiLeafNode(
          id: 'disabled_dropdown',
          type: 'sdui:dropdown',
          version: 1,
          props: {
            'value': 'option1',
            'enabled': false,
            'items': [
              {'label': 'Option 1', 'value': 'option1'},
              {'label': 'Option 2', 'value': 'option2'},
            ],
          },
        );
        await pumpSduiWidget(tester, node);
        expect(find.byType(DropdownButton<String>), findsOneWidget);
      });
    });
  });
}
