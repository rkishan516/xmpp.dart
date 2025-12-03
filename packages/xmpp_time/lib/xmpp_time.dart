/// ISO 8601 date/time utilities for XMPP.
///
/// Provides functions for formatting dates and times according to
/// XEP-0082: XMPP Date and Time Profiles.
library;

/// Formats a [DateTime] as an ISO 8601 date string (YYYY-MM-DD).
///
/// If no [dateTime] is provided, uses the current UTC time.
///
/// Example:
/// ```dart
/// final d = date(DateTime.utc(2024, 1, 15, 10, 30, 45));
/// print(d); // "2024-01-15"
/// ```
String date([DateTime? dateTime]) {
  final d = (dateTime ?? DateTime.now()).toUtc();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// Formats a [DateTime] as an ISO 8601 time string (HH:MM:SSZ).
///
/// If no [dateTime] is provided, uses the current UTC time.
///
/// Example:
/// ```dart
/// final t = time(DateTime.utc(2024, 1, 15, 10, 30, 45));
/// print(t); // "10:30:45Z"
/// ```
String time([DateTime? dateTime]) {
  final d = (dateTime ?? DateTime.now()).toUtc();
  return '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}:'
      '${d.second.toString().padLeft(2, '0')}Z';
}

/// Formats a [DateTime] as an ISO 8601 datetime string (YYYY-MM-DDTHH:MM:SSZ).
///
/// If no [dateTime] is provided, uses the current UTC time.
///
/// Example:
/// ```dart
/// final dt = datetime(DateTime.utc(2024, 1, 15, 10, 30, 45));
/// print(dt); // "2024-01-15T10:30:45Z"
/// ```
String datetime([DateTime? dateTime]) {
  return '${date(dateTime)}T${time(dateTime)}';
}

/// Returns the timezone offset as a string (+HH:MM or -HH:MM).
///
/// If no [dateTime] is provided, uses the current local time.
///
/// Example:
/// ```dart
/// // For a timezone 5 hours behind UTC (e.g., EST)
/// final o = offset();
/// print(o); // "+05:00" or "-05:00" depending on the timezone
/// ```
String offset([DateTime? dateTime]) {
  final d = dateTime ?? DateTime.now();
  final offsetMinutes = d.timeZoneOffset.inMinutes;
  final sign = offsetMinutes >= 0 ? '+' : '-';
  final absOffset = offsetMinutes.abs();
  final hours = (absOffset ~/ 60).toString().padLeft(2, '0');
  final minutes = (absOffset % 60).toString().padLeft(2, '0');
  return '$sign$hours:$minutes';
}

/// Parses an ISO 8601 datetime string to a [DateTime].
///
/// Supports formats:
/// - YYYY-MM-DD
/// - YYYY-MM-DDTHH:MM:SSZ
/// - YYYY-MM-DDTHH:MM:SS+HH:MM
///
/// Example:
/// ```dart
/// final dt = parse('2024-01-15T10:30:45Z');
/// print(dt); // 2024-01-15 10:30:45.000Z
/// ```
DateTime parse(String dateTimeString) {
  return DateTime.parse(dateTimeString);
}
