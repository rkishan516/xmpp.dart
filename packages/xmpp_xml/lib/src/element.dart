import 'escape.dart';

/// An XML element.
///
/// Provides a flexible API for creating and manipulating XML elements,
/// compatible with the ltx library used by xmpp.js.
class XmlElement {
  /// The element name (tag name).
  String name;

  /// The element attributes.
  Map<String, String> attrs;

  /// The element children (XmlElement or String for text nodes).
  List<dynamic> children;

  /// The parent element.
  XmlElement? parent;

  /// Creates a new XML element.
  XmlElement(this.name, [Map<String, String>? attrs, List<dynamic>? children])
      : attrs = attrs ?? {},
        children = children ?? [];

  /// Check if the element matches a name and optional namespace.
  bool is_(String name, [String? xmlns]) {
    if (this.name != name) return false;
    if (xmlns != null && getNS() != xmlns) return false;
    return true;
  }

  /// Alias for [is_].
  bool isElement(String name, [String? xmlns]) => is_(name, xmlns);

  /// Get the namespace (xmlns attribute).
  String? getNS() => attrs['xmlns'];

  /// Set the namespace (xmlns attribute).
  void setNS(String xmlns) {
    attrs['xmlns'] = xmlns;
  }

  /// Get an attribute value.
  String? getAttr(String name) => attrs[name];

  /// Set an attribute value.
  void setAttr(String name, String value) {
    attrs[name] = value;
  }

  /// Get a child element by name and optional namespace.
  XmlElement? getChild(String name, [String? xmlns]) {
    for (final child in children) {
      if (child is XmlElement && child.is_(name, xmlns)) {
        return child;
      }
    }
    return null;
  }

  /// Get all child elements.
  List<XmlElement> getChildElements() {
    return children.whereType<XmlElement>().toList();
  }

  /// Get all child elements matching name and optional namespace.
  List<XmlElement> getChildren(String name, [String? xmlns]) {
    return children
        .whereType<XmlElement>()
        .where((c) => c.is_(name, xmlns))
        .toList();
  }

  /// Get the text content of a child element.
  String? getChildText(String name, [String? xmlns]) {
    return getChild(name, xmlns)?.text();
  }

  /// Get the text content of this element.
  String text() {
    return children.whereType<String>().join();
  }

  /// Get the text content of this element (alias for [text]).
  String getText() => text();

  /// Append text content.
  XmlElement t(String text) {
    children.add(text);
    return this;
  }

  /// Append a child element or text.
  XmlElement append(dynamic child) {
    if (child is XmlElement) {
      child.parent = this;
    }
    children.add(child);
    return this;
  }

  /// Append a child element (alias for [append]).
  XmlElement c(XmlElement child) => append(child);

  /// Prepend a child element or text.
  XmlElement prepend(dynamic child) {
    if (child is XmlElement) {
      child.parent = this;
    }
    children.insert(0, child);
    return this;
  }

  /// Remove a child element.
  bool remove(XmlElement child) {
    final removed = children.remove(child);
    if (removed) {
      child.parent = null;
    }
    return removed;
  }

  /// Clone this element.
  XmlElement clone() {
    final cloned = XmlElement(name, Map.from(attrs));
    for (final child in children) {
      if (child is XmlElement) {
        cloned.append(child.clone());
      } else {
        cloned.append(child);
      }
    }
    return cloned;
  }

  /// Serialize to XML string.
  @override
  String toString() {
    final buffer = StringBuffer();
    buffer.write('<$name');

    for (final entry in attrs.entries) {
      buffer.write(' ${entry.key}="${escapeXML(entry.value)}"');
    }

    if (children.isEmpty) {
      buffer.write('/>');
    } else {
      buffer.write('>');
      for (final child in children) {
        if (child is XmlElement) {
          buffer.write(child.toString());
        } else if (child is String) {
          buffer.write(escapeXMLText(child));
        }
      }
      buffer.write('</$name>');
    }

    return buffer.toString();
  }

  /// Get the root element (traverses up the tree).
  XmlElement get root {
    var el = this;
    while (el.parent != null) {
      el = el.parent!;
    }
    return el;
  }

  /// Find elements matching a predicate.
  List<XmlElement> find(bool Function(XmlElement) predicate) {
    final results = <XmlElement>[];
    void walk(XmlElement el) {
      if (predicate(el)) {
        results.add(el);
      }
      for (final child in el.getChildElements()) {
        walk(child);
      }
    }

    for (final child in getChildElements()) {
      walk(child);
    }
    return results;
  }
}

/// Create an XML element.
///
/// This is the main factory function for creating XML elements.
///
/// Example:
/// ```dart
/// final el = xml('message', {'to': 'user@example.com'}, [
///   xml('body', {}, ['Hello!']),
/// ]);
/// ```
XmlElement xml(String name, [Map<String, String>? attrs, List<dynamic>? children]) {
  final element = XmlElement(name, attrs);

  if (children != null) {
    for (final child in children) {
      element.append(child);
    }
  }

  return element;
}

/// Alias for [xml] function.
XmlElement createElement(String name, [Map<String, String>? attrs, List<dynamic>? children]) {
  return xml(name, attrs, children);
}
