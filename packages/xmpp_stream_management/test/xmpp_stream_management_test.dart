import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_stream_management/xmpp_stream_management.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Mock entity for testing.
class MockEntity extends EventEmitter {
  final List<XmlElement> sentStanzas = [];
  Map<String, dynamic> options = {};

  Future<void> send(XmlElement stanza) async {
    sentStanzas.add(stanza);
    emit('send', stanza);
  }
}

void main() {
  group('makeEnableElement', () {
    test('creates enable element', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);

      final element = makeEnableElement(sm);

      expect(element.name, equals('enable'));
      expect(element.attrs['xmlns'], equals(nsSM));
      expect(element.attrs['resume'], equals('true'));
    });

    test('includes max when set', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity)
        ..preferredMaximum = 300;

      final element = makeEnableElement(sm);

      expect(element.attrs['max'], equals('300'));
    });
  });

  group('makeResumeElement', () {
    test('creates resume element', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity)
        ..id = 'some-id'
        ..inbound = 5;

      final element = makeResumeElement(sm);

      expect(element.name, equals('resume'));
      expect(element.attrs['xmlns'], equals(nsSM));
      expect(element.attrs['previd'], equals('some-id'));
      expect(element.attrs['h'], equals('5'));
    });
  });

  group('StreamManagement', () {
    test('tracks inbound stanzas', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);
      sm.enabled = true;

      sm.handleIncoming(xml('message', {}, []));
      expect(sm.inbound, equals(1));

      sm.handleIncoming(xml('iq', {}, []));
      expect(sm.inbound, equals(2));

      sm.handleIncoming(xml('presence', {}, []));
      expect(sm.inbound, equals(3));
    });

    test('does not count non-stanzas', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);
      sm.enabled = true;

      sm.handleIncoming(xml('r', {'xmlns': nsSM}, []));
      expect(sm.inbound, equals(0));
    });

    test('ackQueue acknowledges stanzas', () async {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);

      final stanza1 = xml('message', {}, []);
      final stanza2 = xml('message', {}, []);
      sm.outboundQueue.add(QueueItem(stanza1, '2024-01-01'));
      sm.outboundQueue.add(QueueItem(stanza2, '2024-01-01'));

      final acked = <XmlElement>[];
      sm.on<XmlElement>('ack', acked.add);

      sm.ackQueue(1);
      await Future<void>.delayed(Duration.zero);

      expect(sm.outbound, equals(1));
      expect(sm.outboundQueue.length, equals(1));
      expect(acked.length, equals(1));
      expect(acked.first.name, equals('message'));
    });

    test('failQueue fails all stanzas', () async {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);

      final stanza1 = xml('message', {}, []);
      final stanza2 = xml('message', {}, []);
      sm.outboundQueue.add(QueueItem(stanza1, '2024-01-01'));
      sm.outboundQueue.add(QueueItem(stanza2, '2024-01-01'));

      final failed = <XmlElement>[];
      sm.on<XmlElement>('fail', failed.add);

      sm.failQueue();
      await Future<void>.delayed(Duration.zero);

      expect(sm.outbound, equals(0));
      expect(sm.outboundQueue, isEmpty);
      expect(failed.length, equals(2));
    });

    test('responds to r with a', () async {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);
      sm.enabled = true;
      sm.inbound = 5;

      sm.handleIncoming(xml('r', {'xmlns': nsSM}, []));
      await Future<void>.delayed(Duration.zero);

      expect(entity.sentStanzas.length, equals(1));
      expect(entity.sentStanzas.first.name, equals('a'));
      expect(entity.sentStanzas.first.attrs['h'], equals('5'));
    });

    test('shouldQueue returns true for stanzas when enabled', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);
      sm.enabled = true;

      expect(sm.shouldQueue(xml('message', {}, [])), isTrue);
      expect(sm.shouldQueue(xml('iq', {}, [])), isTrue);
      expect(sm.shouldQueue(xml('presence', {}, [])), isTrue);
      expect(sm.shouldQueue(xml('r', {'xmlns': nsSM}, [])), isFalse);
    });

    test('shouldQueue returns false when disabled', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);

      expect(sm.shouldQueue(xml('message', {}, [])), isFalse);
    });

    test('onEnabled sets state correctly', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);

      sm.onEnabled('session-id', 300);

      expect(sm.enabled, isTrue);
      expect(sm.id, equals('session-id'));
      expect(sm.max, equals(300));
      expect(sm.inbound, equals(0));
    });

    test('offline resets state', () {
      final entity = MockEntity();
      final sm = StreamManagement(entity: entity);
      sm.enabled = true;
      sm.id = 'session-id';
      sm.inbound = 5;

      sm.offline();

      expect(sm.enabled, isFalse);
      expect(sm.enableSent, isFalse);
      expect(sm.id, isEmpty);
      expect(sm.inbound, equals(0));
    });
  });

  group('streamManagement', () {
    test('creates StreamManagement instance', () {
      final entity = MockEntity();
      final mw = middleware(entity: entity);

      final sm = streamManagement(entity: entity, middleware: mw);

      expect(sm, isNotNull);
      expect(sm.enabled, isFalse);
    });

    test('handles disconnect event', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final sm = streamManagement(entity: entity, middleware: mw);

      sm.enabled = true;
      entity.emit('disconnect', null);
      await Future<void>.delayed(Duration.zero);

      expect(sm.enabled, isFalse);
    });
  });
}
