import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_xml/xmpp_xml.dart';
import 'compose.dart';
import 'incoming_context.dart';
import 'outgoing_context.dart';

/// Middleware manager for XMPP entity.
///
/// Provides `use()` for incoming stanzas and `filter()` for outgoing stanzas.
class MiddlewareManager {
  final EventEmitter entity;
  final List<Middleware<IncomingContext>> _incoming = [];
  final List<Middleware<OutgoingContext>> _outgoing = [];

  MiddlewareManager({required this.entity}) {
    // Add error handler as first middleware
    _incoming.add(_errorHandler());

    // Listen to element and send events
    entity.on<XmlElement>('element', _handleIncoming);
    entity.on<XmlElement>('send', _handleOutgoing);
  }

  /// Add middleware for incoming stanzas/nonzas.
  Middleware<IncomingContext> use(Middleware<IncomingContext> fn) {
    _incoming.add(fn);
    return fn;
  }

  /// Add middleware for outgoing stanzas/nonzas.
  Middleware<OutgoingContext> filter(Middleware<OutgoingContext> fn) {
    _outgoing.add(fn);
    return fn;
  }

  void _handleIncoming(XmlElement stanza) {
    final ctx = IncomingContext(entity, stanza);
    compose<IncomingContext>(_incoming)(ctx, () async => null);
  }

  void _handleOutgoing(XmlElement stanza) {
    final ctx = OutgoingContext(entity, stanza);
    compose<OutgoingContext>(_outgoing)(ctx, () async => null);
  }

  /// Error handler middleware.
  Middleware<IncomingContext> _errorHandler() {
    return (ctx, next) async {
      try {
        final reply = await next();
        if (reply != null && reply is XmlElement) {
          await _sendReply(reply);
        }
        return reply;
      } catch (err) {
        entity.emit('error', err);
        return null;
      }
    };
  }

  Future<void> _sendReply(XmlElement reply) async {
    try {
      final dynamic e = entity;
      await e.send(reply);
    } catch (_) {
      // Entity doesn't have send method
    }
  }
}

/// Create a middleware manager for an entity.
MiddlewareManager middleware({required EventEmitter entity}) {
  return MiddlewareManager(entity: entity);
}
