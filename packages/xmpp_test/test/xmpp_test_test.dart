import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_test/xmpp_test.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('MockSocket', () {
    test('captures sent data', () {
      final socket = MockSocket();

      socket.write('data1');
      socket.write('data2');

      expect(socket.sentData, equals(['data1', 'data2']));
    });

    test('emits data events', () async {
      final socket = MockSocket();
      String? receivedData;

      socket.on<String>('data', (data) {
        receivedData = data;
      });

      socket.fakeData('incoming data');
      await Future<void>.delayed(Duration.zero);

      expect(receivedData, equals('incoming data'));
    });

    test('emits connect events', () async {
      final socket = MockSocket();
      var connected = false;

      socket.on<dynamic>('connect', (_) {
        connected = true;
      });

      socket.fakeConnect();
      await Future<void>.delayed(Duration.zero);

      expect(connected, isTrue);
    });

    test('emits close events', () async {
      final socket = MockSocket();
      var closed = false;

      socket.on<dynamic>('close', (_) {
        closed = true;
      });

      socket.fakeClose();
      await Future<void>.delayed(Duration.zero);

      expect(closed, isTrue);
      expect(socket.isClosed, isTrue);
    });

    test('clears sent data', () {
      final socket = MockSocket();
      socket.write('data');
      socket.clearSentData();

      expect(socket.sentData, isEmpty);
    });
  });

  group('MockContext', () {
    test('sanitizes stanza', () {
      final entity = EventEmitter();
      final ctx = MockContext(entity);

      final stanza = xml('message', {
        'id': 'test-id',
        'xmlns': 'jabber:client',
        'to': 'user@example.com',
      }, []);

      final result = ctx.sanitize(stanza);

      expect(result.id, equals('test-id'));
      expect(result.stanza.attrs.containsKey('id'), isFalse);
      expect(result.stanza.attrs.containsKey('xmlns'), isFalse);
      expect(result.stanza.attrs['to'], equals('user@example.com'));
    });

    test('catches outgoing stanzas', () async {
      final entity = EventEmitter();
      final ctx = MockContext(entity);

      final stanzaFuture = ctx.catchOutgoing();

      entity.emit('send', xml('message', {'to': 'user@example.com'}, []));

      final stanza = await stanzaFuture;
      expect(stanza.name, equals('message'));
    });

    test('catches outgoing IQ', () async {
      final entity = EventEmitter();
      final ctx = MockContext(entity);

      final stanzaFuture = ctx.catchOutgoingIq();

      entity.emit('send', xml('iq', {'type': 'get'}, []));

      final stanza = await stanzaFuture;
      expect(stanza.name, equals('iq'));
    });

    test('mocks input', () async {
      final entity = EventEmitter();
      final ctx = MockContext(entity);
      XmlElement? received;

      entity.on<XmlElement>('element', (el) {
        received = el;
      });

      ctx.mockInput(xml('message', {'from': 'sender@example.com'}, []));
      await Future<void>.delayed(Duration.zero);

      expect(received, isNotNull);
      expect(received!.name, equals('message'));
    });
  });

  group('mockJid', () {
    test('creates default JID', () {
      final jid = mockJid();

      expect(jid.toString(), equals('test@example.com/resource'));
    });

    test('creates custom JID', () {
      final jid = mockJid('user@domain.com/mobile');

      expect(jid.local, equals('user'));
      expect(jid.domain, equals('domain.com'));
      expect(jid.resource, equals('mobile'));
    });
  });
}
