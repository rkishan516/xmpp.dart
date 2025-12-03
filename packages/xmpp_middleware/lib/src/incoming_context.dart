import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'context.dart';

/// Context for incoming stanzas.
///
/// The `from` field represents the sender, and `local`, `domain`, `resource`
/// are extracted from the sender's JID.
class IncomingContext extends Context {
  IncomingContext(EventEmitter entity, XmlElement stanza) : super(entity, stanza) {
    // Get JID from entity if available
    final entityJid = _getEntityJid(entity);
    final domain = _getEntityDomain(entity);

    final toAttr = stanza.attrs['to'] ?? entityJid?.toString();
    final fromAttr = stanza.attrs['from'] ?? domain;

    if (toAttr != null) {
      to = JID.parse(toAttr);
    }

    if (fromAttr != null) {
      from = JID.parse(fromAttr);
      local = from!.local;
      this.domain = from!.domain;
      resource = from!.resource;
    }
  }

  static JID? _getEntityJid(EventEmitter entity) {
    // Check if entity has a jid property (like Connection)
    try {
      final dynamic e = entity;
      return e.jid as JID?;
    } catch (_) {
      return null;
    }
  }

  static String? _getEntityDomain(EventEmitter entity) {
    // Check if entity has options.domain
    try {
      final dynamic e = entity;
      final options = e.options as Map<String, dynamic>?;
      return options?['domain'] as String?;
    } catch (_) {
      return null;
    }
  }
}
