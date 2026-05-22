import 'package:sdui_core/sdui_core.dart';

/// Mock transport serving JSON for all 6 example screens.
///
/// Uses Dart helper functions to build JSON — no external server needed.
class MockTransport implements SduiTransport {
  final _endpoints = <String, Map<String, dynamic> Function()>{
    '/home': _home,
    '/forms': _forms,
    '/templates': _templates,
    '/animations': _animations,
    '/error-boundary': _errors,
    '/live': _live,
  };

  @override
  Future<Map<String, dynamic>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async =>
      (_endpoints[Uri.tryParse(url)?.path ?? url] ?? _unknown)();

  @override
  Stream<Map<String, dynamic>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) async* {
    final fn = _endpoints[Uri.tryParse(url)?.path ?? url];
    if (fn != null) yield fn();
  }

  @override
  Future<void> dispose() async {}

  Map<String, dynamic> _unknown() =>
      {'sdui_version': '1.0', 'error': 'Unknown endpoint'};
}

typedef J = Map<String, dynamic>;

J _root(List<J> children) => {
      'sdui_version': '1.0',
      'root': {
        'type': 'sdui:column',
        'id': 'root',
        'version': 1,
        'props': {'scrollDirection': 'vertical', 'spacing': 12},
        'children': [...children, _spacer()],
      },
    };

J _text(String id, String s, {String style = 'body', String? fontWeight}) => {
      'type': 'sdui:text',
      'id': id,
      'version': 1,
      'props': {
        'text': s,
        'style': style,
        if (fontWeight != null) 'fontWeight': fontWeight,
      },
    };

J _heading(String id, String s) => _text(id, '  $s', style: 'h3');
J _subheading(String id, String s) => _text(id, '  $s', style: 'h4');
J _caption(String id, String s) => _text(id, s, style: 'caption');
J _bold(String id, String s) => _text(id, s, fontWeight: 'bold');
J _body(String id, String s) => _text(id, s);

J _spacer() => {
      'type': 'sdui:padding',
      'id': 'sp_${DateTime.now().microsecondsSinceEpoch}',
      'version': 1,
      'props': {'padding': {'vertical': 24}},
    };

J _pad(String id, J child, {num? h, num? v}) => {
      'type': 'sdui:padding',
      'id': id,
      'version': 1,
      'props': {'padding': {if (h != null) 'horizontal': h, if (v != null) 'vertical': v}},
      'children': [child],
    };

J _card(String id, J child, {Map<String, dynamic>? anim}) => {
      'type': 'sdui:card',
      'id': id,
      'version': 1,
      'props': {
        'borderRadius': 12,
        'elevation': 2,
        'padding': {'all': 16},
        if (anim != null) 'transition_in': anim,
      },
      'children': [child],
    };

J _row(List<J> children, {num spacing = 8}) => {
      'type': 'sdui:row',
      'id': 'r_${DateTime.now().microsecondsSinceEpoch}',
      'version': 1,
      'props': {'spacing': spacing, 'crossAxisAlignment': 'center'},
      'children': children,
    };

// ---------------------------------------------------------------------------
// 1. Quick-Commerce Home
// ---------------------------------------------------------------------------

J _home() => _root([
      // Hero banner via custom myapp:banner widget
      {
        'type': 'myapp:banner',
        'id': 'hero',
        'version': 1,
        'props': {
          'imageUrl': 'https://picsum.photos/seed/hero/800/300',
          'title': 'Fresh groceries\nin 10 minutes',
          'subtitle': 'Free delivery on first order',
        },
      },
      _heading('cat_h', 'Shop by category'),
      {
        'type': 'sdui:list',
        'id': 'cats',
        'version': 1,
        'props': {'scrollDirection': 'horizontal'},
        'children': [
          _chip('fruits', '🍎', 'Fruits'),
          _chip('veggies', '🥦', 'Veggies'),
          _chip('dairy', '🥛', 'Dairy'),
          _chip('bakery', '🍞', 'Bakery'),
          _chip('drinks', '🧃', 'Drinks'),
        ],
      },
      {
        'type': 'sdui:grid',
        'id': 'grid',
        'version': 1,
        'props': {'columns': 2, 'spacing': 12, 'aspectRatio': 0.75},
        'children': [
          _product(
            'p1', 'Organic Apples', r'$3.99',
            'https://picsum.photos/seed/apple/200/200',
          ),
          _product(
            'p2', 'Whole Milk 2L', r'$2.49',
            'https://picsum.photos/seed/milk/200/200',
          ),
          _product(
            'p3', 'Sourdough Bread', r'$4.99',
            'https://picsum.photos/seed/bread/200/200',
          ),
          _product(
            'p4', 'Orange Juice', r'$3.29',
            'https://picsum.photos/seed/oj/200/200',
          ),
        ],
      },
      {
        'type': 'sdui:button',
        'id': 'cart_btn',
        'version': 1,
        'props': {'label': 'View Cart (3 items)', 'variant': 'elevated'},
        'actions': {
          'onTap': {
            'type': 'dispatch',
            'event': 'navigate_to_cart',
            'payload': {'source': 'cta'},
          },
        },
      },
    ]);

J _chip(String id, String emoji, String label) => {
      'type': 'sdui:padding',
      'id': id,
      'version': 1,
      'props': {'padding': {'all': 8}},
      'children': [
        {
          'type': 'sdui:card',
          'id': '${id}_c',
          'version': 1,
          'props': {'borderRadius': 12},
          'children': [
            {
              'type': 'sdui:padding',
              'id': '${id}_i',
              'version': 1,
              'props': {'padding': {'horizontal': 16, 'vertical': 12}},
              'children': [
                {
                  'type': 'sdui:column',
                  'id': '${id}_col',
                  'version': 1,
                  'props': {
                    'mainAxisSize': 'min',
                    'crossAxisAlignment': 'center',
                  },
                  'children': [
                    _text('${id}_e', emoji),
                    _text('${id}_l', label, style: 'caption'),
                  ],
                },
              ],
            },
          ],
        },
      ],
    };

J _product(String id, String name, String price, String img) => {
      'type': 'sdui:card',
      'id': id,
      'version': 1,
      'props': {'borderRadius': 12, 'elevation': 2},
      'children': [
        {
          'type': 'sdui:column',
          'id': '${id}_col',
          'version': 1,
          'props': {'crossAxisAlignment': 'stretch'},
          'children': [
            {
              'type': 'sdui:image',
              'id': '${id}_img',
              'version': 1,
              'props': {'url': img, 'height': 120, 'fit': 'cover'},
            },
            _pad('${id}_n', _bold('${id}_n', name), h: 8),
            _pad('${id}_p', _body('${id}_p', price), h: 8),
          ],
        },
      ],
    };

// ---------------------------------------------------------------------------
// 2. Form Widget Showcase
// ---------------------------------------------------------------------------

J _forms() => _root([
      _heading('f_h', 'Widget Showcase'),
      _caption('f_sub', 'All SDUI form widgets in action'),
      _subheading('f_tf', 'Text Field'),
      {
        'type': 'sdui:text_field',
        'id': 'tf_name',
        'version': 1,
        'props': {'hint': 'Enter your name...', 'border': 'outline'},
      },
      _subheading('f_cb', 'Checkbox'),
      {
        'type': 'sdui:checkbox',
        'id': 'cb_sub',
        'version': 1,
        'props': {'label': 'Subscribe to newsletter', 'value': true},
      },
      _subheading('f_sl', 'Slider'),
      {
        'type': 'sdui:slider',
        'id': 'sl_vol',
        'version': 1,
        'props': {'label': 'Volume', 'value': 50, 'min': 0, 'max': 100},
      },
      _subheading('f_dd', 'Dropdown'),
      {
        'type': 'sdui:dropdown',
        'id': 'dd_plan',
        'version': 1,
        'props': {
          'options': ['Starter', 'Builder', 'Pro', 'Enterprise'],
          'value': 'Pro',
          'label': 'Select plan',
        },
      },
      _subheading('f_sw', 'Switch'),
      {
        'type': 'sdui:switch',
        'id': 'sw_dark',
        'version': 1,
        'props': {'value': true},
      },
      _subheading('f_btn', 'Button Variants'),
      _btn('be', 'Elevated', 'elevated'),
      _btn('bo', 'Outlined', 'outlined'),
      _btn('bt', 'Text', 'text'),
      _btn('bf', 'Filled', 'filled'),
    ]);

J _btn(String id, String label, String variant) => {
      'type': 'sdui:button',
      'id': id,
      'version': 1,
      'props': {'label': label, 'variant': variant},
    };

// ---------------------------------------------------------------------------
// 3. Templates / $ref Demo
// ---------------------------------------------------------------------------

J _templates() => {
      'sdui_version': '1.0',
      'templates': {
        'product_card': {
          'type': 'sdui:card',
          'id': '{{id}}',
          'version': 1,
          'props': {'borderRadius': 12, 'elevation': 2},
          'children': [
            {
              'type': 'sdui:column',
              'id': '{{id}}_col',
              'version': 1,
              'props': {'crossAxisAlignment': 'stretch'},
              'children': [
                {
                  'type': 'sdui:image',
                  'id': '{{id}}_img',
                  'version': 1,
                  'props': {'url': '{{imgUrl}}', 'height': 120, 'fit': 'cover'},
                },
                _pad('{{id}}_n', _bold('{{id}}_n', '{{name}}'), h: 8),
                _pad('{{id}}_p', _body('{{id}}_p', '{{price}}'), h: 8),
              ],
            },
          ],
        },
        'category_chip': {
          'type': 'sdui:padding',
          'id': '{{id}}',
          'version': 1,
          'props': {'padding': {'all': 8}},
          'children': [
            {
              'type': 'sdui:card',
              'id': '{{id}}_c',
              'version': 1,
              'props': {'borderRadius': 12},
              'children': [
                {
                  'type': 'sdui:padding',
                  'id': '{{id}}_i',
                  'version': 1,
                  'props': {'padding': {'horizontal': 16, 'vertical': 12}},
                  'children': [
                    {
                      'type': 'sdui:column',
                      'id': '{{id}}_col',
                      'version': 1,
                      'props': {
                        'mainAxisSize': 'min',
                        'crossAxisAlignment': 'center',
                      },
                      'children': [
                        _text('{{id}}_e', '{{emoji}}'),
                        _text('{{id}}_l', '{{label}}', style: 'caption'),
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        },
      },
      'root': {
        'type': 'sdui:column',
        'id': 'root',
        'version': 1,
        'props': {'scrollDirection': 'vertical', 'spacing': 12},
        'children': [
          _heading('t_h', 'Templates via \$ref'),
          _caption(
            't_sub',
            'product_card + category_chip defined once, reused with {{variables}}',
          ),
          _subheading('t_prods', 'Products (from \$ref)'),
          {
            '\$ref': 'product_card',
            'id': 'pr1',
            'name': 'Wireless Mouse',
            'price': r'$29.99',
            'imgUrl': 'https://picsum.photos/seed/mouse/200/200',
          },
          {
            '\$ref': 'product_card',
            'id': 'pr2',
            'name': 'Mechanical Keyboard',
            'price': r'$89.99',
            'imgUrl': 'https://picsum.photos/seed/keyboard/200/200',
          },
          {
            '\$ref': 'product_card',
            'id': 'pr3',
            'name': 'USB-C Hub 7-in-1',
            'price': r'$34.99',
            'imgUrl': 'https://picsum.photos/seed/usbhub/200/200',
          },
          _subheading('t_cats', 'Category Chips (from \$ref)'),
          {
            'type': 'sdui:list',
            'id': 't_cat_list',
            'version': 1,
            'props': {'scrollDirection': 'horizontal'},
            'children': [
              {'\$ref': 'category_chip', 'id': 'ct_1', 'emoji': '📱', 'label': 'Tech'},
              {'\$ref': 'category_chip', 'id': 'ct_2', 'emoji': '👕', 'label': 'Fashion'},
              {'\$ref': 'category_chip', 'id': 'ct_3', 'emoji': '📚', 'label': 'Books'},
            ],
          },
          _spacer(),
        ],
      },
    };

// ---------------------------------------------------------------------------
// 4. Animations
// ---------------------------------------------------------------------------

J _animations() => {
      'sdui_version': '1.0',
      'templates': {
        'fruit_chip': {
          'type': 'sdui:card',
          'id': '{{id}}',
          'version': 1,
          'props': {
            'borderRadius': 12,
            'elevation': 1,
            'padding': {'horizontal': 16, 'vertical': 12},
            'transition_in': {'type': 'fade', 'duration': 400},
          },
          'children': [
            _row([
              _text('{{id}}_e', '{{emoji}}'),
              _body('{{id}}_l', '{{label}}'),
            ]),
          ],
        },
      },
      'root': {
        'type': 'sdui:column',
        'id': 'root',
        'version': 1,
        'props': {'scrollDirection': 'vertical', 'spacing': 12},
        'children': [
          _heading('a_h', 'Animation Transitions'),
          _caption('a_sub', 'transition_in: fade, slide, scale, size'),
          _animCard(
            'ac_1', '🌟', 'Fade In',
            {'type': 'fade', 'duration': 600},
          ),
          _animCard(
            'ac_2', '⬆️', 'Slide Up',
            {'type': 'slide', 'duration': 500, 'delay': 100, 'direction': 'bottom'},
          ),
          _animCard(
            'ac_3', '🔍', 'Scale In',
            {'type': 'scale', 'duration': 400, 'delay': 200},
          ),
          _animCard(
            'ac_4', '📐', 'Size Transition',
            {'type': 'size', 'duration': 700, 'delay': 300},
          ),
          _animCard(
            'ac_5', '➡️', 'Slide Right',
            {'type': 'slide', 'duration': 600, 'delay': 400, 'direction': 'left'},
          ),
          _subheading('a_fruit', 'Fruit List (fade in)'),
          {'\$ref': 'fruit_chip', 'id': 'f1', 'emoji': '🍎', 'label': 'Apples'},
          {'\$ref': 'fruit_chip', 'id': 'f2', 'emoji': '🍊', 'label': 'Oranges'},
          {'\$ref': 'fruit_chip', 'id': 'f3', 'emoji': '🍋', 'label': 'Lemons'},
          {'\$ref': 'fruit_chip', 'id': 'f4', 'emoji': '🍇', 'label': 'Grapes'},
          {'\$ref': 'fruit_chip', 'id': 'f5', 'emoji': '🍓', 'label': 'Strawberries'},
          _spacer(),
        ],
      },
    };

J _animCard(String id, String emoji, String label, J anim) => {
      'type': 'sdui:card',
      'id': id,
      'version': 1,
      'props': {
        'borderRadius': 12,
        'elevation': 2,
        'padding': {'all': 16},
        'transition_in': anim,
      },
      'children': [
        _row([_text('${id}_e', emoji), _bold('${id}_l', label)]),
      ],
    };

// ---------------------------------------------------------------------------
// 5. Error Boundary Demo
// ---------------------------------------------------------------------------

J _errors() => _root([
      _heading('e_h', 'Error Boundary Demo'),
      _caption('e_sub', 'Bad nodes render debug tiles in debug mode; '
          'children of crashed parents survive.'),
      _body('e_s1', '✅ This renders fine'),
      // Unknown type — triggers renderer error tile
      {'type': 'sdui:unknown_type_xyz', 'id': 'e_bad', 'version': 1},
      _body('e_s2', '🛡️ Still renders after bad node'),
      _body('e_lb', 'Bad parent below — children survive:'),
      {
        'type': 'myapp:throws_on_build',
        'id': 'e_bp',
        'version': 1,
        'props': {'message': 'I always throw!'},
        'children': [
          _body('e_c', '  ✅ Child survived the parent crash!'),
        ],
      },
    ]);

// ---------------------------------------------------------------------------
// 6. Live Updates / Streaming
// ---------------------------------------------------------------------------

J _live() => _root([
      _heading('l_h', 'Live Updates via SduiScreen'),
      _caption('l_sub', 'SduiScreen fetches JSON, diffs, rebuilds only changed '
          'nodes. Pass a streaming transport for real-time updates.'),
      _subheading('l_dash', 'Live Dashboard'),
      _body('l_body', 'Loaded from MockTransport. Replace with WebSocket for streaming.'),
      _card('l_card', _body('l_ct', 'Active Users: 1,284\nOrders: 342\nRevenue: \$12,847')),
    ]);
