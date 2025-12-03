import 'dart:async';
import 'credentials.dart';

/// Base class for SASL mechanisms.
abstract class SASLMechanism {
  /// The name of the mechanism (e.g., 'PLAIN', 'SCRAM-SHA-1').
  String get name;

  /// Whether this mechanism sends client-first.
  bool get clientFirst;

  /// Generate the response for the given credentials.
  FutureOr<String> response(Credentials credentials);

  /// Process a challenge from the server.
  FutureOr<void> challenge(String challenge);
}
