import 'package:test/test.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_stanza/xmpp_stanza.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('Stanza', () {
    test('gets id attribute', () {
      final element = xml('message', {'id': 'msg-123'}, []);
      final stanza = Message.fromXml(element);

      expect(stanza.id, 'msg-123');
    });

    test('sets id attribute', () {
      final stanza = Message();
      stanza.id = 'new-id';

      expect(stanza.id, 'new-id');
      expect(stanza.element.attrs['id'], 'new-id');
    });

    test('gets to JID', () {
      final element = xml('message', {'to': 'user@example.com/resource'}, []);
      final stanza = Message.fromXml(element);

      expect(stanza.to.toString(), 'user@example.com/resource');
    });

    test('sets to JID', () {
      final stanza = Message();
      stanza.to = JID.parse('user@example.com');

      expect(stanza.to.toString(), 'user@example.com');
      expect(stanza.element.attrs['to'], 'user@example.com');
    });

    test('gets from JID', () {
      final element = xml('message', {'from': 'sender@example.com'}, []);
      final stanza = Message.fromXml(element);

      expect(stanza.from.toString(), 'sender@example.com');
    });

    test('sets from JID', () {
      final stanza = Message();
      stanza.from = JID.parse('sender@example.com');

      expect(stanza.from.toString(), 'sender@example.com');
      expect(stanza.element.attrs['from'], 'sender@example.com');
    });

    test('gets type attribute', () {
      final element = xml('message', {'type': 'chat'}, []);
      final stanza = Message.fromXml(element);

      expect(stanza.type, 'chat');
    });

    test('sets type attribute', () {
      final stanza = Message();
      stanza.type = 'groupchat';

      expect(stanza.type, 'groupchat');
      expect(stanza.element.attrs['type'], 'groupchat');
    });

    test('gets lang attribute', () {
      final element = xml('message', {'xml:lang': 'en'}, []);
      final stanza = Message.fromXml(element);

      expect(stanza.lang, 'en');
    });

    test('sets lang attribute', () {
      final stanza = Message();
      stanza.lang = 'es';

      expect(stanza.lang, 'es');
      expect(stanza.element.attrs['xml:lang'], 'es');
    });

    test('getChild returns child element', () {
      final element = xml('message', {}, [
        xml('body', {}, ['Hello']),
        xml('subject', {}, ['Test']),
      ]);
      final stanza = Message.fromXml(element);

      final body = stanza.getChild('body');
      expect(body, isNotNull);
      expect(body!.text(), 'Hello');
    });

    test('getChild returns null for missing child', () {
      final stanza = Message();
      expect(stanza.getChild('nonexistent'), isNull);
    });

    test('getChild with namespace', () {
      final element = xml('message', {}, [
        xml('x', {'xmlns': 'jabber:x:data'}, []),
      ]);
      final stanza = Message.fromXml(element);

      expect(stanza.getChild('x', 'jabber:x:data'), isNotNull);
      expect(stanza.getChild('x', 'other:namespace'), isNull);
    });

    test('getChildren returns all matching children', () {
      final element = xml('message', {}, [
        xml('body', {}, ['Hello']),
        xml('body', {'xml:lang': 'es'}, ['Hola']),
      ]);
      final stanza = Message.fromXml(element);

      final bodies = stanza.getChildren('body');
      expect(bodies.length, 2);
    });

    test('getChildText returns text content', () {
      final element = xml('message', {}, [
        xml('body', {}, ['Hello World']),
      ]);
      final stanza = Message.fromXml(element);

      expect(stanza.getChildText('body'), 'Hello World');
      expect(stanza.getChildText('subject'), isNull);
    });

    test('addChild appends element', () {
      final stanza = Message();
      stanza.addChild(xml('delay', {'stamp': '2023-01-01T00:00:00Z'}, []));

      expect(stanza.getChild('delay'), isNotNull);
      expect(stanza.getChild('delay')!.attrs['stamp'], '2023-01-01T00:00:00Z');
    });

    test('addExtension and getExtension work together', () {
      final stanza = Message();
      final extension = xml('active', {'xmlns': 'http://jabber.org/protocol/chatstates'}, []);
      stanza.addExtension(extension);

      final retrieved = stanza.getExtension('active', 'http://jabber.org/protocol/chatstates');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'active');
    });

    test('getExtensions returns all with namespace', () {
      final stanza = Message();
      stanza.addExtension(xml('x', {'xmlns': 'jabber:x:data'}, []));
      stanza.addExtension(xml('field', {'xmlns': 'jabber:x:data'}, []));
      stanza.addExtension(xml('other', {'xmlns': 'other:namespace'}, []));

      final extensions = stanza.getExtensions('jabber:x:data');
      expect(extensions.length, 2);
    });

    test('hasError returns true when error child exists', () {
      final element = xml('message', {'type': 'error'}, [
        xml('error', {'type': 'cancel'}, [
          xml('not-allowed', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-stanzas'}, []),
        ]),
      ]);
      final stanza = Message.fromXml(element);

      expect(stanza.hasError, true);
    });

    test('hasError returns false when no error child', () {
      final stanza = Message(body: 'Hello');
      expect(stanza.hasError, false);
    });

    test('error returns error element', () {
      final element = xml('message', {'type': 'error'}, [
        xml('error', {'type': 'cancel', 'code': '405'}, []),
      ]);
      final stanza = Message.fromXml(element);

      expect(stanza.error, isNotNull);
      expect(stanza.error!.attrs['type'], 'cancel');
      expect(stanza.error!.attrs['code'], '405');
    });

    test('toXml returns XmlElement', () {
      final stanza = Message(
        to: JID.parse('user@example.com'),
        type: MessageType.chat,
        body: 'Hello',
      );

      final xmlEl = stanza.toXml();
      expect(xmlEl, isA<XmlElement>());
      expect(xmlEl.name, 'message');
      expect(xmlEl.attrs['to'], 'user@example.com');
    });

    test('toString returns XML string', () {
      final stanza = Message(body: 'Test');
      final str = stanza.toString();
      expect(str, isA<String>());
      expect(str, contains('<message'));
      expect(str, contains('<body>Test</body>'));
    });

    test('name returns element name', () {
      expect(Message().name, 'message');
      expect(Presence().name, 'presence');
    });
  });

  group('StanzaParsing extension', () {
    test('isStanza returns true for stanza elements', () {
      expect(xml('message', {}, []).isStanza, true);
      expect(xml('presence', {}, []).isStanza, true);
      expect(xml('iq', {}, []).isStanza, true);
    });

    test('isStanza returns false for non-stanza elements', () {
      expect(xml('stream:stream', {}, []).isStanza, false);
      expect(xml('body', {}, []).isStanza, false);
      expect(xml('features', {}, []).isStanza, false);
    });
  });
}
