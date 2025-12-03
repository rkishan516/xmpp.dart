import 'package:test/test.dart';
import 'package:xmpp_debug/xmpp_debug.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('isSensitive', () {
    test('returns false for empty elements', () {
      final element = xml('message', {}, []);
      expect(isSensitive(element), isFalse);
    });

    test('returns true for SASL auth element', () {
      final element = xml('auth', {'xmlns': nsSASL}, [xml('plain', {}, [])]);
      expect(isSensitive(element), isTrue);
    });

    test('returns true for SASL challenge element', () {
      final element =
          xml('challenge', {'xmlns': nsSASL}, [xml('data', {}, [])]);
      expect(isSensitive(element), isTrue);
    });

    test('returns true for SASL response element', () {
      final element =
          xml('response', {'xmlns': nsSASL}, [xml('data', {}, [])]);
      expect(isSensitive(element), isTrue);
    });

    test('returns true for SASL success element', () {
      final element = xml('success', {'xmlns': nsSASL}, [xml('data', {}, [])]);
      expect(isSensitive(element), isTrue);
    });

    test('returns true for component handshake element', () {
      final element =
          xml('handshake', {'xmlns': nsComponent}, [xml('data', {}, [])]);
      expect(isSensitive(element), isTrue);
    });

    test('returns true for SASL2 challenge element', () {
      final element =
          xml('challenge', {'xmlns': nsSASL2}, [xml('data', {}, [])]);
      expect(isSensitive(element), isTrue);
    });

    test('returns true for SASL2 response element', () {
      final element =
          xml('response', {'xmlns': nsSASL2}, [xml('data', {}, [])]);
      expect(isSensitive(element), isTrue);
    });

    test('returns false for normal message element', () {
      final element = xml('message', {'type': 'chat'}, [
        xml('body', {}, ['Hello']),
      ]);
      expect(isSensitive(element), isFalse);
    });
  });

  group('hideSensitive', () {
    test('hides content of sensitive elements', () {
      final element = xml('auth', {'xmlns': nsSASL}, [
        xml('mechanism', {}, ['PLAIN']),
      ]);
      final hidden = hideSensitive(element);

      expect(hidden.children.length, equals(1));
      expect(hidden.children.first.name, equals('hidden'));
      expect(hidden.children.first.attrs['xmlns'], equals('xmpp.dart'));
    });

    test('does not modify non-sensitive elements', () {
      final element = xml('message', {'type': 'chat'}, [
        xml('body', {}, ['Hello']),
      ]);
      final result = hideSensitive(element);

      expect(result.children.length, equals(1));
      expect(result.children.first.name, equals('body'));
    });

    test('hides initial-response in SASL2 authenticate', () {
      final element = xml('authenticate', {'xmlns': nsSASL2}, [
        xml('initial-response', {}, ['secret']),
        xml('mechanism', {}, ['SCRAM-SHA-1']),
      ]);
      final hidden = hideSensitive(element);

      final initialResponse = hidden.getChild('initial-response');
      expect(initialResponse?.children.first.name, equals('hidden'));
    });

    test('hides additional-data in SASL2 namespace', () {
      final element = xml('success', {'xmlns': nsSASL2}, [
        xml('additional-data', {}, ['secret']),
        xml('authorization-identifier', {}, ['user@example.com']),
      ]);
      final hidden = hideSensitive(element);

      final additionalData = hidden.getChild('additional-data');
      expect(additionalData?.children.first.name, equals('hidden'));
    });

    test('hides FAST token attribute', () {
      final element = xml('success', {'xmlns': nsSASL2}, [
        xml('token', {'xmlns': nsFAST, 'token': 'secret-token'}, []),
      ]);
      final hidden = hideSensitive(element);

      final token = hidden.getChild('token', nsFAST);
      expect(token?.attrs['token'], equals('hidden by xmpp.dart'));
    });

    test('returns a clone, not the original', () {
      final element = xml('auth', {'xmlns': nsSASL}, [
        xml('mechanism', {}, ['PLAIN']),
      ]);
      final hidden = hideSensitive(element);

      // Original should be unchanged
      expect(element.children.first.name, equals('mechanism'));
      // Hidden should be modified
      expect(hidden.children.first.name, equals('hidden'));
    });
  });

  group('formatElement', () {
    test('returns string representation with hidden sensitive data', () {
      final element = xml('auth', {'xmlns': nsSASL}, [
        xml('mechanism', {}, ['PLAIN']),
      ]);
      final formatted = formatElement(element);

      expect(formatted, contains('auth'));
      expect(formatted, contains('hidden'));
      expect(formatted, isNot(contains('PLAIN')));
    });

    test('returns string representation for non-sensitive elements', () {
      final element = xml('message', {'type': 'chat'}, [
        xml('body', {}, ['Hello']),
      ]);
      final formatted = formatElement(element);

      expect(formatted, contains('message'));
      expect(formatted, contains('Hello'));
    });
  });
}
