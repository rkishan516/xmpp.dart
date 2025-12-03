import 'package:xmpp_error/xmpp_error.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Stanza-level XMPP error.
///
/// Stanza errors are recoverable and specific to individual stanzas.
/// See: https://xmpp.org/rfcs/rfc6120.html#stanzas-error
class StanzaError extends XMPPError {
  /// The error type (auth, cancel, continue, modify, wait).
  final String type;

  /// The JID that generated the error.
  final String? by;

  StanzaError(
    String condition, {
    String? text,
    dynamic application,
    this.type = 'cancel',
    this.by,
  }) : super(condition, text, application);

  /// Create a StanzaError from an XML error element.
  static StanzaError fromElement(XmlElement element) {
    final children = element.getChildElements();
    if (children.isEmpty) {
      return StanzaError('undefined-condition');
    }

    final condition = children.first;
    String? text;
    dynamic application;

    if (children.length > 1) {
      final second = children[1];
      if (second.name == 'text') {
        text = second.text();
      } else {
        application = second;
      }

      if (children.length > 2) {
        application = children[2];
      }
    }

    final error = StanzaError(
      condition.name,
      text: text,
      application: application,
      type: element.attrs['type'] ?? 'cancel',
      by: element.attrs['by'],
    );
    error.element = element;
    return error;
  }

  @override
  String toString() {
    final buffer = StringBuffer('StanzaError: $condition');
    if (text != null && text!.isNotEmpty) {
      buffer.write(' - $text');
    }
    buffer.write(' (type: $type)');
    if (by != null) {
      buffer.write(' (by: $by)');
    }
    return buffer.toString();
  }

  /// Stanza error types as defined in RFC 6120.
  static const types = <String>[
    'auth',
    'cancel',
    'continue',
    'modify',
    'wait',
  ];

  /// Stanza error conditions as defined in RFC 6120.
  static const conditions = <String>[
    'bad-request',
    'conflict',
    'feature-not-implemented',
    'forbidden',
    'gone',
    'internal-server-error',
    'item-not-found',
    'jid-malformed',
    'not-acceptable',
    'not-allowed',
    'not-authorized',
    'payment-required',
    'policy-violation',
    'recipient-unavailable',
    'redirect',
    'registration-required',
    'remote-server-not-found',
    'remote-server-timeout',
    'resource-constraint',
    'service-unavailable',
    'subscription-required',
    'undefined-condition',
    'unexpected-request',
  ];
}
