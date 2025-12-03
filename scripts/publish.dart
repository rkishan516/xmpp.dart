#!/usr/bin/env dart

import 'dart:io';

import 'package:talker/talker.dart';

/// Publish all packages to pub.dev.
///
/// Usage:
///   dart run scripts/publish.dart --dry-run  # Validate only
///   dart run scripts/publish.dart            # Publish all
Future<void> main(List<String> args) async {
  final talker = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: false,
    ),
  );

  final dryRun = args.contains('--dry-run');

  talker.info(dryRun
      ? 'Validating packages for publishing...\n'
      : 'Publishing xmpp.dart packages...\n');

  final packages = getPublishablePackages(talker);
  final failures = <String>[];

  for (final package in packages) {
    final packagePath = 'packages/$package';

    talker.info('${dryRun ? "Validating" : "Publishing"} $package...');

    final pubArgs = ['pub', 'publish'];
    if (dryRun) {
      pubArgs.add('--dry-run');
    } else {
      pubArgs.add('--force');
    }

    final result = await Process.run(
      'dart',
      pubArgs,
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

  talker.info(dryRun ? 'All packages validated!' : 'All packages published!');
}

/// Get packages that can be published (not private).
List<String> getPublishablePackages(Talker talker) {
  final packagesDir = Directory('packages');

  if (!packagesDir.existsSync()) {
    talker.error('Error: packages directory not found');
    exit(1);
  }

  return packagesDir
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.split(Platform.pathSeparator).last)
      .where((name) {
    final pubspec = File('packages/$name/pubspec.yaml');
    if (!pubspec.existsSync()) return false;

    final content = pubspec.readAsStringSync();
    // Skip packages with publish_to: none
    return !content.contains('publish_to: none');
  }).toList()
    ..sort();
}
