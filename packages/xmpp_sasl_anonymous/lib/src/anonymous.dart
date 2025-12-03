import 'dart:async';
import 'package:xmpp_sasl/xmpp_sasl.dart';

/// SASL ANONYMOUS mechanism.
///
/// The ANONYMOUS mechanism allows clients to authenticate
/// without providing credentials.
///
/// See: https://tools.ietf.org/html/rfc4505
class AnonymousMechanism implements SASLMechanism {
  @override
  final String name = 'ANONYMOUS';

  @override
  final bool clientFirst = true;

  @override
  FutureOr<String> response(Credentials credentials) {
    // Can optionally send a trace token
    return '';
  }

  @override
  FutureOr<void> challenge(String challenge) {
    // ANONYMOUS doesn't use challenges
  }
}

/// Register the ANONYMOUS mechanism with a SASL factory.
void saslAnonymous(SASLFactory sasl) {
  sasl.use('ANONYMOUS', AnonymousMechanism.new);
}
