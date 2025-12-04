import 'package:xmpp_xml/xmpp_xml.dart';

/// Base class for typed stanza extensions.
///
/// Extend this class to create custom stanza extensions that can be
/// added to Message, Presence, or IQ stanzas with type safety.
///
/// Example:
/// ```dart
/// class DelayExtension extends StanzaExtension {
///   static const String extensionName = 'delay';
///   static const String extensionXmlns = 'urn:xmpp:delay';
///
///   final DateTime stamp;
///   final String? from;
///   final String? reason;
///
///   DelayExtension({required this.stamp, this.from, this.reason});
///
///   @override
///   String get name => extensionName;
///
///   @override
///   String get xmlns => extensionXmlns;
///
///   @override
///   XmlElement toXml() => xml('delay', {
///     'xmlns': xmlns,
///     'stamp': stamp.toIso8601String(),
///     if (from != null) 'from': from!,
///   }, [if (reason != null) reason!]);
///
///   factory DelayExtension.fromXml(XmlElement element) {
///     return DelayExtension(
///       stamp: DateTime.parse(element.attrs['stamp']!),
///       from: element.attrs['from'],
///       reason: element.text().isNotEmpty ? element.text() : null,
///     );
///   }
/// }
/// ```
abstract class StanzaExtension {
  const StanzaExtension();

  /// The XML element name for this extension.
  String get name;

  /// The XML namespace for this extension.
  String get xmlns;

  /// Convert this extension to an XML element.
  XmlElement toXml();

  /// The namespaced tag identifier (name:xmlns format).
  String get tag => '$name:$xmlns';

  @override
  String toString() => toXml().toString();
}

/// Registry for parsing typed extensions from XML.
///
/// Register your extension parsers to enable automatic parsing:
/// ```dart
/// ExtensionRegistry.register<DelayExtension>(
///   'delay',
///   'urn:xmpp:delay',
///   (element) => DelayExtension.fromXml(element),
/// );
/// ```
class ExtensionRegistry {
  static final Map<String, StanzaExtension Function(XmlElement)> _parsers = {};

  /// Register a parser for a typed extension.
  static void register<T extends StanzaExtension>(
    String name,
    String xmlns,
    T Function(XmlElement element) parser,
  ) {
    _parsers['$name:$xmlns'] = parser;
  }

  /// Unregister a parser.
  static void unregister(String name, String xmlns) {
    _parsers.remove('$name:$xmlns');
  }

  /// Parse an XML element into a typed extension if a parser is registered.
  static StanzaExtension? parse(XmlElement element) {
    final tag = '${element.name}:${element.getNS() ?? ''}';
    final parser = _parsers[tag];
    return parser?.call(element);
  }

  /// Check if a parser is registered for the given name and xmlns.
  static bool hasParser(String name, String xmlns) {
    return _parsers.containsKey('$name:$xmlns');
  }

  /// Clear all registered parsers.
  static void clear() {
    _parsers.clear();
  }
}
