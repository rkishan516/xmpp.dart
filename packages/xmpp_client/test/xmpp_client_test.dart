import 'package:test/test.dart';
import 'package:xmpp_client/xmpp_client.dart';

void main() {
  group('ClientOptions', () {
    test('creates with required fields', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      expect(options.service, equals('wss://example.com/xmpp-websocket'));
    });

    test('creates with all fields', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
        domain: 'example.com',
        lang: 'en',
        username: 'user',
        password: 'pass',
        resource: 'mobile',
      );

      expect(options.domain, equals('example.com'));
      expect(options.username, equals('user'));
      expect(options.password, equals('pass'));
      expect(options.resource, equals('mobile'));
    });
  });

  group('getDomain', () {
    test('extracts domain from wss URL', () {
      expect(getDomain('wss://example.com/xmpp-websocket'), equals('example.com'));
    });

    test('extracts domain from ws URL', () {
      expect(getDomain('ws://chat.example.org:5280/xmpp'), equals('chat.example.org'));
    });

    test('extracts domain from xmpp URL', () {
      expect(getDomain('xmpp://jabber.org'), equals('jabber.org'));
    });

    test('returns null for invalid URL', () {
      expect(getDomain('invalid'), isNull);
    });
  });

  group('Client', () {
    test('creates with options', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
        username: 'user',
        password: 'pass',
      );

      final c = Client(options);

      expect(c, isNotNull);
      expect(c.options, equals(options));
    });

    test('has middleware', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      final c = Client(options);

      expect(c.middleware, isNotNull);
    });

    test('has stream features', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      final c = Client(options);

      expect(c.streamFeatures, isNotNull);
    });

    test('has IQ caller', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      final c = Client(options);

      expect(c.iqCaller, isNotNull);
    });

    test('has IQ callee', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      final c = Client(options);

      expect(c.iqCallee, isNotNull);
    });

    test('has SASL factory with mechanisms', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      final c = Client(options);

      expect(c.saslFactory.mechanismNames, contains('PLAIN'));
      expect(c.saslFactory.mechanismNames, contains('ANONYMOUS'));
    });

    test('has stream management', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      final c = Client(options);

      expect(c.streamManagement, isNotNull);
    });

    test('has reconnect', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      final c = Client(options);

      expect(c.reconnect, isNotNull);
    });
  });

  group('client function', () {
    test('creates Client instance', () {
      final options = ClientOptions(
        service: 'wss://example.com/xmpp-websocket',
      );

      final c = client(options);

      expect(c, isA<Client>());
    });
  });
}
