import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'extension.dart';

/// Base class for all XMPP stanzas (message, presence, iq).
///
/// Provides common attributes and functionality shared by all stanza types.
/// Supports both raw XML extensions and typed [StanzaExtension] objects.
abstract class Stanza {
  /// The underlying XML element.
  final XmlElement element;

  /// Typed extensions attached to this stanza.
  final List<StanzaExtension> _typedExtensions = [];

  /// Create a stanza from an existing XML element.
  Stanza(this.element);

  /// The stanza name (message, presence, iq).
  String get name => element.name;

  /// The stanza ID.
  String? get id => element.attrs['id'];
  set id(String? value) {
    if (value != null) {
      element.attrs['id'] = value;
    } else {
      element.attrs.remove('id');
    }
  }

  /// The recipient JID.
  JID? get to {
    final value = element.attrs['to'];
    return value != null ? JID.parse(value) : null;
  }

  set to(JID? value) {
    if (value != null) {
      element.attrs['to'] = value.toString();
    } else {
      element.attrs.remove('to');
    }
  }

  /// The sender JID.
  JID? get from {
    final value = element.attrs['from'];
    return value != null ? JID.parse(value) : null;
  }

  set from(JID? value) {
    if (value != null) {
      element.attrs['from'] = value.toString();
    } else {
      element.attrs.remove('from');
    }
  }

  /// The stanza type attribute.
  String? get type => element.attrs['type'];
  set type(String? value) {
    if (value != null) {
      element.attrs['type'] = value;
    } else {
      element.attrs.remove('type');
    }
  }

  /// The xml:lang attribute.
  String? get lang => element.attrs['xml:lang'];
  set lang(String? value) {
    if (value != null) {
      element.attrs['xml:lang'] = value;
    } else {
      element.attrs.remove('xml:lang');
    }
  }

  /// Get a child element by name and optional namespace.
  XmlElement? getChild(String name, [String? xmlns]) {
    return element.getChild(name, xmlns);
  }

  /// Get all child elements by name and optional namespace.
  List<XmlElement> getChildren(String name, [String? xmlns]) {
    return element.getChildren(name, xmlns);
  }

  /// Get text content of a child element.
  String? getChildText(String name, [String? xmlns]) {
    return element.getChildText(name, xmlns);
  }

  /// Add a child element.
  void addChild(XmlElement child) {
    element.append(child);
  }

  /// Add an extension element (with namespace).
  void addExtension(XmlElement extension) {
    element.append(extension);
  }

  /// Get extension elements by namespace.
  List<XmlElement> getExtensions(String xmlns) {
    return element.getChildElements().where((e) => e.getNS() == xmlns).toList();
  }

  /// Get a single extension element by name and namespace.
  XmlElement? getExtension(String name, String xmlns) {
    return element.getChild(name, xmlns);
  }

  // ============================================
  // Typed Extension Support
  // ============================================

  /// Add a typed extension to this stanza.
  ///
  /// The extension will be serialized to XML when [toXml] is called.
  /// ```dart
  /// message.addTypedExtension(DelayExtension(stamp: DateTime.now()));
  /// ```
  void addTypedExtension(StanzaExtension extension) {
    _typedExtensions.add(extension);
    element.append(extension.toXml());
  }

  /// Get a typed extension by its type.
  ///
  /// Returns the first extension of type [T], or null if not found.
  /// ```dart
  /// final delay = message.getTypedExtension<DelayExtension>();
  /// ```
  T? getTypedExtension<T extends StanzaExtension>() {
    for (final ext in _typedExtensions) {
      if (ext is T) return ext;
    }
    return null;
  }

  /// Get all typed extensions of a specific type.
  ///
  /// ```dart
  /// final allDelays = message.getTypedExtensions<DelayExtension>();
  /// ```
  List<T> getTypedExtensions<T extends StanzaExtension>() {
    return _typedExtensions.whereType<T>().toList();
  }

  /// Get all typed extensions.
  List<StanzaExtension> get typedExtensions => List.unmodifiable(_typedExtensions);

  /// Check if a typed extension of type [T] exists.
  bool hasTypedExtension<T extends StanzaExtension>() {
    return _typedExtensions.any((ext) => ext is T);
  }

  /// Remove a typed extension.
  ///
  /// Returns true if the extension was found and removed.
  bool removeTypedExtension(StanzaExtension extension) {
    final removed = _typedExtensions.remove(extension);
    if (removed) {
      // Also remove from XML
      final xmlExt = element.getChild(extension.name, extension.xmlns);
      if (xmlExt != null) {
        element.remove(xmlExt);
      }
    }
    return removed;
  }

  /// Remove all typed extensions of type [T].
  ///
  /// Returns the number of extensions removed.
  int removeTypedExtensions<T extends StanzaExtension>() {
    final toRemove = _typedExtensions.whereType<T>().toList();
    for (final ext in toRemove) {
      removeTypedExtension(ext);
    }
    return toRemove.length;
  }

  /// Parse and add typed extensions from XML children.
  ///
  /// Uses [ExtensionRegistry] to find parsers for child elements.
  /// Call this after creating a stanza from XML to populate typed extensions.
  void parseTypedExtensions() {
    for (final child in element.getChildElements()) {
      final parsed = ExtensionRegistry.parse(child);
      if (parsed != null) {
        _typedExtensions.add(parsed);
      }
    }
  }

  /// Copy typed extensions from another stanza.
  ///
  /// Used internally when copying stanzas. Does not add XML elements
  /// since the cloned element already contains them.
  void copyTypedExtensionsFrom(Stanza other) {
    _typedExtensions.addAll(other._typedExtensions);
  }

  /// Check if stanza has an error.
  bool get hasError => element.getChild('error') != null;

  /// Get error element if present.
  XmlElement? get error => element.getChild('error');

  /// Convert to XML element.
  XmlElement toXml() => element;

  /// Convert to XML string.
  @override
  String toString() => element.toString();

  /// Create a copy of this stanza.
  Stanza copy();
}

/// Extension methods for XmlElement to create stanzas.
extension StanzaParsing on XmlElement {
  /// Check if this element is a stanza (message, presence, or iq).
  bool get isStanza =>
      name == 'message' || name == 'presence' || name == 'iq';
}
