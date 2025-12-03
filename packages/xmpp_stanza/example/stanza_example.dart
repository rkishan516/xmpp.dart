import 'dart:async';
import 'package:talker/talker.dart';
import 'package:xmpp/xmpp.dart';

/// Example demonstrating Message and Presence stanza usage
void main() async {
  // Create a logger for the example
  final talker = Talker(
    settings: TalkerSettings(
      useConsoleLogs: true,
      useHistory: false,
    ),
  );

  // Create a client with anonymous auth (using anon.localhost domain)
  final client = Client(ClientOptions(
    service: 'ws://localhost:5280/xmpp-websocket',
    domain: 'anon.localhost',
  ));

  // Enable debug logging
  debug(client, force: true);

  // Handle incoming messages
  client.on<XmlElement>('stanza', (stanza) {
    if (stanza.isMessage) {
      final msg = stanza.toMessage();
      if (msg != null && msg.body != null) {
        talker.info('Received message: ${msg.body}');
        talker.verbose('  From: ${msg.from}');
        talker.verbose('  Type: ${msg.messageType}');
      }
    } else if (stanza.isPresence) {
      final presence = stanza.toPresence();
      if (presence != null) {
        talker.info('Received presence from: ${presence.from}');
        talker.verbose('  Type: ${presence.presenceType}');
        if (presence.status != null) {
          talker.verbose('  Status: ${presence.status}');
        }
      }
    }
  });

  // Handle online event
  client.on<JID?>('online', (jid) async {
    talker.info('Connected as: $jid');

    // Send initial presence (available with status)
    final presence = Presence.available(
      show: PresenceShow.chat,
      status: 'Testing xmpp_stanza package',
      priority: 10,
    );
    talker.info('Sending presence: ${presence.presenceType}');
    await client.send(presence.element);

    // Create and display a sample message (not sending since no recipient)
    final message = Message(
      to: JID.parse('test@localhost'),
      type: MessageType.chat,
      body: 'Hello from xmpp_stanza!',
      subject: 'Test Subject',
    );
    talker.info('Sample message created:');
    talker.verbose('  To: ${message.to}');
    talker.verbose('  Type: ${message.messageType}');
    talker.verbose('  Body: ${message.body}');
    talker.verbose('  Subject: ${message.subject}');
    talker.verbose('  XML: ${message.toString().substring(0, 80)}...');

    // Test message reply
    final received = Message(
      from: JID.parse('other@localhost'),
      to: jid,
      type: MessageType.chat,
      body: 'Original message',
      thread: 'thread-123',
    );
    final reply = received.reply(body: 'This is my reply');
    talker.info('Reply message:');
    talker.verbose('  To: ${reply.to}');
    talker.verbose('  Thread preserved: ${reply.thread}');
    talker.verbose('  Body: ${reply.body}');

    // Test presence factory methods
    talker.info('Presence factory methods:');
    talker.verbose('  Subscribe: ${Presence.subscribe(JID.parse("friend@localhost")).presenceType}');
    talker.verbose('  Unavailable: ${Presence.unavailable(status: "Going offline").status}');

    // Wait a bit then disconnect
    await Future<void>.delayed(const Duration(seconds: 2));

    // Send unavailable presence before disconnecting
    final offline = Presence.unavailable(status: 'Goodbye!');
    talker.info('Sending offline presence');
    await client.send(offline.element);

    await Future<void>.delayed(const Duration(milliseconds: 500));
    await client.stop();
  });

  // Handle errors
  client.on<dynamic>('error', (error) {
    talker.error('Error: $error');
  });

  // Handle offline
  client.on<dynamic>('offline', (_) {
    talker.warning('Disconnected');
  });

  // Start the client
  talker.info('Connecting to Prosody server...');
  try {
    await client.start();
  } catch (e) {
    talker.error('Failed to connect: $e');
  }
}
