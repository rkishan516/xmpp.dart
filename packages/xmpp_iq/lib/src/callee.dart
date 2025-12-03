import 'dart:async';

import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Namespace for XMPP stanza errors.
const nsStanza = 'urn:ietf:params:xml:ns:xmpp-stanzas';

/// Check if a stanza is an IQ query (get or set).
bool isQuery(String name, String type) {
  if (name != 'iq') return false;
  if (type == 'error' || type == 'result') return false;
  return true;
}

/// Check if an IQ query is valid.
bool isValidQuery(String type, List<XmlElement> children, XmlElement? child) {
  if (type != 'get' && type != 'set') return false;
  if (children.length != 1) return false;
  if (child == null) return false;
  return true;
}

/// Build an IQ reply stanza.
XmlElement buildReply(XmlElement stanza) {
  return xml('iq', {
    if (stanza.attrs['from'] != null) 'to': stanza.attrs['from']!,
    if (stanza.attrs['to'] != null) 'from': stanza.attrs['to']!,
    if (stanza.attrs['id'] != null) 'id': stanza.attrs['id']!,
  }, []);
}

/// Build an IQ result reply.
XmlElement buildReplyResult(XmlElement stanza, [XmlElement? child]) {
  final reply = buildReply(stanza);
  reply.attrs['type'] = 'result';
  if (child != null) {
    reply.append(child);
  }
  return reply;
}

/// Build an IQ error reply.
XmlElement buildReplyError(XmlElement stanza, XmlElement error, [XmlElement? child]) {
  final reply = buildReply(stanza);
  reply.attrs['type'] = 'error';
  if (child != null) {
    reply.append(child);
  }
  reply.append(error);
  return reply;
}

/// Build an error element.
XmlElement buildError(String type, String condition) {
  return xml('error', {'type': type}, [
    xml(condition, {'xmlns': nsStanza}, []),
  ]);
}

/// Handler function type for IQ requests.
typedef IQHandler = FutureOr<dynamic> Function(IncomingContext ctx, Future<dynamic> Function() next);

/// IQ Callee for handling incoming IQ requests.
class IQCallee {
  final EventEmitter entity;
  final MiddlewareManager middleware;

  IQCallee({
    required this.entity,
    required this.middleware,
  });

  /// Start the IQ callee by registering the IQ handler middleware.
  void start() {
    middleware.use(_iqHandler);
  }

  /// Main IQ handler middleware.
  Future<dynamic> _iqHandler(IncomingContext ctx, Future<dynamic> Function() next) async {
    if (!isQuery(ctx.name, ctx.type)) return next();

    final children = ctx.stanza.getChildElements();
    final child = children.isNotEmpty ? children.first : null;

    if (!isValidQuery(ctx.type, children, child)) {
      return buildReplyError(
        ctx.stanza,
        buildError('modify', 'bad-request'),
        child,
      );
    }

    ctx.element = child;

    dynamic reply;
    try {
      reply = await next();
    } catch (err) {
      entity.emit('error', err);
      reply = buildError('cancel', 'internal-server-error');
    }

    reply ??= buildError('cancel', 'service-unavailable');

    if (reply is XmlElement && reply.name == 'error') {
      return buildReplyError(ctx.stanza, reply, child);
    }

    return buildReplyResult(
      ctx.stanza,
      reply is XmlElement ? reply : null,
    );
  }

  /// Register a handler for IQ get requests.
  void get(String ns, String name, IQHandler handler) {
    middleware.use(_route('get', ns, name, handler));
  }

  /// Register a handler for IQ set requests.
  void set(String ns, String name, IQHandler handler) {
    middleware.use(_route('set', ns, name, handler));
  }

  /// Create a routing middleware for IQ handlers.
  Middleware<IncomingContext> _route(
    String type,
    String ns,
    String name,
    IQHandler handler,
  ) {
    return (ctx, next) async {
      if (ctx.type != type ||
          ctx.element == null ||
          !ctx.element!.is_(name, ns)) {
        return next();
      }
      return handler(ctx, next);
    };
  }
}

/// Create an IQ callee for an entity.
IQCallee iqCallee({
  required EventEmitter entity,
  required MiddlewareManager middleware,
}) {
  final callee = IQCallee(
    entity: entity,
    middleware: middleware,
  );
  callee.start();
  return callee;
}
