import 'dart:async';

import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Namespace for stream features.
const nsStream = 'http://etherx.jabber.org/streams';

/// Handler type for stream features.
typedef StreamFeatureHandler = FutureOr<dynamic> Function(
  IncomingContext ctx,
  Future<dynamic> Function() next,
  XmlElement feature,
);

/// Stream features manager.
///
/// Allows registering handlers for specific stream features.
class StreamFeatures {
  final MiddlewareManager middleware;

  StreamFeatures({required this.middleware});

  /// Register a handler for a stream feature.
  ///
  /// The handler is called when a stream:features element is received
  /// that contains a child element matching [name] and [xmlns].
  Middleware<IncomingContext> use(
    String name,
    String xmlns,
    StreamFeatureHandler handler,
  ) {
    return middleware.use((ctx, next) async {
      final stanza = ctx.stanza;

      // Only process stream:features elements
      // Handle both 'features' (without prefix) and 'stream:features' (with prefix)
      if (!stanza.is_('features', nsStream) && !stanza.is_('stream:features')) {
        return next();
      }

      // Look for the specific feature
      final feature = stanza.getChild(name, xmlns);
      if (feature == null) {
        return next();
      }

      // Call the handler with the feature
      return handler(ctx, next, feature);
    });
  }
}

/// Create a stream features manager.
StreamFeatures streamFeatures({required MiddlewareManager middleware}) {
  return StreamFeatures(middleware: middleware);
}
