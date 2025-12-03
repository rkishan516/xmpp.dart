/// XMPP error classes and utilities.
///
/// Provides base error classes for XMPP protocol errors.
/// StreamError is in xmpp_connection, StanzaError is in xmpp_middleware.
///
/// See: https://xmpp.org/rfcs/rfc6120.html#rfc.section.4.9.2
library;

export 'src/sasl_error.dart';
export 'src/timeout_error.dart';
export 'src/xmpp_error.dart';
