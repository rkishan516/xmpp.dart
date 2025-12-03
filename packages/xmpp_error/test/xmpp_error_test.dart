import 'package:test/test.dart';
import 'package:xmpp_error/xmpp_error.dart';

void main() {
  group('XMPPError', () {
    test('creates error with condition only', () {
      final error = XMPPError('bad-request');
      expect(error.condition, equals('bad-request'));
      expect(error.text, isNull);
      expect(error.application, isNull);
    });

    test('creates error with condition and text', () {
      final error = XMPPError('bad-request', 'Invalid format');
      expect(error.condition, equals('bad-request'));
      expect(error.text, equals('Invalid format'));
    });

    test('toString includes condition', () {
      final error = XMPPError('bad-request');
      expect(error.toString(), contains('bad-request'));
    });

    test('toString includes text when present', () {
      final error = XMPPError('bad-request', 'Invalid format');
      expect(error.toString(), contains('Invalid format'));
    });
  });

  // StreamError is in xmpp_connection package
  // StanzaError is in xmpp_middleware package

  group('SASLError', () {
    test('creates SASL error', () {
      final error = SASLError('not-authorized');
      expect(error.condition, equals('not-authorized'));
    });

    test('conditions list is valid', () {
      expect(SASLError.conditions, contains('not-authorized'));
      expect(SASLError.conditions, contains('credentials-expired'));
    });
  });

  group('TimeoutError', () {
    test('creates timeout error', () {
      final error = TimeoutError(const Duration(seconds: 30));
      expect(error.condition, equals('timeout'));
      expect(error.timeout, equals(const Duration(seconds: 30)));
    });

    test('creates timeout error with custom message', () {
      final error = TimeoutError(const Duration(seconds: 5), 'Custom timeout message');
      expect(error.text, equals('Custom timeout message'));
    });

    test('toString includes timeout duration', () {
      final error = TimeoutError(const Duration(milliseconds: 5000));
      expect(error.toString(), contains('5000'));
    });
  });
}
