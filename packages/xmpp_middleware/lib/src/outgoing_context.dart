import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'context.dart';

/// Context for outgoing stanzas.
///
/// The `to` field represents the recipient, and `local`, `domain`, `resource`
/// are extracted from the recipient's JID.
class OutgoingContext extends Context {
  OutgoingContext(EventEmitter entity, XmlElement stanza) : super(entity, stanza) {
    // Get JID from entity if available
    final entityJid = _getEntityJid(entity);
    final domain = _getEntityDomain(entity);

    final fromAttr = stanza.attrs['from'] ?? entityJid?.toString();
    final toAttr = stanza.attrs['to'] ?? domain;

    if (fromAttr != null) {
      from = JID.parse(fromAttr);
    }

    if (toAttr != null) {
      to = JID.parse(toAttr);
      local = to!.local;
      this.domain = to!.domain;
      resource = to!.resource;
    }
  }

  static JID? _getEntityJid(EventEmitter entity) {
    try {
      final dynamic e = entity;
      return e.jid as JID?;
    } catch (_) {
      return null;
    }
  }

  static String? _getEntityDomain(EventEmitter entity) {
    try {
      final dynamic e = entity;
      final options = e.options as Map<String, dynamic>?;
      return options?['domain'] as String?;
    } catch (_) {
      return null;
    }
  }
}
