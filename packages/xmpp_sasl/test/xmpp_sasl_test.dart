import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_sasl/xmpp_sasl.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Mock SASL mechanism for testing.
class MockMechanism implements SASLMechanism {
  @override
  final String name = 'MOCK';

  @override
  final bool clientFirst = true;

  String? lastCredentials;
  String? lastChallenge;

  @override
  Future<String> response(Credentials credentials) async {
    lastCredentials = credentials.username;
    return 'mock-response';
  }

  @override
  Future<void> challenge(String challenge) async {
    lastChallenge = challenge;
  }
}

void main() {
  group('SASLFactory', () {
    test('registers and creates mechanism', () {
      final factory = SASLFactory();
      factory.use('MOCK', MockMechanism.new);

      final mech = factory.create(['MOCK']);
      expect(mech, isNotNull);
      expect(mech?.name, equals('MOCK'));
    });

    test('returns null for unknown mechanism', () {
      final factory = SASLFactory();

      final mech = factory.create(['UNKNOWN']);
      expect(mech, isNull);
    });

    test('lists mechanism names', () {
      final factory = SASLFactory();
      factory.use('MOCK', MockMechanism.new);
      factory.use('PLAIN', MockMechanism.new);

      expect(factory.mechanismNames, equals(['MOCK', 'PLAIN']));
    });
  });

  group('Credentials', () {
    test('creates with named parameters', () {
      final creds = Credentials(
        username: 'alice',
        password: 'secret',
        server: 'example.com',
      );

      expect(creds.username, equals('alice'));
      expect(creds.password, equals('secret'));
      expect(creds.server, equals('example.com'));
    });

    test('creates from map', () {
      final creds = Credentials.fromMap({
        'username': 'bob',
        'password': '12345',
      });

      expect(creds.username, equals('bob'));
      expect(creds.password, equals('12345'));
    });

    test('copyWith creates new instance', () {
      final creds = Credentials(username: 'alice');
      final newCreds = creds.copyWith(password: 'secret');

      expect(creds.password, isNull);
      expect(newCreds.username, equals('alice'));
      expect(newCreds.password, equals('secret'));
    });
  });

  group('SASLError', () {
    test('creates from element', () {
      final element = xml('failure', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-sasl'}, [
        xml('not-authorized', {}, []),
        xml('text', {}, ['Invalid credentials']),
      ]);

      final error = SASLError.fromElement(element);

      expect(error.condition, equals('not-authorized'));
      expect(error.text, equals('Invalid credentials'));
    });

    test('handles missing text', () {
      final element = xml('failure', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-sasl'}, [
        xml('credentials-expired', {}, []),
      ]);

      final error = SASLError.fromElement(element);

      expect(error.condition, equals('credentials-expired'));
      expect(error.text, isNull);
    });
  });

  group('getAvailableMechanisms', () {
    test('returns intersection of offered and supported', () {
      final factory = SASLFactory();
      factory.use('PLAIN', MockMechanism.new);
      factory.use('MOCK', MockMechanism.new);

      final element = xml('mechanisms', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-sasl'}, [
        xml('mechanism', {}, ['SCRAM-SHA-1']),
        xml('mechanism', {}, ['PLAIN']),
        xml('mechanism', {}, ['ANONYMOUS']),
      ]);

      final available = getAvailableMechanisms(element, nsSASL, factory);
      expect(available, equals(['PLAIN']));
    });

    test('returns empty list when no match', () {
      final factory = SASLFactory();
      factory.use('MOCK', MockMechanism.new);

      final element = xml('mechanisms', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-sasl'}, [
        xml('mechanism', {}, ['SCRAM-SHA-1']),
        xml('mechanism', {}, ['PLAIN']),
      ]);

      final available = getAvailableMechanisms(element, nsSASL, factory);
      expect(available, isEmpty);
    });
  });

  group('sasl setup', () {
    test('registers stream feature handler', () async {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      final factory = SASLFactory();
      factory.use('MOCK', MockMechanism.new);

      var callbackCalled = false;
      List<String>? availableMechs;

      sasl(sf, factory, (done, mechanisms, context, e) async {
        callbackCalled = true;
        availableMechs = mechanisms;
      });

      // Simulate receiving stream features with mechanisms
      final features = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('mechanisms', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-sasl'}, [
          xml('mechanism', {}, ['MOCK']),
        ]),
      ]);

      entity.emit('element', features);
      await Future<void>.delayed(Duration.zero);

      expect(callbackCalled, isTrue);
      expect(availableMechs, equals(['MOCK']));
    });
  });
}
