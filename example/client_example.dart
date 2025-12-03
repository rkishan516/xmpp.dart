/// Example XMPP client usage.
///
/// Before running this example, ensure you have:
/// 1. A running XMPP server (e.g., Prosody) on localhost
/// 2. Created a user account (or use anonymous auth)
///
/// To run with anonymous auth on Prosody:
///   dart run example/client_example.dart --anonymous
///
/// To run with credentials:
///   dart run example/client_example.dart --user=testuser --password=testpass
library;

import 'dart:async';
import 'dart:io';

import 'package:talker/talker.dart';
import 'package:xmpp/xmpp.dart';

void main(List<String> args) async {
  // Set up logger
  final talker = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: false,
    ),
  );

  // Parse arguments
  final anonymous = args.contains('--anonymous');
  String? username;
  String? password;

  for (final arg in args) {
    if (arg.startsWith('--user=')) {
      username = arg.substring(7);
    } else if (arg.startsWith('--password=')) {
      password = arg.substring(11);
    }
  }

  // Default to WebSocket connection to localhost
  const service = 'ws://localhost:5280/xmpp-websocket';
  final domain = anonymous ? 'anon.localhost' : 'localhost';

  talker.info('Connecting to $service...');
  talker.info('Domain: $domain');
  talker.info('Auth: ${anonymous ? "anonymous" : "PLAIN ($username)"}');

  final client = Client(ClientOptions(
    service: service,
    domain: domain,
    username: anonymous ? null : username,
    password: anonymous ? null : password,
  ));

  // Enable debug logging for all XMPP traffic
  final debugger = debug(client, force: true, talker: talker);

  // Set up application-level event handlers
  client.on<XmlElement>('stanza', (stanza) {
    if (stanza.name == 'message') {
      final from = stanza.attrs['from'];
      final body = stanza.getChildText('body');
      if (body != null) {
        talker.info('Message from $from: $body');
      }
    }
  });

  client.on<dynamic>('online', (jid) {
    talker.info('Online as: $jid');
  });

  try {
    // Start the client
    final jid = await client.start();
    talker.info('Connected! JID: $jid');

    // Send initial presence
    await client.send(xml('presence', {}, []));
    talker.info('Sent presence');

    // Keep running and listen for messages
    talker.info('Listening for messages. Press Ctrl+C to quit.');

    // Handle graceful shutdown
    ProcessSignal.sigint.watch().listen((_) async {
      talker.info('Disconnecting...');
      debugger?.dispose();
      await client.stop();
      talker.info('Disconnected.');
      exit(0);
    });

    // Keep the process alive
    await Future<void>.delayed(const Duration(days: 365));
  } catch (e, stack) {
    talker.error('Failed to connect: $e', e, stack);
    exit(1);
  }
}
