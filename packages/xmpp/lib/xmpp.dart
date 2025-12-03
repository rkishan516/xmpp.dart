/// Full-featured XMPP library for Dart.
///
/// This is the main entry point for the XMPP library. It re-exports
/// all commonly used packages for convenience.
///
/// ## Quick Start
///
/// ### Client
///
/// ```dart
/// import 'package:xmpp/xmpp.dart';
///
/// void main() async {
///   final client = Client(ClientOptions(
///     service: 'wss://example.com/xmpp-websocket',
///     username: 'user',
///     password: 'password',
///   ));
///
///   client.on<XmlElement>('stanza', (stanza) {
///     print('Received: $stanza');
///   });
///
///   await client.start();
/// }
/// ```
///
/// ### Component
///
/// ```dart
/// import 'package:xmpp/xmpp.dart';
///
/// void main() async {
///   final comp = Component(ComponentOptions(
///     service: 'xmpp://component.example.com:5347',
///     domain: 'component.example.com',
///     password: 'secret',
///   ));
///
///   comp.on<XmlElement>('stanza', (stanza) {
///     print('Received: $stanza');
///   });
///
///   await comp.start();
/// }
/// ```
library;

export 'package:xmpp_base64/xmpp_base64.dart';
// Client and Component
export 'package:xmpp_client/xmpp_client.dart';
export 'package:xmpp_component/xmpp_component.dart';
// Connection
export 'package:xmpp_connection/xmpp_connection.dart';
// Debug logging
export 'package:xmpp_debug/xmpp_debug.dart'
    hide nsSASL, nsSASL2, nsComponent, nsFAST;
export 'package:xmpp_error/xmpp_error.dart' hide SASLError;
export 'package:xmpp_events/xmpp_events.dart';
// Utilities
export 'package:xmpp_id/xmpp_id.dart';
export 'package:xmpp_iq/xmpp_iq.dart';
export 'package:xmpp_jid/xmpp_jid.dart';
// Middleware
export 'package:xmpp_middleware/xmpp_middleware.dart';
// Reconnection and DNS
export 'package:xmpp_reconnect/xmpp_reconnect.dart';
export 'package:xmpp_resolve/xmpp_resolve.dart';
export 'package:xmpp_resource_binding/xmpp_resource_binding.dart';
// Authentication
export 'package:xmpp_sasl/xmpp_sasl.dart';
export 'package:xmpp_sasl_anonymous/xmpp_sasl_anonymous.dart';
export 'package:xmpp_sasl_plain/xmpp_sasl_plain.dart';
export 'package:xmpp_session_establishment/xmpp_session_establishment.dart';
// Stanzas
export 'package:xmpp_stanza/xmpp_stanza.dart';
// Stream features
export 'package:xmpp_stream_features/xmpp_stream_features.dart' hide nsStream;
export 'package:xmpp_stream_management/xmpp_stream_management.dart';
export 'package:xmpp_time/xmpp_time.dart' hide parse;
export 'package:xmpp_websocket/xmpp_websocket.dart';
// Core
export 'package:xmpp_xml/xmpp_xml.dart';
