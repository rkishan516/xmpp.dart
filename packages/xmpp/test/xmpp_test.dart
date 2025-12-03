import 'package:test/test.dart';
import 'package:xmpp/xmpp.dart';

void main() {
  group('xmpp package', () {
    test('exports xml function', () {
      final el = xml('message', {'to': 'user@example.com'}, []);
      expect(el.name, equals('message'));
    });

    test('exports JID class', () {
      final jid = JID.parse('user@example.com/resource');
      expect(jid.local, equals('user'));
      expect(jid.domain, equals('example.com'));
      expect(jid.resource, equals('resource'));
    });

    test('exports EventEmitter class', () {
      final emitter = EventEmitter();
      expect(emitter, isNotNull);
      emitter.dispose();
    });

    test('exports XMPPError class', () {
      final error = XMPPError('test-error', 'Test message');
      expect(error.condition, equals('test-error'));
    });

    test('exports id function', () {
      final generatedId = id();
      expect(generatedId, isNotEmpty);
    });

    test('exports datetime function', () {
      final dt = datetime(DateTime.utc(2023, 6, 15, 12, 30, 45));
      expect(dt, equals('2023-06-15T12:30:45Z'));
    });

    test('exports Client class', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );
      final c = Client(options);
      expect(c, isNotNull);
    });

    test('exports Component class', () {
      final options = ComponentOptions(
        service: 'xmpp://component.example.com:5347',
        domain: 'component.example.com',
        password: 'secret',
      );
      final c = Component(options);
      expect(c, isNotNull);
    });
  });
}
