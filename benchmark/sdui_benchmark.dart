// Run with: flutter test benchmark/sdui_benchmark.dart -v
//
// Measures:
//   - JSON parse time at 3 payload sizes (small / medium / large)
//   - Tree diff time at 3 tree sizes (small / medium / large)
//   - Validator throughput
//
// Expected targets (debug build, M-series Mac):
//   Parse  small  (<1 KB,   ~10 nodes)  < 5 ms
//   Parse  medium (<50 KB,  ~200 nodes) < 30 ms
//   Parse  large  (<500 KB, ~2 000 nodes) < 200 ms
//   Diff   small  (10 nodes, 30% changed)  < 1 ms
//   Diff   medium (500 nodes, 10% changed) < 10 ms
//   Diff   large  (2 000 nodes, 5% changed) < 30 ms

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sdui_core/sdui_core.dart';

// ---------------------------------------------------------------------------
// Payload generators
// ---------------------------------------------------------------------------

Map<String, Object?> _makePayload(int nodeCount) {
  final children = <Map<String, Object?>>[];
  for (var i = 0; i < nodeCount - 1; i++) {
    children.add({
      'type': i.isEven ? 'sdui:text' : 'sdui:container',
      'id': 'node_$i',
      'version': 1,
      'props': {'text': 'Node $i', 'color': '#1A1A2E', 'padding': 8},
      'actions': {},
    });
  }
  return {
    'sdui_version': '1.0',
    'root': {
      'type': 'sdui:column',
      'id': 'root',
      'version': 1,
      'props': {},
      'actions': {},
      'children': children,
    },
  };
}

SduiNode _makeTree(int nodeCount, {int versionOffset = 0}) {
  final children = <SduiNode>[];
  for (var i = 0; i < nodeCount - 1; i++) {
    children.add(SduiLeafNode(
      id: 'node_$i',
      type: 'sdui:text',
      version: versionOffset > 0 && i % (100 ~/ (versionOffset)) == 0
          ? 2
          : 1,
      props: const {'text': 'Node'},
    ),
    );
  }
  return SduiParentNode(
    id: 'root',
    type: 'sdui:column',
    version: 1,
    children: children,
  );
}

// ---------------------------------------------------------------------------
// Benchmark runner
// ---------------------------------------------------------------------------

Duration _time(void Function() fn) {
  final sw = Stopwatch()..start();
  fn();
  sw.stop();
  return sw.elapsed;
}

void _printRow(String label, int n, Duration d) {
  final ms = d.inMicroseconds / 1000;
  // ignore: avoid_print
  print('  ${label.padRight(38)} n=$n    ${ms.toStringAsFixed(2).padLeft(8)} ms');
}

// ---------------------------------------------------------------------------
// Tests / benchmarks
// ---------------------------------------------------------------------------

void main() {
  const warmupRuns = 3;
  const measuredRuns = 10;

  group('Parse benchmark — SduiParser.parse', () {
    for (final nodeCount in [10, 200, 2000]) {
      test('parse $nodeCount nodes (avg of $measuredRuns runs)', () {
        final payload = _makePayload(nodeCount);
        final jsonStr = jsonEncode(payload);
        final payloadBytes = jsonStr.length;

        // Warmup
        for (var i = 0; i < warmupRuns; i++) {
          SduiParser.parse(payload);
        }

        // Measured
        var total = Duration.zero;
        for (var i = 0; i < measuredRuns; i++) {
          total += _time(() => SduiParser.parse(payload));
        }
        final avg = total ~/ measuredRuns;
        _printRow('parse (${payloadBytes ~/ 1024}KB, $nodeCount nodes)', nodeCount, avg);

        // Soft assertions — fail only if grossly over target
        final targetMs = nodeCount <= 10
            ? 50
            : nodeCount <= 200
                ? 300
                : 2000;
        expect(
          avg.inMilliseconds,
          lessThan(targetMs),
          reason: 'Parse took ${avg.inMilliseconds}ms — target <${targetMs}ms',
        );
      });
    }
  });

  group('Validator benchmark — SduiParser.validate', () {
    for (final nodeCount in [10, 200, 2000]) {
      test('validate $nodeCount nodes (avg of $measuredRuns runs)', () {
        final payload = _makePayload(nodeCount);

        // Warmup
        for (var i = 0; i < warmupRuns; i++) {
          SduiParser.validate(payload);
        }

        var total = Duration.zero;
        for (var i = 0; i < measuredRuns; i++) {
          total += _time(() => SduiParser.validate(payload));
        }
        final avg = total ~/ measuredRuns;
        _printRow('validate ($nodeCount nodes)', nodeCount, avg);

        expect(avg.inMilliseconds, lessThan(500));
      });
    }
  });

  group('Diff benchmark — SduiDiffer.diff', () {
    for (final nodeCount in [10, 500, 2000]) {
      test('diff $nodeCount nodes ~10% changed (avg of $measuredRuns runs)', () {
        final current = _makeTree(nodeCount);
        final updated = _makeTree(nodeCount, versionOffset: 10);

        // Warmup
        for (var i = 0; i < warmupRuns; i++) {
          SduiDiffer.diff(current, updated);
        }

        var total = Duration.zero;
        for (var i = 0; i < measuredRuns; i++) {
          total += _time(() => SduiDiffer.diff(current, updated));
        }
        final avg = total ~/ measuredRuns;
        _printRow('diff ($nodeCount nodes, ~10% changed)', nodeCount, avg);

        final targetMs = nodeCount <= 10 ? 10 : nodeCount <= 500 ? 50 : 200;
        expect(avg.inMilliseconds, lessThan(targetMs));
      });
    }
  });

  group('Migration benchmark — SduiSchemaMigrator.migrate', () {
    for (final nodeCount in [10, 500, 2000]) {
      test('migrate v1→v2 $nodeCount nodes (avg of $measuredRuns runs)', () {
        final payload = _makePayload(nodeCount);

        // Warmup
        for (var i = 0; i < warmupRuns; i++) {
          SduiSchemaMigrator.migrate(payload);
        }

        var total = Duration.zero;
        for (var i = 0; i < measuredRuns; i++) {
          total += _time(() => SduiSchemaMigrator.migrate(payload));
        }
        final avg = total ~/ measuredRuns;
        _printRow('migrate v1→v2 ($nodeCount nodes)', nodeCount, avg);

        expect(avg.inMilliseconds, lessThan(500));
      });
    }
  });
}
