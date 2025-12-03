import 'dart:async';
import 'package:xmpp_sasl/xmpp_sasl.dart';

/// SASL PLAIN mechanism.
///
/// The PLAIN mechanism transmits credentials in plain text.
/// Format: [authzid] NUL authcid NUL passwd
///
/// See: https://tools.ietf.org/html/rfc4616
class PlainMechanism implements SASLMechanism {
  @override
  final String name = 'PLAIN';

  @override
  final bool clientFirst = true;

  @override
  FutureOr<String> response(Credentials credentials) {
    final authcid = credentials.username ?? '';
    final passwd = credentials.password ?? '';

    // Format: [authzid] NUL authcid NUL passwd
    // authzid is optional and typically left empty
    return '\x00$authcid\x00$passwd';
  }

  @override
  FutureOr<void> challenge(String challenge) {
    // PLAIN doesn't use challenges
  }
}

/// Register the PLAIN mechanism with a SASL factory.
void saslPlain(SASLFactory sasl) {
  sasl.use('PLAIN', PlainMechanism.new);
}
