#!/usr/bin/env dart

import 'dart:io';

import 'package:talker/talker.dart';

/// Run tests for all packages.
///
/// Usage:
///   dart run scripts/test.dart           # Test all packages
///   dart run scripts/test.dart --package=xmpp_jid  # Test specific package
Future<void> main(List<String> args) async {
  final talker = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: false,
    ),
  );

  String? specificPackage;

  for (final arg in args) {
    if (arg.startsWith('--package=')) {
      specificPackage = arg.substring('--package='.length);
    }
  }

  talker.info('Testing xmpp.dart packages...\n');

  final packages =
      specificPackage != null ? [specificPackage] : getPackages(talker);
  final failures = <String>[];

  for (final package in packages) {
    final packagePath = 'packages/$package';
    final testDir = Directory('$packagePath/test');

    if (!testDir.existsSync()) {
      talker.warning('Skipping $package (no tests)');
      continue;
    }

    talker.info('Testing $package...');

    final result = await Process.run(
      'dart',
      ['test'],
      workingDirectory: packagePath,
    );

    if (result.exitCode != 0) {
      talker.error('FAILED: $package');
      talker.verbose(result.stdout.toString());
      talker.verbose(result.stderr.toString());
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

  talker.info('All tests passed!');
}

/// Get all packages with test directories.
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
      .where((name) => Directory('packages/$name/test').existsSync())
      .toList()
    ..sort();
}
