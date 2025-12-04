import 'dart:async';

import 'package:xmpp_connection/xmpp_connection.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_iq/xmpp_iq.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_ping/xmpp_ping.dart';
import 'package:xmpp_reconnect/xmpp_reconnect.dart';
import 'package:xmpp_resource_binding/xmpp_resource_binding.dart';
import 'package:xmpp_sasl/xmpp_sasl.dart';
import 'package:xmpp_sasl_anonymous/xmpp_sasl_anonymous.dart';
import 'package:xmpp_sasl_plain/xmpp_sasl_plain.dart';
import 'package:xmpp_session_establishment/xmpp_session_establishment.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
import 'package:xmpp_stream_management/xmpp_stream_management.dart';
import 'package:xmpp_websocket/xmpp_websocket.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// XMPP Client options.
class ClientOptions {
  /// The service URL (e.g., 'wss://example.com/xmpp-websocket').
  final String service;

  /// The domain to connect to.
  final String? domain;

  /// The language for the connection.
  final String? lang;

  /// The username for authentication.
  final String? username;

  /// The password for authentication.
  final String? password;

  /// The resource to bind (optional, server will assign if not provided).
  final String? resource;

  /// If `true`, periodically send a ping to keep the connection alive.
  /// Defaults to `false`.
  final bool pingKeepAlive;

  /// The interval between keepalive pings in seconds.
  /// Defaults to 180 seconds (3 minutes).
  final int pingKeepAliveInterval;

  ClientOptions({
    required this.service,
    this.domain,
    this.lang,
    this.username,
    this.password,
    this.resource,
    this.pingKeepAlive = false,
    this.pingKeepAliveInterval = 180,
  });
}

/// Extract domain from service URL.
String? getDomain(String service) {
  final match = RegExp(r'^[a-z]+://([^/:]+)').firstMatch(service);
  return match?.group(1);
}

/// XMPP Client.
///
/// A full-featured XMPP client with WebSocket support, authentication,
/// resource binding, and stream management.
class Client extends EventEmitter {
  /// The underlying connection.
  late final WebSocketConnection _connection;

  /// The middleware manager.
  late final MiddlewareManager middleware;

  /// The stream features handler.
  late final StreamFeatures streamFeatures;

  /// The IQ caller for making requests.
  late final IQCaller iqCaller;

  /// The IQ callee for handling requests.
  late final IQCallee iqCallee;

  /// The SASL factory.
  late final SASLFactory saslFactory;

  /// The stream management instance.
  late final StreamManagement streamManagement;

  /// The reconnect handler.
  late final Reconnect reconnect;

  /// The ping handler (XEP-0199).
  late final Ping pingHandler;

  /// Client options.
  final ClientOptions options;

  /// Current connection status.
  ConnectionStatus get status => _connection.status;

  /// Current JID.
  JID? get jid => _connection.jid;

  Client(this.options) {
    final domain = options.domain ?? getDomain(options.service);

    _connection = WebSocketConnection(
      options: {
        'service': options.service,
        'domain': domain,
        'lang': options.lang,
      },
    );

    // Forward events
    _connection.on<dynamic>('status', (status) => emit('status', status));
    _connection.on<dynamic>('error', (error) => emit('error', error));
    _connection.on<XmlElement>('element', (el) => emit('element', el));
    _connection.on<XmlElement>('stanza', (el) => emit('stanza', el));
    _connection.on<XmlElement>('send', (el) => emit('send', el));
    _connection.on<dynamic>('online', (jid) => emit('online', jid));
    _connection.on<dynamic>('offline', (data) => emit('offline', data));

    // Set up middleware
    middleware = MiddlewareManager(entity: _connection);

    // Set up stream features
    streamFeatures = StreamFeatures(middleware: middleware);

    // Set up IQ handlers
    iqCaller = IQCaller(
      entity: _connection,
      middleware: middleware,
    );
    iqCaller.start();

    iqCallee = IQCallee(
      entity: _connection,
      middleware: middleware,
    );
    iqCallee.start();

    // Set up XEP-0199 ping handler
    pingHandler = ping(
      entity: _connection,
      iqCaller: iqCaller,
      iqCallee: iqCallee,
    );

    // Set up SASL
    saslFactory = SASLFactory();
    saslPlain(saslFactory);
    saslAnonymous(saslFactory);

    // Set up SASL authentication
    sasl(streamFeatures, saslFactory, _onAuthenticate);

    // Set up resource binding
    resourceBinding(streamFeatures, iqCaller, options.resource);

    // Set up session establishment (for legacy servers)
    sessionEstablishment(streamFeatures, iqCaller);

    // Set up stream management
    streamManagement = streamManagementFunc(
      entity: _connection,
      middleware: middleware,
      streamFeatures: streamFeatures,
    );

    // Set up reconnection
    reconnect = Reconnect(entity: _connection);

    // Set up ping keepalive
    if (options.pingKeepAlive) {
      _connection.on<dynamic>('online', (_) {
        pingHandler.startKeepAlive(interval: options.pingKeepAliveInterval);
      });
      _connection.on<dynamic>('offline', (_) => pingHandler.stopKeepAlive());
      _connection.on<dynamic>('disconnect', (_) => pingHandler.stopKeepAlive());
    }

    // Forward ping events
    _connection.on<dynamic>('ping:success', (_) => emit('ping:success', null));
    _connection.on<dynamic>('ping:error', (err) => emit('ping:error', err));
  }

  /// Send an XEP-0199 ping to an entity.
  ///
  /// If [to] is null, pings the server.
  /// Returns a [PingResult] with success/failure and round-trip time.
  Future<PingResult> sendPing([String? to]) => pingHandler.ping(to);

  /// SASL authentication callback.
  Future<void> _onAuthenticate(
    Future<void> Function(Map<String, dynamic> credentials, String mechanism) done,
    List<String> mechanisms,
    dynamic context,
    EventEmitter entity,
  ) async {
    // Prefer PLAIN if username/password provided
    if (options.username != null && options.password != null) {
      if (mechanisms.contains('PLAIN')) {
        await done({
          'username': options.username,
          'password': options.password,
        }, 'PLAIN');
        return;
      }
    }

    // Fall back to ANONYMOUS if available
    if (mechanisms.contains('ANONYMOUS')) {
      await done({}, 'ANONYMOUS');
      return;
    }

    throw StateError('No suitable authentication mechanism available');
  }

  /// Start the client connection.
  Future<JID?> start() async {
    reconnect.start();

    await _connection.connect(options.service);

    final domain = options.domain ?? getDomain(options.service);
    if (domain == null) {
      throw ArgumentError('Domain could not be determined from service URL');
    }

    await _connection.open(domain: domain, lang: options.lang);

    // Wait for online status
    final completer = Completer<JID?>();
    _connection.once<JID>('online', completer.complete);

    return completer.future;
  }

  /// Stop the client connection.
  Future<void> stop() async {
    pingHandler.stopKeepAlive();
    reconnect.stop();
    await _connection.stop();
  }

  /// Send an element.
  Future<void> send(XmlElement element) async {
    await _connection.send(element);
  }

  /// Send an element and wait for response.
  Future<XmlElement> sendReceive(XmlElement element, [Duration? timeout]) async {
    return _connection.sendReceive(element, timeout);
  }
}

/// Create a new XMPP client.
Client client(ClientOptions options) {
  return Client(options);
}

// Alias for stream management function to avoid name collision
StreamManagement streamManagementFunc({
  required EventEmitter entity,
  required MiddlewareManager middleware,
  StreamFeatures? streamFeatures,
}) {
  return streamManagement(
    entity: entity,
    middleware: middleware,
    streamFeatures: streamFeatures,
  );
}
