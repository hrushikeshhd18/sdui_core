import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';

// ---------------------------------------------------------------------------
// Mock transport — no server required to run this example
// ---------------------------------------------------------------------------

class _MockTransport implements SduiTransport {
  @override
  Future<Map<String, Object?>> fetch(
    String url, {
    Map<String, String>? headers,
  }) async =>
      _homeScreenJson();

  @override
  Stream<Map<String, Object?>> subscribe(
    String url, {
    Map<String, String>? headers,
  }) =>
      Stream.value(_homeScreenJson());

  @override
  Future<void> dispose() async {}
}

// ---------------------------------------------------------------------------
// Realistic quick-commerce home screen JSON
// ---------------------------------------------------------------------------

Map<String, dynamic> _homeScreenJson() => {
      'sdui_version': '1.0',
      'root': {
        'type': 'sdui:column',
        'id': 'root',
        'version': 1,
        'props': {'scrollDirection': 'vertical'},
        'actions': {},
        'children': [
          // Hero banner (custom widget registered below)
          {
            'type': 'myapp:banner',
            'id': 'hero_banner',
            'version': 1,
            'props': {
              'imageUrl': 'https://picsum.photos/seed/hero/800/300',
              'title': 'Fresh groceries\nin 10 minutes',
              'subtitle': 'Free delivery on first order',
            },
            'actions': {},
          },
          // Category section title
          {
            'type': 'sdui:padding',
            'id': 'category_padding',
            'version': 1,
            'props': {'top': 16, 'left': 16, 'right': 16, 'bottom': 8},
            'actions': {},
            'children': [
              {
                'type': 'sdui:text',
                'id': 'category_title',
                'version': 1,
                'props': {'text': 'Shop by category', 'style': 'h3'},
                'actions': {},
              },
            ],
          },
          // Horizontal category list
          {
            'type': 'sdui:list',
            'id': 'category_list',
            'version': 1,
            'props': {'scrollDirection': 'horizontal'},
            'actions': {},
            'children': [
              _categoryChip('cat_fruits', 'Fruits', '🍎'),
              _categoryChip('cat_veggies', 'Veggies', '🥦'),
              _categoryChip('cat_dairy', 'Dairy', '🥛'),
              _categoryChip('cat_bakery', 'Bakery', '🍞'),
              _categoryChip('cat_drinks', 'Drinks', '🧃'),
            ],
          },
          // Product grid
          {
            'type': 'sdui:padding',
            'id': 'products_padding',
            'version': 1,
            'props': {'all': 16},
            'actions': {},
            'children': [
              {
                'type': 'sdui:grid',
                'id': 'product_grid',
                'version': 1,
                'props': {
                  'columns': 2,
                  'spacing': 12,
                  'aspectRatio': 0.75,
                },
                'actions': {},
                'children': [
                  _productCard('prod_1', 'Organic Apples', r'$3.99',
                      'https://picsum.photos/seed/apple/200/200',),
                  _productCard('prod_2', 'Whole Milk 2L', r'$2.49',
                      'https://picsum.photos/seed/milk/200/200',),
                  _productCard('prod_3', 'Sourdough Bread', r'$4.99',
                      'https://picsum.photos/seed/bread/200/200',),
                  _productCard('prod_4', 'Orange Juice', r'$3.29',
                      'https://picsum.photos/seed/oj/200/200',),
                ],
              },
            ],
          },
          // CTA button dispatching a custom action
          {
            'type': 'sdui:padding',
            'id': 'cta_padding',
            'version': 1,
            'props': {'horizontal': 16, 'bottom': 32},
            'actions': {},
            'children': [
              {
                'type': 'sdui:button',
                'id': 'view_cart_btn',
                'version': 1,
                'props': {
                  'label': 'View Cart (3 items)',
                  'variant': 'elevated',
                },
                'actions': {
                  'onTap': {
                    'type': 'dispatch',
                    'event': 'navigate_to_cart',
                    'payload': {'source': 'home_cta'},
                  },
                },
              },
            ],
          },
        ],
      },
    };

Map<String, dynamic> _categoryChip(
        String id, String label, String emoji,) =>
    {
      'type': 'sdui:padding',
      'id': id,
      'version': 1,
      'props': {'all': 8},
      'actions': {},
      'children': [
        {
          'type': 'sdui:card',
          'id': '${id}_card',
          'version': 1,
          'props': {'borderRadius': 12},
          'actions': {},
          'children': [
            {
              'type': 'sdui:padding',
              'id': '${id}_inner',
              'version': 1,
              'props': {'horizontal': 16, 'vertical': 12},
              'actions': {},
              'children': [
                {
                  'type': 'sdui:column',
                  'id': '${id}_col',
                  'version': 1,
                  'props': {
                    'mainAxisSize': 'min',
                    'crossAxisAlignment': 'center',
                  },
                  'actions': {},
                  'children': [
                    {
                      'type': 'sdui:text',
                      'id': '${id}_emoji',
                      'version': 1,
                      'props': {'text': emoji, 'fontSize': 28},
                      'actions': {},
                    },
                    {
                      'type': 'sdui:text',
                      'id': '${id}_label',
                      'version': 1,
                      'props': {'text': label, 'style': 'caption'},
                      'actions': {},
                    },
                  ],
                },
              ],
            },
          ],
        },
      ],
    };

Map<String, dynamic> _productCard(
        String id, String name, String price, String imgUrl,) =>
    {
      'type': 'sdui:card',
      'id': id,
      'version': 1,
      'props': {'borderRadius': 12, 'elevation': 2},
      'actions': {},
      'children': [
        {
          'type': 'sdui:column',
          'id': '${id}_col',
          'version': 1,
          'props': {'crossAxisAlignment': 'stretch'},
          'actions': {},
          'children': [
            {
              'type': 'sdui:image',
              'id': '${id}_img',
              'version': 1,
              'props': {'url': imgUrl, 'height': 120, 'fit': 'cover'},
              'actions': {},
            },
            {
              'type': 'sdui:padding',
              'id': '${id}_info',
              'version': 1,
              'props': {'all': 8},
              'actions': {},
              'children': [
                {
                  'type': 'sdui:text',
                  'id': '${id}_name',
                  'version': 1,
                  'props': {
                    'text': name,
                    'style': 'body2',
                    'maxLines': 2,
                    'overflow': 'ellipsis',
                  },
                  'actions': {},
                },
                {
                  'type': 'sdui:text',
                  'id': '${id}_price',
                  'version': 1,
                  'props': {
                    'text': price,
                    'style': 'body',
                    'fontWeight': 'bold',
                  },
                  'actions': {},
                },
              ],
            },
          ],
        },
      ],
    };

// ---------------------------------------------------------------------------
// Custom banner widget — demonstrates custom widget registration
// ---------------------------------------------------------------------------

Widget _bannerBuilder(SduiNode node, SduiBuildContext ctx) {
  final props = node.props;
  final imgUrl = props['imageUrl'] as String? ?? '';
  final title = props['title'] as String? ?? '';
  final subtitle = props['subtitle'] as String? ?? '';

  return Stack(
    alignment: Alignment.bottomLeft,
    children: [
      Image.network(
        imgUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xCC000000), Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    ],
  );
}

// ---------------------------------------------------------------------------
// App entry point
// ---------------------------------------------------------------------------

void main() {
  // 1. Register built-in widgets.
  SduiWidgetRegistry.defaults.registerAll(createCoreWidgets());

  // 2. Register a custom widget.
  SduiWidgetRegistry.defaults.register('myapp:banner', _bannerBuilder);

  // 3. Register a custom action handler.
  SduiActionRegistry.defaults.register(
    'navigate_to_cart',
    (action, ctx) async {
      debugPrint(
        '[Action] navigate_to_cart — payload: ${action.payload}',
      );
      // In a real app: Navigator.of(ctx.flutterContext).pushNamed('/cart');
      return const SduiActionResult.success();
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'sdui_core Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
}

/// Demonstrates [SduiScreen] pointed at a mock URL.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('sdui_core Demo'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: SduiScreen(
          url: 'https://api.example.com/layouts/home',
          transport: _MockTransport(),
          loadingBuilder: (_) => const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          ),
          errorBuilder: (_, err) => Center(child: Text('Error: $err')),
          onEvent: (event, payload) =>
              debugPrint('[SduiScreen] event: $event, payload: $payload'),
        ),
      ),
    );
}
