import 'package:test/test.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_stanza/xmpp_stanza.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('PresenceType', () {
    test('fromString returns correct type', () {
      expect(PresenceTypeExtension.fromString('unavailable'), PresenceType.unavailable);
      expect(PresenceTypeExtension.fromString('subscribe'), PresenceType.subscribe);
      expect(PresenceTypeExtension.fromString('subscribed'), PresenceType.subscribed);
      expect(PresenceTypeExtension.fromString('unsubscribe'), PresenceType.unsubscribe);
      expect(PresenceTypeExtension.fromString('unsubscribed'), PresenceType.unsubscribed);
      expect(PresenceTypeExtension.fromString('probe'), PresenceType.probe);
      expect(PresenceTypeExtension.fromString('error'), PresenceType.error);
      expect(PresenceTypeExtension.fromString(null), PresenceType.available);
      expect(PresenceTypeExtension.fromString('unknown'), PresenceType.available);
    });

    test('value returns correct string', () {
      expect(PresenceType.available.value, isNull); // No type attribute for available
      expect(PresenceType.unavailable.value, 'unavailable');
      expect(PresenceType.subscribe.value, 'subscribe');
      expect(PresenceType.subscribed.value, 'subscribed');
      expect(PresenceType.unsubscribe.value, 'unsubscribe');
      expect(PresenceType.unsubscribed.value, 'unsubscribed');
      expect(PresenceType.probe.value, 'probe');
      expect(PresenceType.error.value, 'error');
    });
  });

  group('PresenceShow', () {
    test('fromString returns correct show', () {
      expect(PresenceShowExtension.fromString('chat'), PresenceShow.chat);
      expect(PresenceShowExtension.fromString('away'), PresenceShow.away);
      expect(PresenceShowExtension.fromString('xa'), PresenceShow.xa);
      expect(PresenceShowExtension.fromString('dnd'), PresenceShow.dnd);
      expect(PresenceShowExtension.fromString(null), isNull);
      expect(PresenceShowExtension.fromString('unknown'), isNull);
    });

    test('value returns correct string', () {
      expect(PresenceShow.chat.value, 'chat');
      expect(PresenceShow.away.value, 'away');
      expect(PresenceShow.xa.value, 'xa');
      expect(PresenceShow.dnd.value, 'dnd');
    });
  });

  group('Presence', () {
    test('creates basic presence', () {
      final presence = Presence();

      expect(presence.presenceType, PresenceType.available);
      expect(presence.element.attrs['type'], isNull);
    });

    test('creates presence with all fields', () {
      final presence = Presence(
        to: JID.parse('user@example.com'),
        from: JID.parse('sender@example.com'),
        type: PresenceType.unavailable,
        id: 'pres-1',
        show: PresenceShow.away,
        status: 'Be right back',
        priority: 5,
        lang: 'en',
      );

      expect(presence.to.toString(), 'user@example.com');
      expect(presence.from.toString(), 'sender@example.com');
      expect(presence.presenceType, PresenceType.unavailable);
      expect(presence.id, 'pres-1');
      expect(presence.show, PresenceShow.away);
      expect(presence.status, 'Be right back');
      expect(presence.priority, 5);
      expect(presence.lang, 'en');
    });

    test('parses from XML', () {
      final element = xml('presence', {
        'to': 'user@example.com',
        'from': 'sender@example.com',
        'type': 'unavailable',
        'id': 'pres-1',
      }, [
        xml('show', {}, ['away']),
        xml('status', {}, ['Be right back']),
        xml('priority', {}, ['5']),
      ]);

      final presence = Presence.fromXml(element);

      expect(presence.to.toString(), 'user@example.com');
      expect(presence.from.toString(), 'sender@example.com');
      expect(presence.presenceType, PresenceType.unavailable);
      expect(presence.id, 'pres-1');
      expect(presence.show, PresenceShow.away);
      expect(presence.status, 'Be right back');
      expect(presence.priority, 5);
    });

    test('available presence has no type attribute', () {
      final presence = Presence(type: PresenceType.available);
      expect(presence.element.attrs['type'], isNull);
    });

    test('factory Presence.available creates correct presence', () {
      final presence = Presence.available(
        show: PresenceShow.chat,
        status: 'Ready to chat',
        priority: 10,
      );

      expect(presence.presenceType, PresenceType.available);
      expect(presence.show, PresenceShow.chat);
      expect(presence.status, 'Ready to chat');
      expect(presence.priority, 10);
    });

    test('factory Presence.unavailable creates correct presence', () {
      final presence = Presence.unavailable(status: 'Going offline');

      expect(presence.presenceType, PresenceType.unavailable);
      expect(presence.status, 'Going offline');
    });

    test('factory Presence.subscribe creates correct presence', () {
      final to = JID.parse('user@example.com');
      final presence = Presence.subscribe(to);

      expect(presence.presenceType, PresenceType.subscribe);
      expect(presence.to.toString(), 'user@example.com');
    });

    test('factory Presence.subscribed creates correct presence', () {
      final to = JID.parse('user@example.com');
      final presence = Presence.subscribed(to);

      expect(presence.presenceType, PresenceType.subscribed);
      expect(presence.to.toString(), 'user@example.com');
    });

    test('factory Presence.unsubscribe creates correct presence', () {
      final to = JID.parse('user@example.com');
      final presence = Presence.unsubscribe(to);

      expect(presence.presenceType, PresenceType.unsubscribe);
      expect(presence.to.toString(), 'user@example.com');
    });

    test('factory Presence.unsubscribed creates correct presence', () {
      final to = JID.parse('user@example.com');
      final presence = Presence.unsubscribed(to);

      expect(presence.presenceType, PresenceType.unsubscribed);
      expect(presence.to.toString(), 'user@example.com');
    });

    test('setters work correctly', () {
      final presence = Presence();

      presence.show = PresenceShow.dnd;
      expect(presence.show, PresenceShow.dnd);

      presence.status = 'Do not disturb';
      expect(presence.status, 'Do not disturb');

      presence.priority = 3;
      expect(presence.priority, 3);

      presence.presenceType = PresenceType.unavailable;
      expect(presence.presenceType, PresenceType.unavailable);
    });

    test('setter removes element when set to null', () {
      final presence = Presence(
        show: PresenceShow.away,
        status: 'Away',
        priority: 5,
      );

      presence.show = null;
      expect(presence.show, isNull);

      presence.status = null;
      expect(presence.status, isNull);

      presence.priority = null;
      expect(presence.priority, isNull);
    });

    test('presenceType setter removes type for available', () {
      final presence = Presence(type: PresenceType.unavailable);
      expect(presence.element.attrs['type'], 'unavailable');

      presence.presenceType = PresenceType.available;
      expect(presence.element.attrs['type'], isNull);
    });

    test('helper getters work', () {
      expect(Presence(type: PresenceType.available).isAvailable, true);
      expect(Presence(type: PresenceType.unavailable).isUnavailable, true);
      expect(Presence(type: PresenceType.subscribe).isSubscribe, true);
      expect(Presence(type: PresenceType.subscribed).isSubscribed, true);
      expect(Presence(type: PresenceType.error).isError, true);

      expect(Presence(type: PresenceType.available).isUnavailable, false);
    });

    test('copy creates independent copy', () {
      final original = Presence(
        status: 'Original status',
        show: PresenceShow.away,
      );

      final copy = original.copy();
      copy.status = 'Modified status';

      expect(original.status, 'Original status');
      expect(copy.status, 'Modified status');
    });

    test('toXml returns XmlElement', () {
      final presence = Presence(
        type: PresenceType.unavailable,
        status: 'Going offline',
      );

      final xmlEl = presence.toXml();
      expect(xmlEl, isA<XmlElement>());
      expect(xmlEl.name, 'presence');
      expect(xmlEl.attrs['type'], 'unavailable');
      expect(xmlEl.getChildText('status'), 'Going offline');
    });

    test('toString returns XML string', () {
      final presence = Presence(
        type: PresenceType.unavailable,
        status: 'Going offline',
      );

      final xmlStr = presence.toString();
      expect(xmlStr, contains('<presence'));
      expect(xmlStr, contains('type="unavailable"'));
      expect(xmlStr, contains('<status>Going offline</status>'));
    });

    test('priority parses as integer', () {
      final element = xml('presence', {}, [
        xml('priority', {}, ['10']),
      ]);

      final presence = Presence.fromXml(element);
      expect(presence.priority, 10);
    });

    test('invalid priority returns null', () {
      final element = xml('presence', {}, [
        xml('priority', {}, ['invalid']),
      ]);

      final presence = Presence.fromXml(element);
      expect(presence.priority, isNull);
    });
  });

  group('PresenceParsing extension', () {
    test('isPresence returns correct value', () {
      final presEl = xml('presence', {}, []);
      final msgEl = xml('message', {}, []);

      expect(presEl.isPresence, true);
      expect(msgEl.isPresence, false);
    });

    test('toPresence converts element', () {
      final presEl = xml('presence', {'type': 'unavailable'}, [
        xml('status', {}, ['Going offline']),
      ]);

      final presence = presEl.toPresence();
      expect(presence, isNotNull);
      expect(presence!.presenceType, PresenceType.unavailable);
      expect(presence.status, 'Going offline');
    });

    test('toPresence returns null for non-presence', () {
      final msgEl = xml('message', {}, []);
      expect(msgEl.toPresence(), isNull);
    });
  });
}
