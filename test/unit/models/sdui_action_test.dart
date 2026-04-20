import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

void main() {
  group('SduiAction.fromJson', () {
    test('parses minimal navigate action', () {
      final action = SduiAction.fromJson(const {
        'type': 'navigate',
        'event': 'go_home',
      });
      expect(action.type, 'navigate');
      expect(action.event, 'go_home');
      expect(action.payload, isEmpty);
      expect(action.debounceMs, isNull);
    });

    test('parses action with payload and debounce', () {
      final action = SduiAction.fromJson(const {
        'type': 'dispatch',
        'event': 'add_to_cart',
        'payload': {'productId': '123'},
        'debounceMs': 300,
      });
      expect(action.type, 'dispatch');
      expect(action.payload['productId'], '123');
      expect(action.debounceMs, 300);
    });

    test('defaults missing type to dispatch', () {
      final action = SduiAction.fromJson(const {'event': 'my_event'});
      expect(action.type, SduiActionType.dispatch);
    });

    test('defaults missing event to empty string', () {
      final action = SduiAction.fromJson(const {'type': 'navigate'});
      expect(action.event, '');
    });

    test('handles untyped payload Map via cast', () {
      final raw = <dynamic, dynamic>{'key': 'value'};
      final action =
          SduiAction.fromJson({'type': 'custom', 'event': 'e', 'payload': raw});
      expect(action.payload['key'], 'value');
    });

    test('missing payload produces empty map', () {
      final action =
          SduiAction.fromJson(const {'type': 'navigate', 'event': 'home'});
      expect(action.payload, isEmpty);
    });
  });

  group('SduiAction.toJson', () {
    test('round-trips through toJson/fromJson', () {
      const original = SduiAction(
        type: 'dispatch',
        event: 'buy_now',
        payload: {'sku': 'abc'},
        debounceMs: 150,
      );
      final json = original.toJson();
      final restored = SduiAction.fromJson(json);
      expect(restored.type, original.type);
      expect(restored.event, original.event);
      expect(restored.payload['sku'], 'abc');
      expect(restored.debounceMs, 150);
    });

    test('omits debounceMs when null', () {
      const action = SduiAction(type: 'navigate', event: 'home');
      expect(action.toJson().containsKey('debounceMs'), isFalse);
    });
  });

  group('SduiAction equality and hashCode', () {
    test('identical instances are equal', () {
      const a = SduiAction(type: 'navigate', event: 'go_home');
      const b = SduiAction(type: 'navigate', event: 'go_home');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different events produce inequality', () {
      const a = SduiAction(type: 'navigate', event: 'home');
      const b = SduiAction(type: 'navigate', event: 'cart');
      expect(a, isNot(equals(b)));
    });

    test('different debounce produces inequality', () {
      const a = SduiAction(type: 'navigate', event: 'home', debounceMs: 100);
      const b = SduiAction(type: 'navigate', event: 'home', debounceMs: 200);
      expect(a, isNot(equals(b)));
    });
  });

  group('SduiAction.copyWith', () {
    const original = SduiAction(
      type: 'navigate',
      event: 'go_home',
      payload: {'screen': 'home'},
      debounceMs: 200,
    );

    test('replaces event only', () {
      final copy = original.copyWith(event: 'go_cart');
      expect(copy.event, 'go_cart');
      expect(copy.type, 'navigate');
      expect(copy.debounceMs, 200);
    });

    test('replaces payload only', () {
      final copy = original.copyWith(payload: {'screen': 'cart'});
      expect(copy.payload['screen'], 'cart');
      expect(copy.event, 'go_home');
    });

    test('replaces debounceMs', () {
      final copy = original.copyWith(debounceMs: 500);
      expect(copy.debounceMs, 500);
    });
  });

  group('SduiActionType constants', () {
    test('all expected constants defined', () {
      expect(SduiActionType.dispatch, 'dispatch');
      expect(SduiActionType.navigate, 'navigate');
      expect(SduiActionType.openUrl, 'open_url');
      expect(SduiActionType.copyToClipboard, 'copy_to_clipboard');
      expect(SduiActionType.showSnackbar, 'show_snackbar');
      expect(SduiActionType.refresh, 'refresh');
    });
  });
}
