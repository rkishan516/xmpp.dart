/// Random ID generator for XMPP stanzas.
///
/// Generates unique random IDs suitable for XMPP stanza identification.
library;

import 'dart:math';

final _random = Random.secure();
const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

/// Generates a random ID string.
///
/// Returns a random alphanumeric string of approximately 10 characters,
/// suitable for use as XMPP stanza IDs.
///
/// Example:
/// ```dart
/// final stanzaId = id();
/// print(stanzaId); // e.g., "k7f9m2xn3p"
/// ```
String id() {
  String result;
  do {
    result = _generateRandomString(10);
  } while (result.isEmpty);
  return result;
}

String _generateRandomString(int length) {
  return List.generate(
    length,
    (_) => _chars[_random.nextInt(_chars.length)],
  ).join();
}

/// Alias for [id] function.
///
/// Provides a more descriptive name for generating IDs.
String generateId() => id();
