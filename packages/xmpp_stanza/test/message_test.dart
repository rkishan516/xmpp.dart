import 'package:test/test.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_stanza/xmpp_stanza.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('MessageType', () {
    test('fromString returns correct type', () {
      expect(MessageTypeExtension.fromString('chat'), MessageType.chat);
      expect(MessageTypeExtension.fromString('error'), MessageType.error);
      expect(MessageTypeExtension.fromString('groupchat'), MessageType.groupchat);
      expect(MessageTypeExtension.fromString('headline'), MessageType.headline);
      expect(MessageTypeExtension.fromString('normal'), MessageType.normal);
      expect(MessageTypeExtension.fromString(null), MessageType.normal);
      expect(MessageTypeExtension.fromString('unknown'), MessageType.normal);
    });

    test('value returns correct string', () {
      expect(MessageType.chat.value, 'chat');
      expect(MessageType.error.value, 'error');
      expect(MessageType.groupchat.value, 'groupchat');
      expect(MessageType.headline.value, 'headline');
      expect(MessageType.normal.value, 'normal');
    });
  });

  group('Message', () {
    test('creates basic message', () {
      final msg = Message(
        to: JID.parse('user@example.com'),
        type: MessageType.chat,
        body: 'Hello!',
      );

      expect(msg.to, isNotNull);
      expect(msg.to.toString(), 'user@example.com');
      expect(msg.messageType, MessageType.chat);
      expect(msg.body, 'Hello!');
    });

    test('creates message with all fields', () {
      final msg = Message(
        to: JID.parse('user@example.com'),
        from: JID.parse('sender@example.com'),
        type: MessageType.chat,
        id: 'msg-1',
        body: 'Hello!',
        subject: 'Greetings',
        thread: 'thread-123',
        lang: 'en',
      );

      expect(msg.to.toString(), 'user@example.com');
      expect(msg.from.toString(), 'sender@example.com');
      expect(msg.messageType, MessageType.chat);
      expect(msg.id, 'msg-1');
      expect(msg.body, 'Hello!');
      expect(msg.subject, 'Greetings');
      expect(msg.thread, 'thread-123');
      expect(msg.lang, 'en');
    });

    test('parses from XML', () {
      final element = xml('message', {
        'to': 'user@example.com',
        'from': 'sender@example.com',
        'type': 'chat',
        'id': 'msg-1',
      }, [
        xml('body', {}, ['Hello!']),
        xml('subject', {}, ['Greetings']),
        xml('thread', {}, ['thread-123']),
      ]);

      final msg = Message.fromXml(element);

      expect(msg.to.toString(), 'user@example.com');
      expect(msg.from.toString(), 'sender@example.com');
      expect(msg.messageType, MessageType.chat);
      expect(msg.id, 'msg-1');
      expect(msg.body, 'Hello!');
      expect(msg.subject, 'Greetings');
      expect(msg.thread, 'thread-123');
    });

    test('parses from XML element directly', () {
      final element = xml('message', {
        'type': 'chat',
        'to': 'user@example.com',
      }, [
        xml('body', {}, ['Hello!']),
      ]);

      final msg = Message.fromXml(element);

      expect(msg.to.toString(), 'user@example.com');
      expect(msg.messageType, MessageType.chat);
      expect(msg.body, 'Hello!');
    });

    test('parses from XML string', () {
      final msg = Message.fromString(
        '<message type="chat" to="user@example.com"><body>Hello!</body></message>',
      );

      expect(msg.to.toString(), 'user@example.com');
      expect(msg.messageType, MessageType.chat);
      expect(msg.body, 'Hello!');
    });

    test('normal type does not add type attribute', () {
      final msg = Message(
        to: JID.parse('user@example.com'),
        type: MessageType.normal,
      );

      expect(msg.element.attrs['type'], isNull);
    });

    test('setters work correctly', () {
      final msg = Message();

      msg.body = 'New body';
      expect(msg.body, 'New body');

      msg.subject = 'New subject';
      expect(msg.subject, 'New subject');

      msg.thread = 'new-thread';
      expect(msg.thread, 'new-thread');

      msg.messageType = MessageType.groupchat;
      expect(msg.messageType, MessageType.groupchat);
    });

    test('setter removes element when set to null', () {
      final msg = Message(body: 'Hello', subject: 'Test', thread: 'thread-1');

      msg.body = null;
      expect(msg.body, isNull);

      msg.subject = null;
      expect(msg.subject, isNull);

      msg.thread = null;
      expect(msg.thread, isNull);
    });

    test('helper getters work', () {
      expect(Message(type: MessageType.chat).isChat, true);
      expect(Message(type: MessageType.groupchat).isGroupChat, true);
      expect(Message(type: MessageType.error).isError, true);
      expect(Message(type: MessageType.normal).isChat, false);
    });

    test('addBody with language', () {
      final msg = Message(body: 'Hello');
      msg.addBody('Hola', lang: 'es');

      final bodies = msg.bodies;
      expect(bodies.length, 2);
      expect(bodies[0].text, 'Hello');
      expect(bodies[1].text, 'Hola');
      expect(bodies[1].lang, 'es');
    });

    test('getBodyForLang returns correct body', () {
      final msg = Message(body: 'Hello');
      msg.addBody('Hola', lang: 'es');
      msg.addBody('Bonjour', lang: 'fr');

      expect(msg.getBodyForLang('es'), 'Hola');
      expect(msg.getBodyForLang('fr'), 'Bonjour');
      expect(msg.getBodyForLang('de'), isNull);
    });

    test('reply creates correct response', () {
      final original = Message(
        to: JID.parse('user@example.com'),
        from: JID.parse('sender@example.com'),
        type: MessageType.chat,
        thread: 'thread-123',
      );

      final reply = original.reply(body: 'Reply body');

      expect(reply.to.toString(), 'sender@example.com');
      expect(reply.messageType, MessageType.chat);
      expect(reply.thread, 'thread-123');
      expect(reply.body, 'Reply body');
    });

    test('copy creates independent copy', () {
      final original = Message(
        to: JID.parse('user@example.com'),
        body: 'Original',
      );

      final copy = original.copy();
      copy.body = 'Modified';

      expect(original.body, 'Original');
      expect(copy.body, 'Modified');
    });

    test('toXml returns XmlElement', () {
      final msg = Message(
        to: JID.parse('user@example.com'),
        type: MessageType.chat,
        body: 'Hello!',
      );

      final xmlEl = msg.toXml();
      expect(xmlEl, isA<XmlElement>());
      expect(xmlEl.name, 'message');
      expect(xmlEl.attrs['to'], 'user@example.com');
      expect(xmlEl.attrs['type'], 'chat');
    });

    test('toString returns XML string', () {
      final msg = Message(
        to: JID.parse('user@example.com'),
        type: MessageType.chat,
        body: 'Hello!',
      );

      final xmlStr = msg.toString();
      expect(xmlStr, contains('<message'));
      expect(xmlStr, contains('to="user@example.com"'));
      expect(xmlStr, contains('type="chat"'));
      expect(xmlStr, contains('<body>Hello!</body>'));
    });
  });

  group('MessageParsing extension', () {
    test('isMessage returns correct value', () {
      final msgEl = xml('message', {}, []);
      final presEl = xml('presence', {}, []);

      expect(msgEl.isMessage, true);
      expect(presEl.isMessage, false);
    });

    test('toMessage converts element', () {
      final msgEl = xml('message', {'type': 'chat'}, [
        xml('body', {}, ['Hello']),
      ]);

      final msg = msgEl.toMessage();
      expect(msg, isNotNull);
      expect(msg!.messageType, MessageType.chat);
      expect(msg.body, 'Hello');
    });

    test('toMessage returns null for non-message', () {
      final presEl = xml('presence', {}, []);
      expect(presEl.toMessage(), isNull);
    });
  });
}
