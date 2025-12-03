import 'package:xmpp_xml/xmpp_xml.dart';

/// SASL namespace.
const nsSASL = 'urn:ietf:params:xml:ns:xmpp-sasl';

/// SASL2 namespace.
const nsSASL2 = 'urn:xmpp:sasl:2';

/// Component namespace.
const nsComponent = 'jabber:component:accept';

/// FAST namespace.
const nsFAST = 'urn:xmpp:fast:0';

/// List of sensitive element types that should be hidden.
const sensitiveElements = [
  ('handshake', nsComponent),
  ('auth', nsSASL),
  ('challenge', nsSASL),
  ('response', nsSASL),
  ('success', nsSASL),
  ('challenge', nsSASL2),
  ('response', nsSASL2),
];

/// Check if an element contains sensitive data.
bool isSensitive(XmlElement element) {
  if (element.children.isEmpty) return false;
  return sensitiveElements.any((sensitive) {
    return element.is_(sensitive.$1, sensitive.$2);
  });
}

/// Hide the contents of an element.
void _hide(XmlElement? element) {
  if (element != null) {
    element.children.clear();
    element.append(xml('hidden', {'xmlns': 'xmpp.dart'}, []));
  }
}

/// Hide sensitive data in an element.
///
/// Returns a copy of the element with sensitive data replaced by
/// `<hidden xmlns="xmpp.dart"/>`.
XmlElement hideSensitive(XmlElement element) {
  final clone = element.clone();

  if (isSensitive(clone)) {
    _hide(clone);
  } else if (clone.is_('authenticate', nsSASL2)) {
    _hide(clone.getChild('initial-response'));
  } else if (clone.getNS() == nsSASL2) {
    _hide(clone.getChild('additional-data'));
    final token = clone.getChild('token', nsFAST);
    if (token != null) {
      token.attrs['token'] = 'hidden by xmpp.dart';
    }
  }

  return clone;
}

/// Format an element for logging with sensitive data hidden.
String formatElement(XmlElement element) {
  return hideSensitive(element).toString();
}
