import 'dart:convert';
import 'dart:io';

import 'package:sdui_core/src/parser/sdui_validator.dart';

void runValidate(List<String> args) {
  if (args.isEmpty || args.first == '--help') {
    stdout.writeln('Usage: sdui validate <file.json>');
    exit(0);
  }

  final path = args.first;
  final file = File(path);
  if (!file.existsSync()) {
    _err('File not found: $path');
    exit(1);
  }

  Map<String, Object?> payload;
  try {
    payload = (jsonDecode(file.readAsStringSync()) as Map).cast();
  } on Exception catch (e) {
    _err('Invalid JSON in $path: $e');
    exit(1);
  }

  final result = SduiValidator.validate(payload);

  if (result.isValid) {
    _ok('$path — valid'
        '${result.warnings.isEmpty ? '' : ' (${result.warnings.length} warning(s))'}');
    for (final w in result.warnings) {
      _warn('  ⚠  ${w.path.padRight(28)} ${w.message}');
    }
    exit(0);
  } else {
    _fail(
      '$path — ${result.errors.length} error(s), ${result.warnings.length} warning(s)',
    );
    for (final e in result.errors) {
      _err('  ✗  ${e.code.padRight(28)} ${e.path.padRight(20)} ${e.message}');
    }
    for (final w in result.warnings) {
      _warn('  ⚠  ${''.padRight(28)} ${w.path.padRight(20)} ${w.message}');
    }
    exit(1);
  }
}

void _ok(String msg) => stdout.writeln('\x1B[32m✓ $msg\x1B[0m');
void _fail(String msg) => stdout.writeln('\x1B[31m✗ $msg\x1B[0m');
void _warn(String msg) => stdout.writeln('\x1B[33m$msg\x1B[0m');
void _err(String msg) => stderr.writeln('\x1B[31m$msg\x1B[0m');
