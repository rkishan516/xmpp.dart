import 'package:test/test.dart';
import 'package:xmpp_jid/xmpp_jid.dart';

void main() {
  group('JID', () {
    test('creates JID with all parts', () {
      final j = JID('user', 'example.com', 'resource');
      expect(j.local, equals('user'));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals('resource'));
    });

    test('creates JID without local', () {
      final j = JID(null, 'example.com', 'resource');
      expect(j.local, equals(''));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals('resource'));
    });

    test('creates JID without resource', () {
      final j = JID('user', 'example.com');
      expect(j.local, equals('user'));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals(''));
    });

    test('throws on empty domain', () {
      expect(() => JID('user', ''), throwsArgumentError);
    });

    test('lowercases local and domain', () {
      final j = JID('USER', 'EXAMPLE.COM', 'Resource');
      expect(j.local, equals('user'));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals('Resource')); // Resource is case-sensitive
    });
  });

  group('parse', () {
    test('parses full JID', () {
      final j = parse('user@example.com/resource');
      expect(j.local, equals('user'));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals('resource'));
    });

    test('parses JID without resource', () {
      final j = parse('user@example.com');
      expect(j.local, equals('user'));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals(''));
    });

    test('parses JID without local', () {
      final j = parse('example.com/resource');
      expect(j.local, equals(''));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals('resource'));
    });

    test('parses domain only', () {
      final j = parse('example.com');
      expect(j.local, equals(''));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals(''));
    });

    test('handles resource with slash', () {
      final j = parse('user@example.com/res/with/slashes');
      expect(j.resource, equals('res/with/slashes'));
    });
  });

  group('JID.parse', () {
    test('parses JID string', () {
      final j = JID.parse('user@example.com/resource');
      expect(j.local, equals('user'));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals('resource'));
    });
  });

  group('toString', () {
    test('converts to string with all parts', () {
      final j = JID('user', 'example.com', 'resource');
      expect(j.toString(), equals('user@example.com/resource'));
    });

    test('converts to string without resource', () {
      final j = JID('user', 'example.com');
      expect(j.toString(), equals('user@example.com'));
    });

    test('converts to string without local', () {
      final j = JID(null, 'example.com', 'resource');
      expect(j.toString(), equals('example.com/resource'));
    });
  });

  group('bare', () {
    test('returns JID without resource', () {
      final j = JID('user', 'example.com', 'resource');
      final bare = j.bare();
      expect(bare.toString(), equals('user@example.com'));
    });

    test('returns same JID if no resource', () {
      final j = JID('user', 'example.com');
      final bare = j.bare();
      expect(identical(j, bare), isTrue);
    });
  });

  group('equals', () {
    test('returns true for equal JIDs', () {
      final j1 = JID('user', 'example.com', 'resource');
      final j2 = JID('user', 'example.com', 'resource');
      expect(j1.equals(j2), isTrue);
      expect(j1 == j2, isTrue);
    });

    test('returns false for different JIDs', () {
      final j1 = JID('user1', 'example.com');
      final j2 = JID('user2', 'example.com');
      expect(j1.equals(j2), isFalse);
      expect(j1 == j2, isFalse);
    });

    test('is case-insensitive for local and domain', () {
      final j1 = JID('USER', 'EXAMPLE.COM');
      final j2 = JID('user', 'example.com');
      expect(j1.equals(j2), isTrue);
    });
  });

  group('escaping', () {
    test('detectEscape returns true for unescaped characters', () {
      expect(detectEscape('user@domain'), isTrue);
      expect(detectEscape('user:pass'), isTrue);
      expect(detectEscape('user with space'), isTrue);
    });

    test('detectEscape returns false for safe characters', () {
      expect(detectEscape('user'), isFalse);
      expect(detectEscape('user123'), isFalse);
      expect(detectEscape(null), isFalse);
      expect(detectEscape(''), isFalse);
    });

    test('escapeLocal escapes special characters', () {
      expect(escapeLocal('user@domain'), equals(r'user\40domain'));
      expect(escapeLocal('user:pass'), equals(r'user\3apass'));
      expect(escapeLocal('a space'), equals(r'a\20space'));
    });

    test('unescapeLocal unescapes special characters', () {
      expect(unescapeLocal(r'user\40domain'), equals('user@domain'));
      expect(unescapeLocal(r'user\3apass'), equals('user:pass'));
      expect(unescapeLocal(r'a\20space'), equals('a space'));
    });

    test('escape/unescape roundtrip', () {
      const original = 'user@domain:pass';
      final escaped = escapeLocal(original);
      final unescaped = unescapeLocal(escaped!);
      expect(unescaped, equals(original));
    });

    test('JID auto-escapes when needed', () {
      final j = JID('user@domain', 'example.com');
      expect(j.local, equals(r'user\40domain'));
      expect(j.getLocal(true), equals('user@domain'));
    });

    test('toString with unescape', () {
      final j = JID('user@domain', 'example.com');
      expect(j.toString(true), equals('user@domain@example.com'));
    });
  });

  group('jid helper', () {
    test('parses string', () {
      final j = jid('user@example.com');
      expect(j.local, equals('user'));
      expect(j.domain, equals('example.com'));
    });

    test('creates from parts', () {
      final j = jid('user', 'example.com', 'resource');
      expect(j.local, equals('user'));
      expect(j.domain, equals('example.com'));
      expect(j.resource, equals('resource'));
    });

    test('returns JID if passed JID', () {
      final original = JID('user', 'example.com');
      final result = jid(original);
      expect(identical(original, result), isTrue);
    });
  });

  group('equal helper', () {
    test('returns true for equal JIDs', () {
      final j1 = JID('user', 'example.com');
      final j2 = JID('user', 'example.com');
      expect(equal(j1, j2), isTrue);
    });
  });
}
