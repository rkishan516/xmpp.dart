import 'package:xmpp_error/xmpp_error.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Stream error for XMPP connections.
///
/// Stream errors are unrecoverable and result in stream closure.
class StreamError extends XMPPError {
  StreamError(super.condition, [super.text, super.application]);

  /// Create a StreamError from an XML element.
  static StreamError fromElement(XmlElement element) {
    final children = element.getChildElements();
    if (children.isEmpty) {
      return StreamError('undefined-condition');
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

    final error = StreamError(condition.name, text, application);
    error.element = element;
    return error;
  }

  @override
  String toString() {
    final buffer = StringBuffer('StreamError: $condition');
    if (text != null && text!.isNotEmpty) {
      buffer.write(' - $text');
    }
    return buffer.toString();
  }
}
