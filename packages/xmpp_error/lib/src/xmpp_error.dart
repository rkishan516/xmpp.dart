/// Base XMPP error class.
///
/// All XMPP-specific errors extend this class.
/// See: https://xmpp.org/rfcs/rfc6120.html#rfc.section.4.9.2
class XMPPError implements Exception {
  /// The error condition (e.g., 'bad-request', 'item-not-found').
  final String condition;

  /// Optional human-readable error text.
  final String? text;

  /// Optional application-specific error element.
  final dynamic application;

  /// The original XML element (if parsed from element).
  dynamic element;

  XMPPError(this.condition, [this.text, this.application]);

  @override
  String toString() {
    final buffer = StringBuffer('XMPPError: $condition');
    if (text != null && text!.isNotEmpty) {
      buffer.write(' - $text');
    }
    return buffer.toString();
  }

  /// Creates an error from its component parts.
  ///
  /// This is a helper for subclasses to implement fromElement.
  static T create<T extends XMPPError>(
    T Function(String condition, String? text, dynamic application) factory,
    String condition,
    String? text,
    dynamic application,
  ) {
    return factory(condition, text, application);
  }
}
