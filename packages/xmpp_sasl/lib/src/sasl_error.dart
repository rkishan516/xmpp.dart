import 'package:xmpp_error/xmpp_error.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// SASL authentication error.
///
/// See: https://xmpp.org/rfcs/rfc6120.html#sasl-errors
class SASLError extends XMPPError {
  SASLError(super.condition, [super.text, super.application]);

  /// Create a SASLError from an XML failure element.
  static SASLError fromElement(XmlElement element) {
    final children = element.getChildElements();
    if (children.isEmpty) {
      return SASLError('undefined-condition');
    }

    final condition = children.first;
    String? text;
    dynamic application;

    // Look for text element
    final textElement = element.getChild('text');
    if (textElement != null) {
      text = textElement.text();
    }

    // Look for application-specific element
    for (final child in children) {
      if (child.name != condition.name && child.name != 'text') {
        application = child;
        break;
      }
    }

    final error = SASLError(condition.name, text, application);
    error.element = element;
    return error;
  }

  @override
  String toString() {
    final buffer = StringBuffer('SASLError: $condition');
    if (text != null && text!.isNotEmpty) {
      buffer.write(' - $text');
    }
    return buffer.toString();
  }

  /// SASL error conditions as defined in RFC 6120.
  static const conditions = <String>[
    'aborted',
    'account-disabled',
    'credentials-expired',
    'encryption-required',
    'incorrect-encoding',
    'invalid-authzid',
    'invalid-mechanism',
    'malformed-request',
    'mechanism-too-weak',
    'not-authorized',
    'temporary-auth-failure',
  ];
}
