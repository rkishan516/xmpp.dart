import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Base context for middleware processing.
///
/// Contains the stanza being processed and metadata about it.
class Context {
  /// The entity (connection) that received/sent the stanza.
  final EventEmitter entity;

  /// The stanza being processed.
  final XmlElement stanza;

  /// The stanza name (iq, message, presence).
  final String name;

  /// The stanza type attribute.
  final String type;

  /// The stanza ID.
  final String id;

  /// The sender JID.
  JID? from;

  /// The recipient JID.
  JID? to;

  /// The local part of the relevant JID.
  String local = '';

  /// The domain part of the relevant JID.
  String domain = '';

  /// The resource part of the relevant JID.
  String resource = '';

  /// The child element for IQ stanzas.
  XmlElement? element;

  Context(this.entity, this.stanza)
      : name = stanza.name,
        id = stanza.attrs['id'] ?? '',
        type = _inferType(stanza);

  static String _inferType(XmlElement stanza) {
    final name = stanza.name;
    final type = stanza.attrs['type'];

    if (type != null) return type;

    if (name == 'message') return 'normal';
    if (name == 'presence') return 'available';
    return '';
  }
}
