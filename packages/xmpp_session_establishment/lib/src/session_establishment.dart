import 'package:xmpp_iq/xmpp_iq.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Session establishment namespace.
const nsSession = 'urn:ietf:params:xml:ns:xmpp-session';

/// Set up session establishment for stream features.
///
/// This handles the deprecated session feature for legacy servers.
void sessionEstablishment(StreamFeatures streamFeatures, IQCaller iqCaller) {
  streamFeatures.use('session', nsSession, (ctx, next, feature) async {
    // Check if session is optional
    if (feature.getChild('optional') != null) {
      return next();
    }

    // Send session IQ
    await iqCaller.set(xml('session', {'xmlns': nsSession}, []), null);
    return next();
  });
}
