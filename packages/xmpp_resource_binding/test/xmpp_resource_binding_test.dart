import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_iq/xmpp_iq.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_resource_binding/xmpp_resource_binding.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Mock entity for testing.
class MockEntity extends EventEmitter {
  final List<XmlElement> sentStanzas = [];
  Map<String, dynamic> options = {};
  String? boundJid;
  bool isReady = false;

  Future<void> send(XmlElement stanza) async {
    sentStanzas.add(stanza);
    emit('send', stanza);
  }

  void setJid(String jid) {
    boundJid = jid;
  }

  void ready({bool resumed = false}) {
    isReady = true;
  }
}

void main() {
  group('makeBindElement', () {
    test('creates bind element without resource', () {
      final element = makeBindElement();

      expect(element.name, equals('bind'));
      expect(element.attrs['xmlns'], equals(nsBind));
      expect(element.getChild('resource'), isNull);
    });

    test('creates bind element with resource', () {
      final element = makeBindElement('myresource');

      expect(element.name, equals('bind'));
      expect(element.getChildText('resource'), equals('myresource'));
    });
  });

  group('bind', () {
    test('sends bind IQ and extracts JID', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final iqCall = iqCaller(entity: entity, middleware: mw);

      // Start bind
      final bindFuture = bind(entity, iqCall, 'test-resource');
      await Future<void>.delayed(Duration.zero);

      // Check bind IQ was sent
      expect(entity.sentStanzas, isNotEmpty);
      final sentIq = entity.sentStanzas.first;
      expect(sentIq.attrs['type'], equals('set'));

      // Simulate response
      final id = sentIq.attrs['id']!;
      entity.emit('element', xml('iq', {'type': 'result', 'id': id}, [
        xml('bind', {'xmlns': nsBind}, [
          xml('jid', {}, ['user@example.com/test-resource']),
        ]),
      ]));

      final jid = await bindFuture;
      expect(jid, equals('user@example.com/test-resource'));
      expect(entity.boundJid, equals('user@example.com/test-resource'));
      expect(entity.isReady, isTrue);
    });
  });

  group('resourceBinding', () {
    test('registers stream feature handler', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      final iqCall = iqCaller(entity: entity, middleware: mw);

      resourceBinding(sf, iqCall, 'myresource');

      // Simulate stream features with bind
      final features = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('bind', {'xmlns': nsBind}, []),
      ]);

      entity.emit('element', features);
      await Future<void>.delayed(Duration.zero);

      // Check bind IQ was sent
      expect(entity.sentStanzas, isNotEmpty);
      expect(entity.sentStanzas.first.getChild('bind', nsBind), isNotNull);
    });

    test('uses resource provider function', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      final iqCall = iqCaller(entity: entity, middleware: mw);

      resourceBinding(sf, iqCall, () async => 'dynamic-resource');

      final features = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('bind', {'xmlns': nsBind}, []),
      ]);

      entity.emit('element', features);
      await Future<void>.delayed(Duration.zero);

      // Check bind element has the resource
      final bindElement = entity.sentStanzas.first.getChild('bind', nsBind);
      expect(bindElement?.getChildText('resource'), equals('dynamic-resource'));
    });
  });
}
