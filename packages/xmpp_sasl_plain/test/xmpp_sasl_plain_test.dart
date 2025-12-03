import 'package:test/test.dart';
import 'package:xmpp_sasl/xmpp_sasl.dart';
import 'package:xmpp_sasl_plain/xmpp_sasl_plain.dart';

void main() {
  group('PlainMechanism', () {
    test('name is PLAIN', () {
      final mech = PlainMechanism();
      expect(mech.name, equals('PLAIN'));
    });

    test('is client-first', () {
      final mech = PlainMechanism();
      expect(mech.clientFirst, isTrue);
    });

    test('generates correct response', () async {
      final mech = PlainMechanism();
      final creds = Credentials(username: 'alice', password: 'secret');

      final response = await mech.response(creds);

      // Expected: NUL + "alice" + NUL + "secret"
      expect(response, equals('\x00alice\x00secret'));
    });

    test('handles empty credentials', () async {
      final mech = PlainMechanism();
      final creds = Credentials();

      final response = await mech.response(creds);

      expect(response, equals('\x00\x00'));
    });
  });

  group('saslPlain', () {
    test('registers PLAIN mechanism', () {
      final factory = SASLFactory();
      saslPlain(factory);

      expect(factory.mechanismNames, contains('PLAIN'));
    });

    test('creates PlainMechanism', () {
      final factory = SASLFactory();
      saslPlain(factory);

      final mech = factory.create(['PLAIN']);
      expect(mech, isA<PlainMechanism>());
    });
  });
}
