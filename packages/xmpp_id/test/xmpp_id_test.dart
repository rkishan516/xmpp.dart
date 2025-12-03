import 'package:test/test.dart';
import 'package:xmpp_id/xmpp_id.dart';

void main() {
  group('id', () {
    test('returns a non-empty string', () {
      final result = id();
      expect(result, isNotEmpty);
    });

    test('returns string of expected length', () {
      final result = id();
      expect(result.length, equals(10));
    });

    test('returns alphanumeric characters only', () {
      final result = id();
      expect(result, matches(RegExp(r'^[a-z0-9]+$')));
    });

    test('generates unique IDs', () {
      final ids = List.generate(1000, (_) => id());
      final uniqueIds = ids.toSet();
      expect(uniqueIds.length, equals(1000));
    });
  });

  group('generateId', () {
    test('is an alias for id', () {
      final result = generateId();
      expect(result, isNotEmpty);
      expect(result.length, equals(10));
      expect(result, matches(RegExp(r'^[a-z0-9]+$')));
    });
  });
}
