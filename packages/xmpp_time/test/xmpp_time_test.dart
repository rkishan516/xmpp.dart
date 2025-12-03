import 'package:test/test.dart';
import 'package:xmpp_time/xmpp_time.dart';

void main() {
  group('date', () {
    test('formats date correctly', () {
      final d = DateTime.utc(2024, 1, 15, 10, 30, 45);
      expect(date(d), equals('2024-01-15'));
    });

    test('pads single digit months and days', () {
      final d = DateTime.utc(2024, 3, 5);
      expect(date(d), equals('2024-03-05'));
    });

    test('returns current date when no argument', () {
      final result = date();
      expect(result, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });
  });

  group('time', () {
    test('formats time correctly', () {
      final d = DateTime.utc(2024, 1, 15, 10, 30, 45);
      expect(time(d), equals('10:30:45Z'));
    });

    test('pads single digit hours, minutes, seconds', () {
      final d = DateTime.utc(2024, 1, 1, 5, 3, 7);
      expect(time(d), equals('05:03:07Z'));
    });

    test('returns current time when no argument', () {
      final result = time();
      expect(result, matches(RegExp(r'^\d{2}:\d{2}:\d{2}Z$')));
    });
  });

  group('datetime', () {
    test('formats datetime correctly', () {
      final d = DateTime.utc(2024, 1, 15, 10, 30, 45);
      expect(datetime(d), equals('2024-01-15T10:30:45Z'));
    });

    test('returns current datetime when no argument', () {
      final result = datetime();
      expect(result, matches(RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$')));
    });
  });

  group('offset', () {
    test('formats positive offset correctly', () {
      // Create a datetime and check the offset format
      final result = offset();
      expect(result, matches(RegExp(r'^[+-]\d{2}:\d{2}$')));
    });
  });

  group('parse', () {
    test('parses ISO date', () {
      final result = parse('2024-01-15');
      expect(result.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
    });

    test('parses ISO datetime with Z', () {
      final result = parse('2024-01-15T10:30:45Z');
      expect(result.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
      expect(result.hour, equals(10));
      expect(result.minute, equals(30));
      expect(result.second, equals(45));
      expect(result.isUtc, isTrue);
    });

    test('parses ISO datetime with offset', () {
      final result = parse('2024-01-15T10:30:45+05:00');
      expect(result.year, equals(2024));
      expect(result.month, equals(1));
      expect(result.day, equals(15));
    });
  });
}
