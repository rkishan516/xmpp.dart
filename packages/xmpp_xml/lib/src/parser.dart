import 'dart:async';
import 'package:xml/xml_events.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'element.dart';
import 'xml_error.dart';

/// Streaming XML parser for XMPP.
///
/// Parses XML data incrementally and emits events:
/// - `start`: When the root element opens
/// - `element`: When a complete child element is parsed
/// - `end`: When the root element closes
/// - `error`: When a parsing error occurs
///
/// Example:
/// ```dart
/// final parser = XmlParser();
///
/// parser.on<XmlElement>('element', (el) {
///   print('Received: $el');
/// });
///
/// parser.on<XmlElement>('start', (root) {
///   print('Stream started: ${root.name}');
/// });
///
/// parser.write('<stream:stream><message><body>Hi</body></message>');
/// ```
class XmlParser extends EventEmitter {
  /// The root element of the stream.
  XmlElement? root;

  /// The current element being parsed.
  XmlElement? cursor;

  final StreamController<String> _inputController = StreamController<String>();
  StreamSubscription<dynamic>? _subscription;
  String _buffer = '';

  XmlParser() {
    _setupParser();
  }

  void _setupParser() {
    // XmlEventDecoder returns List<XmlEvent> per chunk
    _subscription = _inputController.stream
        .transform(XmlEventDecoder())
        .expand<XmlEvent>((events) => events)
        .listen(
          _handleEvent,
          onError: _handleError,
        );
  }

  void _handleEvent(XmlEvent event) {
    if (event is XmlStartElementEvent) {
      _onStartElement(
        event.name,
        Map.fromEntries(event.attributes.map((a) => MapEntry(a.name, a.value))),
        event.isSelfClosing,
      );
    } else if (event is XmlEndElementEvent) {
      _onEndElement(event.name);
    } else if (event is XmlTextEvent) {
      _onText(event.value);
    } else if (event is XmlCDATAEvent) {
      _onText(event.value);
    }
  }

  void _handleError(Object error, StackTrace stackTrace) {
    emit('error', XMLError(error.toString()));
  }

  void _onStartElement(String name, Map<String, String> attrs, [bool isSelfClosing = false]) {
    final element = XmlElement(name, attrs);

    if (root == null) {
      root = element;
      emit('start', element);
      if (isSelfClosing) {
        // For self-closing root elements (like <open/> in WebSocket XMPP)
        // Don't emit 'end' - treat it as the stream opener
        cursor = root;
        return;
      }
    } else if (cursor != root) {
      cursor?.append(element);
    }

    cursor = element;

    // Handle self-closing elements (like <register/>, <starttls/>, etc.)
    if (isSelfClosing && root != null && element != root) {
      _onEndElement(name);
    }
  }

  void _onEndElement(String name) {
    if (name != cursor?.name) {
      emit('error', XMLError('${cursor?.name} must be closed, but got $name.'));
      return;
    }

    if (cursor == root) {
      emit('end', root);
      return;
    }

    if (cursor?.parent == null) {
      cursor?.parent = root;
      emit('element', cursor);
      cursor = root;
      return;
    }

    cursor = cursor?.parent;
  }

  void _onText(String str) {
    if (cursor == null) {
      emit('error', XMLError('$str must be a child.'));
      return;
    }
    cursor?.t(str);
  }

  /// Write XML data to the parser.
  void write(String data) {
    // Buffer incomplete data and only process complete chunks
    _buffer += data;

    // Try to add to the stream controller
    // The xml package's XmlEventDecoder handles incremental parsing
    try {
      _inputController.add(_buffer);
      _buffer = '';
    } catch (e) {
      // If parsing fails, keep buffering
      // This handles cases where XML is split across chunks
    }
  }

  /// End the parser.
  void end([String? data]) {
    if (data != null) {
      write(data);
    }
  }

  /// Reset the parser state.
  void reset() {
    root = null;
    cursor = null;
    _buffer = '';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _inputController.close();
    super.dispose();
  }
}

/// Static reference to XMLError for compatibility.
// ignore: constant_identifier_names
const ParserXMLError = XMLError;
