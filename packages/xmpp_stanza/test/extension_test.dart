import 'package:test/test.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_stanza/xmpp_stanza.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Example typed extension for testing - Delay (XEP-0203)
class DelayExtension extends StanzaExtension {
  static const String extensionName = 'delay';
  static const String extensionXmlns = 'urn:xmpp:delay';

  final DateTime stamp;
  final String? from;
  final String? reason;

  DelayExtension({required this.stamp, this.from, this.reason});

  @override
  String get name => extensionName;

  @override
  String get xmlns => extensionXmlns;

  @override
  XmlElement toXml() => xml('delay', {
        'xmlns': xmlns,
        'stamp': stamp.toUtc().toIso8601String(),
        if (from != null) 'from': from!,
      }, [
        if (reason != null) reason!
      ]);

  factory DelayExtension.fromXml(XmlElement element) {
    return DelayExtension(
      stamp: DateTime.parse(element.attrs['stamp']!),
      from: element.attrs['from'],
      reason: element.text().isNotEmpty ? element.text() : null,
    );
  }
}

/// Example typed extension for testing - Receipt (XEP-0184)
class ReceiptExtension extends StanzaExtension {
  static const String extensionName = 'received';
  static const String extensionXmlns = 'urn:xmpp:receipts';

  final String messageId;

  ReceiptExtension({required this.messageId});

  @override
  String get name => extensionName;

  @override
  String get xmlns => extensionXmlns;

  @override
  XmlElement toXml() => xml('received', {
        'xmlns': xmlns,
        'id': messageId,
      });

  factory ReceiptExtension.fromXml(XmlElement element) {
    return ReceiptExtension(
      messageId: element.attrs['id']!,
    );
  }
}

void main() {
  setUp(ExtensionRegistry.clear);

  group('StanzaExtension', () {
    test('has correct name and xmlns', () {
      final delay = DelayExtension(stamp: DateTime.now());

      expect(delay.name, 'delay');
      expect(delay.xmlns, 'urn:xmpp:delay');
      expect(delay.tag, 'delay:urn:xmpp:delay');
    });

    test('toXml generates correct XML', () {
      final stamp = DateTime.utc(2023, 6, 15, 10, 30, 0);
      final delay = DelayExtension(
        stamp: stamp,
        from: 'server@example.com',
        reason: 'Offline storage',
      );

      final xmlEl = delay.toXml();
      expect(xmlEl.name, 'delay');
      expect(xmlEl.attrs['xmlns'], 'urn:xmpp:delay');
      expect(xmlEl.attrs['stamp'], '2023-06-15T10:30:00.000Z');
      expect(xmlEl.attrs['from'], 'server@example.com');
      expect(xmlEl.text(), 'Offline storage');
    });

    test('toString returns XML string', () {
      final delay = DelayExtension(stamp: DateTime.utc(2023, 6, 15, 10, 30, 0));
      final str = delay.toString();

      expect(str, contains('<delay'));
      expect(str, contains('xmlns="urn:xmpp:delay"'));
    });
  });

  group('ExtensionRegistry', () {
    test('register and parse extension', () {
      ExtensionRegistry.register<DelayExtension>(
        'delay',
        'urn:xmpp:delay',
        DelayExtension.fromXml,
      );

      final element = xml('delay', {
        'xmlns': 'urn:xmpp:delay',
        'stamp': '2023-06-15T10:30:00.000Z',
        'from': 'server@example.com',
      }, ['Offline storage']);

      final parsed = ExtensionRegistry.parse(element);

      expect(parsed, isA<DelayExtension>());
      final delay = parsed as DelayExtension;
      expect(delay.stamp.year, 2023);
      expect(delay.from, 'server@example.com');
      expect(delay.reason, 'Offline storage');
    });

    test('hasParser returns correct value', () {
      expect(ExtensionRegistry.hasParser('delay', 'urn:xmpp:delay'), false);

      ExtensionRegistry.register<DelayExtension>(
        'delay',
        'urn:xmpp:delay',
        DelayExtension.fromXml,
      );

      expect(ExtensionRegistry.hasParser('delay', 'urn:xmpp:delay'), true);
      expect(ExtensionRegistry.hasParser('other', 'urn:xmpp:other'), false);
    });

    test('unregister removes parser', () {
      ExtensionRegistry.register<DelayExtension>(
        'delay',
        'urn:xmpp:delay',
        DelayExtension.fromXml,
      );

      expect(ExtensionRegistry.hasParser('delay', 'urn:xmpp:delay'), true);

      ExtensionRegistry.unregister('delay', 'urn:xmpp:delay');

      expect(ExtensionRegistry.hasParser('delay', 'urn:xmpp:delay'), false);
    });

    test('parse returns null for unregistered extension', () {
      final element = xml('unknown', {'xmlns': 'urn:xmpp:unknown'});
      final parsed = ExtensionRegistry.parse(element);

      expect(parsed, isNull);
    });

    test('clear removes all parsers', () {
      ExtensionRegistry.register<DelayExtension>(
        'delay',
        'urn:xmpp:delay',
        DelayExtension.fromXml,
      );
      ExtensionRegistry.register<ReceiptExtension>(
        'received',
        'urn:xmpp:receipts',
        ReceiptExtension.fromXml,
      );

      ExtensionRegistry.clear();

      expect(ExtensionRegistry.hasParser('delay', 'urn:xmpp:delay'), false);
      expect(ExtensionRegistry.hasParser('received', 'urn:xmpp:receipts'), false);
    });
  });

  group('Stanza typed extensions', () {
    test('addTypedExtension adds extension', () {
      final msg = Message(
        to: JID.parse('user@example.com'),
        body: 'Hello!',
      );

      final delay = DelayExtension(stamp: DateTime.now());
      msg.addTypedExtension(delay);

      expect(msg.typedExtensions.length, 1);
      expect(msg.typedExtensions.first, delay);
    });

    test('getTypedExtension returns correct extension', () {
      final msg = Message();
      final delay = DelayExtension(stamp: DateTime.now());
      final receipt = ReceiptExtension(messageId: 'msg-123');

      msg.addTypedExtension(delay);
      msg.addTypedExtension(receipt);

      expect(msg.getTypedExtension<DelayExtension>(), delay);
      expect(msg.getTypedExtension<ReceiptExtension>(), receipt);
    });

    test('getTypedExtension returns null when not found', () {
      final msg = Message();

      expect(msg.getTypedExtension<DelayExtension>(), isNull);
    });

    test('getTypedExtensions returns all of type', () {
      final msg = Message();
      final delay1 = DelayExtension(stamp: DateTime.now());
      final delay2 = DelayExtension(stamp: DateTime.now().subtract(const Duration(hours: 1)));
      final receipt = ReceiptExtension(messageId: 'msg-123');

      msg.addTypedExtension(delay1);
      msg.addTypedExtension(delay2);
      msg.addTypedExtension(receipt);

      final delays = msg.getTypedExtensions<DelayExtension>();
      expect(delays.length, 2);
      expect(delays, contains(delay1));
      expect(delays, contains(delay2));
    });

    test('hasTypedExtension returns correct value', () {
      final msg = Message();

      expect(msg.hasTypedExtension<DelayExtension>(), false);

      msg.addTypedExtension(DelayExtension(stamp: DateTime.now()));

      expect(msg.hasTypedExtension<DelayExtension>(), true);
      expect(msg.hasTypedExtension<ReceiptExtension>(), false);
    });

    test('removeTypedExtension removes extension', () {
      final msg = Message();
      final delay = DelayExtension(stamp: DateTime.now());

      msg.addTypedExtension(delay);
      expect(msg.typedExtensions.length, 1);

      final removed = msg.removeTypedExtension(delay);
      expect(removed, true);
      expect(msg.typedExtensions.length, 0);
    });

    test('removeTypedExtensions removes all of type', () {
      final msg = Message();
      msg.addTypedExtension(DelayExtension(stamp: DateTime.now()));
      msg.addTypedExtension(DelayExtension(stamp: DateTime.now()));
      msg.addTypedExtension(ReceiptExtension(messageId: 'msg-123'));

      final count = msg.removeTypedExtensions<DelayExtension>();
      expect(count, 2);
      expect(msg.typedExtensions.length, 1);
      expect(msg.hasTypedExtension<ReceiptExtension>(), true);
    });

    test('typed extension is added to XML', () {
      final msg = Message(body: 'Hello');
      msg.addTypedExtension(DelayExtension(
        stamp: DateTime.utc(2023, 6, 15, 10, 30, 0),
      ));

      final xmlStr = msg.toString();
      expect(xmlStr, contains('<delay'));
      expect(xmlStr, contains('xmlns="urn:xmpp:delay"'));
      expect(xmlStr, contains('stamp="2023-06-15T10:30:00.000Z"'));
    });

    test('parseTypedExtensions parses registered extensions', () {
      ExtensionRegistry.register<DelayExtension>(
        'delay',
        'urn:xmpp:delay',
        DelayExtension.fromXml,
      );

      final element = xml('message', {
        'to': 'user@example.com',
      }, [
        xml('body', {}, ['Hello']),
        xml('delay', {
          'xmlns': 'urn:xmpp:delay',
          'stamp': '2023-06-15T10:30:00.000Z',
        }),
      ]);

      final msg = Message.fromXml(element, parseExtensions: true);

      expect(msg.typedExtensions.length, 1);
      expect(msg.hasTypedExtension<DelayExtension>(), true);

      final delay = msg.getTypedExtension<DelayExtension>()!;
      expect(delay.stamp.year, 2023);
    });
  });

  group('Message with typed extensions', () {
    test('copy preserves typed extensions', () {
      final msg = Message(body: 'Hello');
      final delay = DelayExtension(stamp: DateTime.now());
      msg.addTypedExtension(delay);

      final copied = msg.copy();

      expect(copied.typedExtensions.length, 1);
      expect(copied.getTypedExtension<DelayExtension>(), delay);
    });

    test('reply with copyExtensions preserves extensions', () {
      final msg = Message(
        to: JID.parse('user@example.com'),
        from: JID.parse('sender@example.com'),
        body: 'Original',
      );
      final delay = DelayExtension(stamp: DateTime.now());
      msg.addTypedExtension(delay);

      final reply = msg.reply(body: 'Reply', copyExtensions: true);

      expect(reply.typedExtensions.length, 1);
      expect(reply.hasTypedExtension<DelayExtension>(), true);
    });

    test('reply without copyExtensions has no extensions', () {
      final msg = Message(
        to: JID.parse('user@example.com'),
        from: JID.parse('sender@example.com'),
        body: 'Original',
      );
      msg.addTypedExtension(DelayExtension(stamp: DateTime.now()));

      final reply = msg.reply(body: 'Reply');

      expect(reply.typedExtensions.length, 0);
    });
  });

  group('Presence with typed extensions', () {
    test('copy preserves typed extensions', () {
      final presence = Presence.available(status: 'Online');
      final delay = DelayExtension(stamp: DateTime.now());
      presence.addTypedExtension(delay);

      final copied = presence.copy();

      expect(copied.typedExtensions.length, 1);
      expect(copied.getTypedExtension<DelayExtension>(), delay);
    });

    test('parseExtensions works', () {
      ExtensionRegistry.register<DelayExtension>(
        'delay',
        'urn:xmpp:delay',
        DelayExtension.fromXml,
      );

      final element = xml('presence', {}, [
        xml('show', {}, ['away']),
        xml('delay', {
          'xmlns': 'urn:xmpp:delay',
          'stamp': '2023-06-15T10:30:00.000Z',
        }),
      ]);

      final presence = Presence.fromXml(element, parseExtensions: true);

      expect(presence.typedExtensions.length, 1);
      expect(presence.hasTypedExtension<DelayExtension>(), true);
    });
  });

  group('Both extension types together', () {
    test('raw and typed extensions work together', () {
      final msg = Message(body: 'Hello');

      // Add typed extension
      msg.addTypedExtension(DelayExtension(stamp: DateTime.now()));

      // Add raw XML extension
      msg.addExtension(xml('x', {'xmlns': 'jabber:x:custom'}, ['Custom data']));

      // Both should be accessible
      expect(msg.typedExtensions.length, 1);
      expect(msg.getExtension('x', 'jabber:x:custom'), isNotNull);

      // XML should contain both
      final xmlStr = msg.toString();
      expect(xmlStr, contains('<delay'));
      expect(xmlStr, contains('xmlns="jabber:x:custom"'));
    });
  });
}
