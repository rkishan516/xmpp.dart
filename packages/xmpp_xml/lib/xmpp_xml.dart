/// XML element and streaming parser for XMPP.
///
/// Provides XML element manipulation and a streaming parser
/// suitable for XMPP streams.
///
/// Example:
/// ```dart
/// // Create an element
/// final el = xml('message', {'to': 'user@example.com'}, [
///   xml('body', {}, ['Hello, World!']),
/// ]);
///
/// // Parse XML
/// final parser = XmlParser();
/// parser.on('element', (el) => print(el));
/// parser.write('<message><body>Hi</body></message>');
/// ```
library;

export 'src/element.dart';
export 'src/escape.dart';
export 'src/parser.dart';
export 'src/xml_error.dart';
