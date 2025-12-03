import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:xmpp_connection/xmpp_connection.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// XMPP WebSocket framing namespace.
const nsFraming = 'urn:ietf:params:xml:ns:xmpp-framing';

/// XMPP client namespace.
const nsClient = 'jabber:client';

/// WebSocket connection for XMPP.
///
/// Implements the WebSocket transport for XMPP as defined in RFC 7395.
class WebSocketConnection extends Connection {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  WebSocketConnection({super.options, super.timeout});

  @override
  String get ns => nsClient;

  @override
  dynamic get socketClass => WebSocketChannel;

  @override
  XmlParser Function() get parserFactory => XmlParser.new;

  @override
  dynamic createSocket() {
    // Socket is created in socketConnect
    return null;
  }

  @override
  Future<void> socketConnect(dynamic socket, Map<String, dynamic>? params) async {
    if (params == null || params['url'] == null) {
      throw ArgumentError('WebSocket URL is required');
    }

    final url = params['url'] as String;
    // RFC 7395 requires 'xmpp' subprotocol for XMPP over WebSocket
    _channel = WebSocketChannel.connect(
      Uri.parse(url),
      protocols: ['xmpp'],
    );

    // Wrap channel in EventEmitter-like interface
    final emitter = _WebSocketEmitter(_channel!);
    attachSocket(emitter);

    // Wait for connection
    await _channel!.ready;
    emitter.emit('connect', null);
  }

  @override
  Future<void> socketWrite(dynamic socket, String data) async {
    _channel?.sink.add(data);
  }

  @override
  Future<void> socketEnd(dynamic socket) async {
    await _subscription?.cancel();
    await _channel?.sink.close();
  }

  @override
  Map<String, dynamic>? socketParameters(String service) {
    if (RegExp(r'^wss?://').hasMatch(service)) {
      return {'url': service};
    }
    return null;
  }

  @override
  XmlElement headerElement() {
    // WebSocket uses <open> instead of <stream:stream>
    return xml('open', {
      'xmlns': nsFraming,
      'version': '1.0',
    }, []);
  }

  @override
  String header(XmlElement el) {
    return el.toString();
  }

  @override
  XmlElement? footerElement() {
    return xml('close', {'xmlns': nsFraming}, []);
  }

  @override
  String footer(XmlElement el) {
    return el.toString();
  }

  @override
  Future<void> send(XmlElement element) async {
    // Add default xmlns for client stanzas
    element.attrs['xmlns'] ??= ns;
    await super.send(element);
  }

  /// Check if this transport supports the given service URL.
  static bool canHandle(String service) {
    return RegExp(r'^wss?://').hasMatch(service);
  }
}

/// WebSocket emitter wrapper.
class _WebSocketEmitter extends EventEmitter {
  final WebSocketChannel channel;
  StreamSubscription<dynamic>? _subscription;

  _WebSocketEmitter(this.channel) {
    _subscription = channel.stream.listen(
      (data) => emit('data', data),
      onError: (Object error) => emit('error', error),
      onDone: () => emit('close', null),
    );
  }

  void close() {
    _subscription?.cancel();
  }
}

/// Set up WebSocket transport for an entity.
void websocket(EventEmitter entity) {
  try {
    final dynamic e = entity;
    if (e.transports is List) {
      e.transports.add(WebSocketConnection);
    }
  } catch (_) {
    // Entity doesn't support transports
  }
}
