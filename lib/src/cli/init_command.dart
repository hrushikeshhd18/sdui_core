import 'dart:convert';
import 'dart:io';

void runInit(List<String> args) {
  if (args.isNotEmpty && args.first == '--help') {
    stdout.writeln('Usage: sdui init [dir]');
    stdout.writeln('  dir  Target directory (default: current directory)');
    exit(0);
  }

  final base = args.isEmpty ? '.' : args.first;
  final screensDir = Directory('$base/screens');
  screensDir.createSync();

  final sampleFile = File('${screensDir.path}/home.json');
  if (sampleFile.existsSync()) {
    stdout.writeln(
      '\x1B[33m⚠  ${sampleFile.path} already exists — skipping\x1B[0m',
    );
    exit(0);
  }

  const encoder = JsonEncoder.withIndent('  ');
  sampleFile.writeAsStringSync(encoder.convert(_samplePayload));
  stdout.writeln('\x1B[32m✓ Created ${sampleFile.path}\x1B[0m');
  stdout.writeln();
  stdout.writeln('Run  sdui validate ${sampleFile.path}  to check the schema.');
}

const _samplePayload = {
  'sdui_version': '2.0',
  'metadata': {'screen': 'home'},
  'root': {
    'type': 'sdui:column',
    'id': 'root',
    'version': 1,
    'props': {'mainAxisAlignment': 'center', 'padding': 24},
    'actions': {},
    'children': [
      {
        'type': 'sdui:text',
        'id': 'headline',
        'version': 1,
        'props': {'text': 'Welcome', 'style': 'headlineMedium'},
        'actions': {},
      },
      {
        'type': 'sdui:spacer',
        'id': 'gap1',
        'version': 1,
        'props': {'flex': 1},
        'actions': {},
      },
      {
        'type': 'sdui:button',
        'id': 'cta',
        'version': 1,
        'props': {'label': 'Get Started', 'variant': 'filled'},
        'actions': {
          'onTap': {
            'type': 'navigate',
            'event': 'go_dashboard',
            'payload': {'route': '/dashboard'},
          },
        },
      },
    ],
  },
};
