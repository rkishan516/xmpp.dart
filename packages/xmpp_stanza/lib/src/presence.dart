import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'stanza.dart';

/// Presence types as defined in XMPP RFC 6121.
enum PresenceType {
  /// Entity is available (default, no type attribute).
  available,

  /// Entity is unavailable (going offline).
  unavailable,

  /// Sender wishes to subscribe to recipient's presence.
  subscribe,

  /// Sender has allowed the subscription.
  subscribed,

  /// Sender is unsubscribing from recipient's presence.
  unsubscribe,

  /// Sender has removed the subscription.
  unsubscribed,

  /// Probe for current presence (server use).
  probe,

  /// Error in presence stanza.
  error,
}

/// Extension to convert PresenceType to/from string.
extension PresenceTypeExtension on PresenceType {
  /// Convert to XMPP string value.
  String? get value {
    switch (this) {
      case PresenceType.available:
        return null; // No type attribute for available
      case PresenceType.unavailable:
        return 'unavailable';
      case PresenceType.subscribe:
        return 'subscribe';
      case PresenceType.subscribed:
        return 'subscribed';
      case PresenceType.unsubscribe:
        return 'unsubscribe';
      case PresenceType.unsubscribed:
        return 'unsubscribed';
      case PresenceType.probe:
        return 'probe';
      case PresenceType.error:
        return 'error';
    }
  }

  /// Parse from XMPP string value.
  static PresenceType fromString(String? value) {
    switch (value) {
      case 'unavailable':
        return PresenceType.unavailable;
      case 'subscribe':
        return PresenceType.subscribe;
      case 'subscribed':
        return PresenceType.subscribed;
      case 'unsubscribe':
        return PresenceType.unsubscribe;
      case 'unsubscribed':
        return PresenceType.unsubscribed;
      case 'probe':
        return PresenceType.probe;
      case 'error':
        return PresenceType.error;
      default:
        return PresenceType.available;
    }
  }
}

/// Presence show values (availability sub-states).
enum PresenceShow {
  /// Available for chat (most available).
  chat,

  /// Away from device.
  away,

  /// Extended away (longer absence).
  xa,

  /// Do not disturb.
  dnd,
}

/// Extension to convert PresenceShow to/from string.
extension PresenceShowExtension on PresenceShow {
  /// Convert to XMPP string value.
  String get value {
    switch (this) {
      case PresenceShow.chat:
        return 'chat';
      case PresenceShow.away:
        return 'away';
      case PresenceShow.xa:
        return 'xa';
      case PresenceShow.dnd:
        return 'dnd';
    }
  }

  /// Parse from XMPP string value.
  static PresenceShow? fromString(String? value) {
    switch (value) {
      case 'chat':
        return PresenceShow.chat;
      case 'away':
        return PresenceShow.away;
      case 'xa':
        return PresenceShow.xa;
      case 'dnd':
        return PresenceShow.dnd;
      default:
        return null;
    }
  }
}

/// XMPP Presence stanza.
class Presence extends Stanza {
  Presence({
    JID? to,
    JID? from,
    PresenceType type = PresenceType.available,
    String? id,
    PresenceShow? show,
    String? status,
    int? priority,
    String? lang,
  }) : super(xml('presence', {
          if (to != null) 'to': to.toString(),
          if (from != null) 'from': from.toString(),
          if (type.value != null) 'type': type.value!,
          if (id != null) 'id': id,
          if (lang != null) 'xml:lang': lang,
        }, [
          if (show != null) xml('show', {}, [show.value]),
          if (status != null) xml('status', {}, [status]),
          if (priority != null) xml('priority', {}, [priority.toString()]),
        ]));

  Presence.fromXml(super.element);

  factory Presence.available({PresenceShow? show, String? status, int? priority}) {
    return Presence(type: PresenceType.available, show: show, status: status, priority: priority);
  }

  factory Presence.unavailable({String? status}) {
    return Presence(type: PresenceType.unavailable, status: status);
  }

  factory Presence.subscribe(JID to) {
    return Presence(to: to, type: PresenceType.subscribe);
  }

  factory Presence.subscribed(JID to) {
    return Presence(to: to, type: PresenceType.subscribed);
  }

  factory Presence.unsubscribe(JID to) {
    return Presence(to: to, type: PresenceType.unsubscribe);
  }

  factory Presence.unsubscribed(JID to) {
    return Presence(to: to, type: PresenceType.unsubscribed);
  }

  PresenceType get presenceType => PresenceTypeExtension.fromString(element.attrs['type']);

  set presenceType(PresenceType value) {
    final typeValue = value.value;
    if (typeValue == null) {
      element.attrs.remove('type');
    } else {
      element.attrs['type'] = typeValue;
    }
  }

  PresenceShow? get show {
    final showText = element.getChildText('show');
    return PresenceShowExtension.fromString(showText);
  }

  set show(PresenceShow? value) {
    final existing = element.getChild('show');
    if (existing != null) element.remove(existing);
    if (value != null) element.append(xml('show', {}, [value.value]));
  }

  String? get status => element.getChildText('status');

  set status(String? value) {
    final existing = element.getChild('status');
    if (existing != null) element.remove(existing);
    if (value != null) element.append(xml('status', {}, [value]));
  }

  int? get priority {
    final text = element.getChildText('priority');
    return text != null ? int.tryParse(text) : null;
  }

  set priority(int? value) {
    final existing = element.getChild('priority');
    if (existing != null) element.remove(existing);
    if (value != null) element.append(xml('priority', {}, [value.toString()]));
  }

  bool get isAvailable => presenceType == PresenceType.available;
  bool get isUnavailable => presenceType == PresenceType.unavailable;
  bool get isSubscribe => presenceType == PresenceType.subscribe;
  bool get isSubscribed => presenceType == PresenceType.subscribed;
  bool get isError => presenceType == PresenceType.error;

  @override
  Presence copy() => Presence.fromXml(element.clone());
}

extension PresenceParsing on XmlElement {
  bool get isPresence => name == 'presence';
  Presence? toPresence() => isPresence ? Presence.fromXml(this) : null;
}
