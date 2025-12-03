/// XMPP middleware system for routing stanzas and nonzas.
///
/// Provides Koa-style middleware composition for processing
/// incoming and outgoing XMPP stanzas.
library;

export 'src/compose.dart';
export 'src/context.dart';
export 'src/incoming_context.dart';
export 'src/middleware.dart';
export 'src/outgoing_context.dart';
export 'src/stanza_error.dart';
