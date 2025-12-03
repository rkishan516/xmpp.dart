import 'package:test/test.dart';
import 'package:xmpp_component/xmpp_component.dart';

void main() {
  group('ComponentOptions', () {
    test('creates with required fields', () {
      final options = ComponentOptions(
        service: 'xmpp://component.example.com:5347',
        domain: 'component.example.com',
        password: 'secret',
      );

      expect(options.service, equals('xmpp://component.example.com:5347'));
      expect(options.domain, equals('component.example.com'));
      expect(options.password, equals('secret'));
    });
  });

  group('Component', () {
    test('creates with options', () {
      final options = ComponentOptions(
        service: 'xmpp://component.example.com:5347',
        domain: 'component.example.com',
        password: 'secret',
      );

      final c = Component(options);

      expect(c, isNotNull);
      expect(c.options, equals(options));
    });

    test('has middleware', () {
      final options = ComponentOptions(
        service: 'xmpp://component.example.com:5347',
        domain: 'component.example.com',
        password: 'secret',
      );

      final c = Component(options);

      expect(c.middleware, isNotNull);
    });

    test('has IQ caller', () {
      final options = ComponentOptions(
        service: 'xmpp://component.example.com:5347',
        domain: 'component.example.com',
        password: 'secret',
      );

      final c = Component(options);

      expect(c.iqCaller, isNotNull);
    });

    test('has IQ callee', () {
      final options = ComponentOptions(
        service: 'xmpp://component.example.com:5347',
        domain: 'component.example.com',
        password: 'secret',
      );

      final c = Component(options);

      expect(c.iqCallee, isNotNull);
    });

    test('has reconnect', () {
      final options = ComponentOptions(
        service: 'xmpp://component.example.com:5347',
        domain: 'component.example.com',
        password: 'secret',
      );

      final c = Component(options);

      expect(c.reconnect, isNotNull);
    });
  });

  group('component function', () {
    test('creates Component instance', () {
      final options = ComponentOptions(
        service: 'xmpp://component.example.com:5347',
        domain: 'component.example.com',
        password: 'secret',
      );

      final c = component(options);

      expect(c, isA<Component>());
    });
  });
}
