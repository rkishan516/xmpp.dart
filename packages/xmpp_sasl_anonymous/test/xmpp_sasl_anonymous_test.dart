import 'package:test/test.dart';
import 'package:xmpp_sasl/xmpp_sasl.dart';
import 'package:xmpp_sasl_anonymous/xmpp_sasl_anonymous.dart';

void main() {
  group('AnonymousMechanism', () {
    test('name is ANONYMOUS', () {
      final mech = AnonymousMechanism();
      expect(mech.name, equals('ANONYMOUS'));
    });

    test('is client-first', () {
      final mech = AnonymousMechanism();
      expect(mech.clientFirst, isTrue);
    });

    test('generates empty response', () async {
      final mech = AnonymousMechanism();
      final creds = Credentials();

      final response = await mech.response(creds);

      expect(response, equals(''));
    });
  });

  group('saslAnonymous', () {
    test('registers ANONYMOUS mechanism', () {
      final factory = SASLFactory();
      saslAnonymous(factory);

      expect(factory.mechanismNames, contains('ANONYMOUS'));
    });

    test('creates AnonymousMechanism', () {
      final factory = SASLFactory();
      saslAnonymous(factory);

      final mech = factory.create(['ANONYMOUS']);
      expect(mech, isA<AnonymousMechanism>());
    });
  });
}
