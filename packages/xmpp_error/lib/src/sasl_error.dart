import 'xmpp_error.dart';

/// SASL authentication error.
///
/// See: https://xmpp.org/rfcs/rfc6120.html#sasl-errors
///
/// Common conditions:
/// - aborted
/// - account-disabled
/// - credentials-expired
/// - encryption-required
/// - incorrect-encoding
/// - invalid-authzid
/// - invalid-mechanism
/// - malformed-request
/// - mechanism-too-weak
/// - not-authorized
/// - temporary-auth-failure
class SASLError extends XMPPError {
  SASLError(super.condition, [super.text, super.application]);

  @override
  String toString() {
    final buffer = StringBuffer('SASLError: $condition');
    if (text != null && text!.isNotEmpty) {
      buffer.write(' - $text');
    }
    return buffer.toString();
  }

  /// SASL error conditions as defined in RFC 6120.
  static const conditions = <String>[
    'aborted',
    'account-disabled',
    'credentials-expired',
    'encryption-required',
    'incorrect-encoding',
    'invalid-authzid',
    'invalid-mechanism',
    'malformed-request',
    'mechanism-too-weak',
    'not-authorized',
    'temporary-auth-failure',
  ];
}
