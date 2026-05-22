import 'package:flutter/material.dart';
import 'package:sdui_core/sdui_core.dart';
import 'transport/mock_transport.dart';

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
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: Colors.green.shade100,
          child: const Center(child: Icon(Icons.image, size: 64)),
        ),
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

Widget _throwsBuilder(SduiNode node, SduiBuildContext ctx) {
  throw Exception(
    node.props['message'] as String? ?? 'Intentional builder crash',
  );
}

final _mockTransport = MockTransport();

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => SduiScope(
        registry: SduiWidgetRegistry.withDefaults()
          ..register('myapp:banner', _bannerBuilder)
          ..register('myapp:throws_on_build', _throwsBuilder),
        actionRegistry: SduiActionRegistry.defaults
          ..register('navigate_to_cart', (action, ctx) async {
            debugPrint(
              '[Action] navigate_to_cart — payload: ${action.payload}',
            );
            return const SduiActionResult.success();
          }),
        child: MaterialApp(
          title: 'sdui_core Examples',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            useMaterial3: true,
          ),
          home: const ExampleHub(),
        ),
      );
}

class ExampleHub extends StatelessWidget {
  const ExampleHub({super.key});

  static const _examples = [
    _ExampleCard(
      title: 'Quick-Commerce Home',
      subtitle: 'Rich layout with custom banner, grid, cards, and actions',
      icon: Icons.store,
      endpoint: '/home',
    ),
    _ExampleCard(
      title: 'Widget Showcase',
      subtitle: 'Form widgets: text_field, checkbox, slider, dropdown, buttons',
      icon: Icons.widgets,
      endpoint: '/forms',
    ),
    _ExampleCard(
      title: 'Templates & \$ref',
      subtitle: 'Reusable node templates with {{variable}} interpolation',
      icon: Icons.copy_all,
      endpoint: '/templates',
    ),
    _ExampleCard(
      title: 'Animations',
      subtitle: 'Fade, slide, scale, and size transition_in effects',
      icon: Icons.animation,
      endpoint: '/animations',
    ),
    _ExampleCard(
      title: 'Error Boundary',
      subtitle: 'Bad nodes render debug tiles; children of crashed parents survive',
      icon: Icons.shield,
      endpoint: '/error-boundary',
    ),
    _ExampleCard(
      title: 'Live Updates',
      subtitle: 'SduiScreen streaming transport and hot-reload demo',
      icon: Icons.sync,
      endpoint: '/live',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('sdui_core Examples'),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _examples.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _ExampleCardWidget(
            card: _examples[i],
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => _ExampleScreen(card: _examples[i]),
              ),
            ),
          ),
        ),
      );
}

class _ExampleCard {
  final String title;
  final String subtitle;
  final IconData icon;
  final String endpoint;
  const _ExampleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.endpoint,
  });
}

class _ExampleCardWidget extends StatelessWidget {
  final _ExampleCard card;
  final VoidCallback onTap;
  const _ExampleCardWidget({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(card.icon, size: 40, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.subtitle,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleScreen extends StatelessWidget {
  final _ExampleCard card;
  const _ExampleScreen({required this.card});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(card.title),
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        body: SduiScreen(
          key: ValueKey(card.endpoint),
          url: 'https://api.example.com${card.endpoint}',
          transport: _mockTransport,
          loadingBuilder: (_) => const Center(child: CircularProgressIndicator()),
          errorBuilder: (_, err) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: $err', textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          onEvent: (event, payload) =>
              debugPrint('[${card.endpoint}] event: $event, payload: $payload'),
        ),
      );
}

void main() => runApp(const ExampleApp());
