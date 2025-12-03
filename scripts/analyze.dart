#!/usr/bin/env dart

import 'dart:io';

import 'package:talker/talker.dart';

/// Run static analysis on all packages.
///
/// Usage: dart run scripts/analyze.dart
Future<void> main(List<String> args) async {
  final talker = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: false,
    ),
  );

  talker.info('Analyzing xmpp.dart packages...\n');

  final packages = getPackages(talker);
  final failures = <String>[];

  for (final package in packages) {
    final packagePath = 'packages/$package';
    final pubspec = File('$packagePath/pubspec.yaml');

    if (!pubspec.existsSync()) {
      continue;
    }

    talker.info('Analyzing $package...');

    final result = await Process.run(
      'dart',
      ['analyze', '--fatal-infos'],
      workingDirectory: packagePath,
    );

    if (result.exitCode != 0) {
      talker.error('FAILED: $package');
      talker.verbose(result.stdout.toString());
      failures.add(package);
    } else {
      talker.info('  OK');
    }
  }

  if (failures.isNotEmpty) {
    talker.error('Failed packages:');
    for (final f in failures) {
      talker.error('  - $f');
    }
    exit(1);
  }

  talker.info('All packages pass analysis!');
}

/// Get all packages.
List<String> getPackages(Talker talker) {
  final packagesDir = Directory('packages');

  if (!packagesDir.existsSync()) {
    talker.error('Error: packages directory not found');
    exit(1);
  }

  return packagesDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split(Platform.pathSeparator).last)
      .where((name) => File('packages/$name/pubspec.yaml').existsSync())
      .toList()
    ..sort();
}
