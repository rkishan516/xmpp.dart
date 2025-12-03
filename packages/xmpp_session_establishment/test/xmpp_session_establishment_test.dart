import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_iq/xmpp_iq.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_session_establishment/xmpp_session_establishment.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
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
  group('sessionEstablishment', () {
    test('sends session IQ when feature is required', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      final iqCall = iqCaller(entity: entity, middleware: mw);

      sessionEstablishment(sf, iqCall);

      // Simulate stream features with session (required)
      final features = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('session', {'xmlns': nsSession}, []),
      ]);

      entity.emit('element', features);
      await Future<void>.delayed(Duration.zero);

      // Check session IQ was sent
      expect(entity.sentStanzas, isNotEmpty);
      final sentIq = entity.sentStanzas.first;
      expect(sentIq.getChild('session', nsSession), isNotNull);
    });

    test('skips session IQ when feature is optional', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      final iqCall = iqCaller(entity: entity, middleware: mw);

      sessionEstablishment(sf, iqCall);

      // Simulate stream features with optional session
      final features = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('session', {'xmlns': nsSession}, [
          xml('optional', {}, []),
        ]),
      ]);

      entity.emit('element', features);
      await Future<void>.delayed(Duration.zero);

      // No IQ should be sent
      expect(entity.sentStanzas, isEmpty);
    });
  });
}
