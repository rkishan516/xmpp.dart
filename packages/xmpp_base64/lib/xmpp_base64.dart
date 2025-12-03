/// Base64 encoding/decoding utilities for XMPP.
///
/// Provides simple encode/decode functions for base64 strings,
/// commonly used in SASL authentication.
library;

import 'dart:convert';

/// Encodes a string to base64.
///
/// Example:
/// ```dart
/// final encoded = encode('Hello, World!');
/// print(encoded); // SGVsbG8sIFdvcmxkIQ==
/// ```
String encode(String string) {
  return base64.encode(utf8.encode(string));
}

/// Decodes a base64 string.
///
/// Example:
/// ```dart
/// final decoded = decode('SGVsbG8sIFdvcmxkIQ==');
/// print(decoded); // Hello, World!
/// ```
String decode(String string) {
  return utf8.decode(base64.decode(string));
}

/// Encodes bytes to base64.
///
/// Example:
/// ```dart
/// final encoded = encodeBytes([72, 101, 108, 108, 111]);
/// print(encoded); // SGVsbG8=
/// ```
String encodeBytes(List<int> bytes) {
  return base64.encode(bytes);
}

/// Decodes a base64 string to bytes.
///
/// Example:
/// ```dart
/// final bytes = decodeBytes('SGVsbG8=');
/// print(bytes); // [72, 101, 108, 108, 111]
/// ```
List<int> decodeBytes(String string) {
  return base64.decode(string);
}
