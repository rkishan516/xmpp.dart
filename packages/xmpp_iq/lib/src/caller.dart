import 'dart:async';

import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_id/xmpp_id.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Check if a stanza is an IQ reply (result or error).
bool isReply(String name, String type) {
  if (name != 'iq') return false;
  if (type != 'error' && type != 'result') return false;
  return true;
}

/// IQ Caller for making IQ requests and receiving responses.
///
/// The caller sends IQ stanzas and tracks pending responses by ID.
class IQCaller {
  final EventEmitter entity;
  final MiddlewareManager middleware;
  final Map<String, Deferred<XmlElement>> _handlers = {};

  /// Default timeout for IQ requests.
  final Duration timeout;

  IQCaller({
    required this.entity,
    required this.middleware,
    this.timeout = const Duration(seconds: 30),
  });

  /// Start the IQ caller by registering middleware.
  void start() {
    middleware.use(_route);
  }

  /// Middleware to route IQ responses.
  Future<dynamic> _route(IncomingContext ctx, Future<dynamic> Function() next) async {
    if (!isReply(ctx.name, ctx.type)) return next();

    final deferred = _handlers[ctx.id];
    if (deferred == null) return next();

    if (ctx.type == 'error') {
      final errorElement = ctx.stanza.getChild('error');
      if (errorElement != null) {
        deferred.reject(StanzaError.fromElement(errorElement));
      } else {
        deferred.reject(StanzaError('undefined-condition'));
      }
    } else {
      deferred.resolve(ctx.stanza);
    }

    _handlers.remove(ctx.id);
    return null;
  }

  /// Send an IQ request and wait for response.
  ///
  /// If the stanza doesn't have an ID, one will be generated.
  Future<XmlElement> request(XmlElement stanza, [Duration? timeout]) async {
    timeout ??= this.timeout;

    if (stanza.attrs['id'] == null) {
      stanza.attrs['id'] = id();
    }

    final stanzaId = stanza.attrs['id']!;
    final deferred = Deferred<XmlElement>();
    _handlers[stanzaId] = deferred;

    try {
      // Send the stanza
      final dynamic e = entity;
      await e.send(stanza);

      // Wait for response with timeout
      return await deferred.future.timeout(timeout, onTimeout: () {
        _handlers.remove(stanzaId);
        throw TimeoutException('IQ request timed out', timeout);
      });
    } catch (err) {
      _handlers.remove(stanzaId);
      rethrow;
    }
  }

  /// Send an IQ get request with a child element.
  ///
  /// Returns the child element from the response.
  Future<XmlElement?> get(XmlElement element, String? to, [Duration? timeout]) async {
    final name = element.name;
    final xmlns = element.attrs['xmlns'];

    final result = await request(
      xml('iq', {'type': 'get', if (to != null) 'to': to}, [element]),
      timeout,
    );

    return result.getChild(name, xmlns);
  }

  /// Send an IQ set request with a child element.
  ///
  /// Returns the child element from the response.
  Future<XmlElement?> set(XmlElement element, String? to, [Duration? timeout]) async {
    final name = element.name;
    final xmlns = element.attrs['xmlns'];

    final result = await request(
      xml('iq', {'type': 'set', if (to != null) 'to': to}, [element]),
      timeout,
    );

    return result.getChild(name, xmlns);
  }
}

/// Create an IQ caller for an entity.
IQCaller iqCaller({
  required EventEmitter entity,
  required MiddlewareManager middleware,
  Duration timeout = const Duration(seconds: 30),
}) {
  final caller = IQCaller(
    entity: entity,
    middleware: middleware,
    timeout: timeout,
  );
  caller.start();
  return caller;
}
