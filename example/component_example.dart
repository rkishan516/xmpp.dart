/// Example XMPP component usage.
///
/// Before running this example, ensure you have:
/// 1. A running XMPP server (e.g., Prosody) on localhost
/// 2. Configured a component in prosody.cfg.lua
///
/// Default Prosody component config:
///   Component "component.localhost"
///     component_secret = "mysecretcomponentpassword"
///
/// To run:
///   dart run example/component_example.dart
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

  // Default component settings
  const service = 'xmpp://localhost:5347';
  const domain = 'component.localhost';
  const password = 'mysecretcomponentpassword';

  talker.info('Connecting component to $service...');
  talker.info('Domain: $domain');

  final comp = Component(ComponentOptions(
    service: service,
    domain: domain,
    password: password,
  ));

  // Enable debug logging for all XMPP traffic
  final debugger = debug(comp, force: true, talker: talker);

  // Set up application-level event handlers
  comp.on<XmlElement>('stanza', (stanza) {
    // Echo back messages
    if (stanza.name == 'message') {
      final from = stanza.attrs['from'];
      final to = stanza.attrs['to'];
      final body = stanza.getChildText('body');

      if (body != null && from != null) {
        talker.info('Message from $from: $body');

        // Send echo reply
        comp.send(xml('message', {
          'to': from,
          'from': to ?? domain,
          'type': 'chat',
        }, [
          xml('body', {}, ['Echo: $body']),
        ]));
      }
    }
  });

  comp.on<dynamic>('online', (jid) {
    talker.info('Component online as: $jid');
  });

  try {
    // Start the component
    final jid = await comp.start();
    talker.info('Component connected! JID: $jid');

    // Keep running and handle stanzas
    talker.info('Component running. Press Ctrl+C to quit.');

    // Handle graceful shutdown
    ProcessSignal.sigint.watch().listen((_) async {
      talker.info('Disconnecting component...');
      debugger?.dispose();
      await comp.stop();
      talker.info('Component disconnected.');
      exit(0);
    });

    // Keep the process alive
    await Future<void>.delayed(const Duration(days: 365));
  } catch (e, stack) {
    talker.error('Failed to connect component: $e', e, stack);
    exit(1);
  }
}
