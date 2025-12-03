import 'package:test/test.dart';
import 'package:xmpp_base64/xmpp_base64.dart';

void main() {
  group('encode', () {
    test('encodes a simple string', () {
      expect(encode('Hello, World!'), equals('SGVsbG8sIFdvcmxkIQ=='));
    });

    test('encodes an empty string', () {
      expect(encode(''), equals(''));
    });

    test('encodes unicode characters', () {
      expect(encode('café'), equals('Y2Fmw6k='));
    });

    test('encodes special characters', () {
      expect(encode('\x00\x01\x02'), equals('AAEC'));
    });
  });

  group('decode', () {
    test('decodes a simple string', () {
      expect(decode('SGVsbG8sIFdvcmxkIQ=='), equals('Hello, World!'));
    });

    test('decodes an empty string', () {
      expect(decode(''), equals(''));
    });

    test('decodes unicode characters', () {
      expect(decode('Y2Fmw6k='), equals('café'));
    });
  });

  group('encodeBytes', () {
    test('encodes bytes', () {
      expect(encodeBytes([72, 101, 108, 108, 111]), equals('SGVsbG8='));
    });

    test('encodes empty list', () {
      expect(encodeBytes([]), equals(''));
    });
  });

  group('decodeBytes', () {
    test('decodes to bytes', () {
      expect(decodeBytes('SGVsbG8='), equals([72, 101, 108, 108, 111]));
    });

    test('decodes empty string', () {
      expect(decodeBytes(''), equals([]));
    });
  });

  group('roundtrip', () {
    test('encode/decode roundtrip preserves data', () {
      const original = 'Hello, XMPP World! 你好';
      expect(decode(encode(original)), equals(original));
    });

    test('encodeBytes/decodeBytes roundtrip preserves data', () {
      final original = [0, 1, 2, 255, 128, 64];
      expect(decodeBytes(encodeBytes(original)), equals(original));
    });
  });
}
