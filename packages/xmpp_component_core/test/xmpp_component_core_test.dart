import 'package:test/test.dart';
import 'package:xmpp_component_core/xmpp_component_core.dart';

void main() {
  group('ComponentConnection', () {
    test('has correct namespace', () {
      final connection = ComponentConnection();
      expect(connection.ns, equals(nsComponent));
    });

    test('socketParameters extracts host and default port', () {
      final connection = ComponentConnection();
      final params = connection.socketParameters('xmpp://component.example.com');

      expect(params, isNotNull);
      expect(params!['host'], equals('component.example.com'));
      expect(params['port'], equals(5347));
    });

    test('socketParameters extracts host and custom port', () {
      final connection = ComponentConnection();
      final params = connection.socketParameters('xmpp://component.example.com:5348');

      expect(params, isNotNull);
      expect(params!['host'], equals('component.example.com'));
      expect(params['port'], equals(5348));
    });

    test('socketParameters returns null for non-xmpp URL', () {
      final connection = ComponentConnection();

      expect(connection.socketParameters('http://example.com'), isNull);
      expect(connection.socketParameters('wss://example.com'), isNull);
    });

    test('headerElement creates stream:stream element', () {
      final connection = ComponentConnection();
      final el = connection.headerElement();

      expect(el.name, equals('stream:stream'));
      expect(el.attrs['xmlns'], equals(nsComponent));
      expect(el.attrs['xmlns:stream'], equals(nsJabberStreamXmpp));
    });

    test('header produces XML declaration and opening tag', () {
      final connection = ComponentConnection();
      final el = connection.headerElement();
      el.attrs['to'] = 'example.com';
      final headerStr = connection.header(el);

      expect(headerStr, startsWith("<?xml version='1.0'?>"));
      expect(headerStr, contains('stream:stream'));
      expect(headerStr, isNot(contains('/>')));
    });

    test('footer produces closing stream tag', () {
      final connection = ComponentConnection();
      expect(connection.footer(connection.headerElement()), equals('</stream:stream>'));
    });

    test('canHandle returns true for xmpp URLs', () {
      expect(ComponentConnection.canHandle('xmpp://example.com'), isTrue);
      expect(ComponentConnection.canHandle('xmpp://example.com:5347'), isTrue);
    });

    test('canHandle returns false for non-xmpp URLs', () {
      expect(ComponentConnection.canHandle('http://example.com'), isFalse);
      expect(ComponentConnection.canHandle('wss://example.com'), isFalse);
    });
  });

  group('nsComponent', () {
    test('has correct value', () {
      expect(nsComponent, equals('jabber:component:accept'));
    });
  });
}
