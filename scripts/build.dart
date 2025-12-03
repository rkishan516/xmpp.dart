#!/usr/bin/env dart

import 'dart:io';

import 'package:talker/talker.dart';

/// Build all packages in dependency order.
///
/// Usage: dart run scripts/build.dart
Future<void> main(List<String> args) async {
  final talker = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: false,
    ),
  );

  talker.info('Building xmpp.dart packages...\n');

  final packages = getPackagesInOrder();

  for (final package in packages) {
    final packagePath = 'packages/$package';
    final pubspec = File('$packagePath/pubspec.yaml');

    if (!pubspec.existsSync()) {
      continue;
    }

    talker.info('Building $package...');

    final result = await Process.run(
      'dart',
      ['pub', 'get'],
      workingDirectory: packagePath,
    );

    if (result.exitCode != 0) {
      talker.error('Failed to build $package');
      talker.error(result.stderr.toString());
      exit(1);
    }

    talker.info('  OK');
  }

  talker.info('\nAll packages built successfully!');
}

/// Get packages in dependency order (dependencies first).
List<String> getPackagesInOrder() {
  return [
    // Level 0: No internal dependencies
    'xmpp_base64',
    'xmpp_id',
    'xmpp_time',
    'xmpp_error',

    // Level 1: Depends on error
    'xmpp_events',
    'xmpp_jid',

    // Level 2: Depends on events
    'xmpp_xml',

    // Level 3: Connection layer
    'xmpp_connection',
    'xmpp_connection_tcp',
    'xmpp_middleware',
    'xmpp_iq',

    // Level 4: Stream features
    'xmpp_stream_features',
    'xmpp_starttls',
    'xmpp_resource_binding',
    'xmpp_session_establishment',

    // Level 5: Authentication
    'xmpp_sasl',
    'xmpp_sasl_plain',
    'xmpp_sasl_scram_sha_1',
    'xmpp_sasl_anonymous',
    'xmpp_sasl2',
    'xmpp_sasl_ht_sha_256_none',

    // Level 6: Advanced features
    'xmpp_stream_management',
    'xmpp_reconnect',
    'xmpp_resolve',

    // Level 7: Transports
    'xmpp_tcp',
    'xmpp_tls',
    'xmpp_websocket',

    // Level 8: Utilities
    'xmpp_debug',
    'xmpp_uri',

    // Level 9: Client/Component
    'xmpp_client_core',
    'xmpp_client',
    'xmpp_component_core',
    'xmpp_component',

    // Level 10: Testing and main package
    'xmpp_test',
    'xmpp',
  ];
}
