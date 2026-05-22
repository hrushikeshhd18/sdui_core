import 'dart:io';

import 'package:sdui_core/src/cli/diff_command.dart';
import 'package:sdui_core/src/cli/init_command.dart';
import 'package:sdui_core/src/cli/validate_command.dart';

void main(List<String> args) {
  if (args.isEmpty || args.first == '--help' || args.first == '-h') {
    _printHelp();
    exit(0);
  }

  switch (args.first) {
    case 'validate':
      runValidate(args.sublist(1));
    case 'diff':
      runDiff(args.sublist(1));
    case 'init':
      runInit(args.sublist(1));
    default:
      stderr.writeln('Unknown command: ${args.first}');
      stderr.writeln('Run "sdui --help" to see available commands.');
      exit(1);
  }
}

void _printHelp() {
  stdout.writeln('''
sdui — Server-Driven UI toolkit

Usage:
  sdui <command> [options]

Commands:
  validate <file.json>            Validate an SDUI payload against the schema
  diff <current.json> <new.json>  Show which nodes changed between two payloads
  init [dir]                      Scaffold a sample screen JSON (default: current dir)

Run with: flutter pub run sdui_core:sdui <command>
''');
}
