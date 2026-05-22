import 'dart:convert';
import 'dart:io';

import 'package:sdui_core/src/exceptions/sdui_exceptions.dart';
import 'package:sdui_core/src/models/sdui_node.dart';
import 'package:sdui_core/src/parser/sdui_parser.dart';
import 'package:sdui_core/src/renderer/sdui_differ.dart';

void runDiff(List<String> args) {
  if (args.length < 2 || args.first == '--help') {
    stdout.writeln('Usage: sdui diff <current.json> <new.json>');
    exit(0);
  }

  final currentPath = args[0];
  final updatedPath = args[1];

  final currentMap = _readJson(currentPath);
  final updatedMap = _readJson(updatedPath);

  late final SduiNode current;
  late final SduiNode updated;
  try {
    current = SduiParser.parse(currentMap);
    updated = SduiParser.parse(updatedMap);
  } on SduiException catch (e) {
    stderr.writeln('\x1B[31mParse error: [${e.code}] ${e.message}\x1B[0m');
    exit(1);
  }

  final result = SduiDiffer.diff(current, updated);
  final changed =
      result.diffs.where((d) => d.type != SduiDiffType.unchanged).toList();

  if (!result.hasDiffs) {
    stdout.writeln(
      '\x1B[32m✓ No changes — $currentPath and $updatedPath are identical\x1B[0m',
    );
    exit(0);
  }

  final added = changed.where((d) => d.type == SduiDiffType.added).toList();
  final removed = changed.where((d) => d.type == SduiDiffType.removed).toList();
  final upd = changed.where((d) => d.type == SduiDiffType.updated).toList();
  final moved = changed.where((d) => d.type == SduiDiffType.moved).toList();

  stdout.writeln('Diff  $currentPath → $updatedPath');
  stdout.writeln(
    '  ${changed.length} change(s): '
    '${added.length} added · ${removed.length} removed · '
    '${upd.length} updated · ${moved.length} moved\n',
  );

  for (final d in added) {
    final id = (d.newNode?.id ?? '').padRight(30);
    stdout.writeln('\x1B[32m  +  $id  ${d.path}\x1B[0m');
  }
  for (final d in removed) {
    final id = (d.oldNode?.id ?? '').padRight(30);
    stdout.writeln('\x1B[31m  -  $id  ${d.path}\x1B[0m');
  }
  for (final d in upd) {
    final id = (d.newNode?.id ?? '').padRight(30);
    final vOld = d.oldNode?.version ?? '?';
    final vNew = d.newNode?.version ?? '?';
    stdout.writeln('\x1B[33m  ~  $id  ${d.path}  v$vOld → v$vNew\x1B[0m');
  }
  for (final d in moved) {
    final id = (d.newNode?.id ?? '').padRight(30);
    stdout.writeln('  ↕  $id  ${d.path}');
  }

  exit(0);
}

Map<String, Object?> _readJson(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('\x1B[31mFile not found: $path\x1B[0m');
    exit(1);
  }
  try {
    return (jsonDecode(file.readAsStringSync()) as Map).cast();
  } on Exception catch (e) {
    stderr.writeln('\x1B[31mInvalid JSON in $path: $e\x1B[0m');
    exit(1);
  }
}
