import 'package:xmpp_xml/xmpp_xml.dart';

/// XEP-0199 XMPP Ping namespace.
const nsPing = 'urn:xmpp:ping';

/// XMPP Client namespace (jabber:client).
const nsClient = 'jabber:client';

/// Ping stanza element for XEP-0199.
///
/// Represents the `<ping xmlns='urn:xmpp:ping'/>` element used in
/// IQ stanzas for XMPP ping requests.
///
/// Example:
/// ```dart
/// // Create a ping stanza
/// final ping = PingStanza();
///
/// // Use with IQ caller
/// await iqCaller.get(ping.toXml(), 'server.example.com');
///
/// // Parse from XML
/// final ping = PingStanza.fromXml(element);
/// ```
class PingStanza {
  /// The underlying XML element.
  final XmlElement element;

  /// Create a new ping stanza.
  PingStanza() : element = xml('ping', {'xmlns': nsPing}, []);

  /// Create a ping stanza from an existing XML element.
  PingStanza.fromXml(this.element);

  /// The element name.
  String get name => element.name;

  /// The namespace.
  String? get xmlns => element.getNS();

  /// Check if this is a valid ping element.
  bool get isValid => element.is_('ping', nsPing);

  /// Convert to XML element.
  XmlElement toXml() => element;

  /// Convert to XML string.
  @override
  String toString() => element.toString();

  /// Create a ping IQ request stanza.
  ///
  /// [to] - The target JID to ping (optional, defaults to server)
  /// [id] - The stanza ID (optional, will be auto-generated if not provided)
  static XmlElement createRequest({String? to, String? id}) {
    return xml('iq', {
      'type': 'get',
      'xmlns': nsClient,
      if (to != null) 'to': to,
      if (id != null) 'id': id,
    }, [
      xml('ping', {'xmlns': nsPing}, []),
    ]);
  }

  /// Create a ping IQ result (pong) stanza.
  ///
  /// [to] - The recipient JID
  /// [from] - The sender JID (optional)
  /// [id] - The stanza ID (should match the request)
  static XmlElement createResult({
    required String to,
    String? from,
    required String id,
  }) {
    return xml('iq', {
      'type': 'result',
      'xmlns': nsClient,
      'to': to,
      if (from != null) 'from': from,
      'id': id,
    }, []);
  }
}

/// Extension on XmlElement for ping stanza parsing.
extension PingStanzaParsing on XmlElement {
  /// Check if this element is a ping stanza.
  bool get isPing => is_('ping', nsPing);

  /// Check if this IQ contains a ping request.
  bool get isPingRequest {
    if (name != 'iq') return false;
    if (attrs['type'] != 'get') return false;
    return getChild('ping', nsPing) != null;
  }

  /// Convert to PingStanza if this is a ping element.
  PingStanza? toPingStanza() => isPing ? PingStanza.fromXml(this) : null;

  /// Get the ping child element from an IQ stanza.
  PingStanza? getPingChild() {
    final pingEl = getChild('ping', nsPing);
    return pingEl != null ? PingStanza.fromXml(pingEl) : null;
  }
}
