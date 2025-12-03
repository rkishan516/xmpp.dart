/// XMPP SASL authentication framework.
///
/// Provides SASL authentication mechanism support for XMPP.
/// Use with mechanism packages like xmpp_sasl_plain, xmpp_sasl_scram_sha_1.
///
/// See: https://xmpp.org/rfcs/rfc6120.html#sasl
library;

export 'src/credentials.dart';
export 'src/mechanism.dart';
export 'src/sasl.dart';
export 'src/sasl_error.dart';
export 'src/sasl_factory.dart';
