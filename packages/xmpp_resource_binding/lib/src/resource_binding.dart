import 'dart:async';

import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_iq/xmpp_iq.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Resource binding namespace.
const nsBind = 'urn:ietf:params:xml:ns:xmpp-bind';

/// Create a bind element.
XmlElement makeBindElement([String? resource]) {
  return xml('bind', {'xmlns': nsBind}, [
    if (resource != null) xml('resource', {}, [resource]),
  ]);
}

/// Bind a resource to the connection.
Future<String> bind(EventEmitter entity, IQCaller iqCaller, [String? resource]) async {
  final result = await iqCaller.set(makeBindElement(resource), null);
  final jid = result?.getChildText('jid');

  if (jid == null) {
    throw StateError('Bind result missing JID');
  }

  // Set JID on entity if it has the method
  try {
    final dynamic e = entity;
    e.setJid(jid);
    e.ready(resumed: false);
  } catch (_) {
    // Entity doesn't have these methods
  }

  return jid;
}

/// Resource provider type.
typedef ResourceProvider = FutureOr<String?> Function();

/// Set up resource binding for stream features.
///
/// [resource] can be:
/// - A string: Use this exact resource
/// - A function: Call to get the resource
/// - null: Let the server assign a resource
void resourceBinding(
  StreamFeatures streamFeatures,
  IQCaller iqCaller, [
  dynamic resource,
]) {
  streamFeatures.use('bind', nsBind, (ctx, next, feature) async {
    String? res;
    if (resource is String) {
      res = resource;
    } else if (resource is ResourceProvider) {
      res = await resource();
    }

    await bind(ctx.entity, iqCaller, res);
    return next();
  });
}
