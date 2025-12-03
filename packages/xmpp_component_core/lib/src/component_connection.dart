import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:xmpp_connection/xmpp_connection.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Component namespace (XEP-0114).
const nsComponent = 'jabber:component:accept';

/// XMPP stream namespace.
const nsJabberStreamXmpp = 'http://etherx.jabber.org/streams';

/// XMPP Component connection (XEP-0114).
///
/// Implements the component protocol for connecting external components
/// to an XMPP server.
class ComponentConnection extends Connection {
  Socket? _socket;
  StreamSubscription<dynamic>? _subscription;

  ComponentConnection({super.options, super.timeout});

  @override
  String get ns => nsComponent;

  @override
  dynamic get socketClass => Socket;

  @override
  XmlParser Function() get parserFactory => XmlParser.new;

  @override
  dynamic createSocket() {
    // Socket is created in socketConnect
    return null;
  }

  @override
  Future<void> socketConnect(dynamic socket, Map<String, dynamic>? params) async {
    if (params == null) {
      throw ArgumentError('Connection parameters are required');
    }

    final host = params['host'] as String?;
    final port = params['port'] as int? ?? 5347;

    if (host == null) {
      throw ArgumentError('Host is required');
    }

    _socket = await Socket.connect(host, port);

    // Wrap socket in EventEmitter-like interface
    final emitter = _SocketEmitter(_socket!);
    attachSocket(emitter);

    emitter.emit('connect', null);
  }

  @override
  Future<void> socketWrite(dynamic socket, String data) async {
    _socket?.write(data);
    await _socket?.flush();
  }

  @override
  Future<void> socketEnd(dynamic socket) async {
    await _subscription?.cancel();
    await _socket?.close();
  }

  @override
  Map<String, dynamic>? socketParameters(String service) {
    final match = RegExp(r'^xmpp://([^/:]+)(?::(\d+))?').firstMatch(service);
    if (match != null) {
      final host = match.group(1);
      final port = match.group(2) != null ? int.parse(match.group(2)!) : 5347;
      return {'host': host, 'port': port};
    }
    return null;
  }

  @override
  XmlElement headerElement() {
    return xml('stream:stream', {
      'xmlns': nsComponent,
      'xmlns:stream': nsJabberStreamXmpp,
      'version': '1.0',
    }, []);
  }

  @override
  String header(XmlElement el) {
    // XML declaration + opening tag without closing />
    final str = el.toString();
    return "<?xml version='1.0'?>${str.substring(0, str.length - 2)}>";
  }

  @override
  XmlElement? footerElement() {
    return null;
  }

  @override
  String footer(XmlElement el) {
    return '</stream:stream>';
  }

  @override
  Future<void> send(XmlElement element) async {
    // All stanzas sent to the server MUST possess a 'from' attribute
    if (isStanza(element) && element.attrs['from'] == null) {
      element.attrs['from'] = jid.toString();
    }
    await super.send(element);
  }

  /// Authenticate with the server using XEP-0114 handshake.
  ///
  /// [id] is the stream ID received from the server in the stream:stream response.
  /// [password] is the shared secret configured on the server.
  Future<void> authenticate(String id, String password) async {
    // SHA-1 hash of stream ID + password
    final bytes = utf8.encode(id + password);
    final digest = sha1.convert(bytes);
    final hash = digest.toString();

    final response = await sendReceive(xml('handshake', {}, [hash]));

    if (response.name != 'handshake') {
      throw StateError('Unexpected server response: ${response.name}');
    }

    // Set the JID to the domain
    final domain = options['domain'] as String?;
    if (domain != null) {
      setJid(domain);
    }
    ready();
  }

  /// Check if this transport supports the given service URL.
  static bool canHandle(String service) {
    return RegExp(r'^xmpp://').hasMatch(service);
  }
}

/// Socket emitter wrapper.
class _SocketEmitter extends EventEmitter {
  final Socket socket;
  StreamSubscription<List<int>>? _subscription;

  _SocketEmitter(this.socket) {
    _subscription = socket.listen(
      (data) => emit('data', utf8.decode(data)),
      onError: (Object error) => emit('error', error),
      onDone: () => emit('close', null),
    );
  }

  void close() {
    _subscription?.cancel();
  }
}
