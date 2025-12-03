import 'dart:async';

import 'package:xmpp_component_core/xmpp_component_core.dart';
import 'package:xmpp_connection/xmpp_connection.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_iq/xmpp_iq.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_reconnect/xmpp_reconnect.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// XMPP Component options.
class ComponentOptions {
  /// The service URL (e.g., 'xmpp://component.example.com:5347').
  final String service;

  /// The domain for the component.
  final String domain;

  /// The shared secret password for authentication.
  final String password;

  ComponentOptions({
    required this.service,
    required this.domain,
    required this.password,
  });
}

/// XMPP Component.
///
/// A full-featured XMPP component with TCP support, XEP-0114 authentication,
/// IQ handling, and reconnection support.
class Component extends EventEmitter {
  /// The underlying connection.
  late final ComponentConnection _connection;

  /// The middleware manager.
  late final MiddlewareManager middleware;

  /// The IQ caller for making requests.
  late final IQCaller iqCaller;

  /// The IQ callee for handling requests.
  late final IQCallee iqCallee;

  /// The reconnect handler.
  late final Reconnect reconnect;

  /// Component options.
  final ComponentOptions options;

  /// Current connection status.
  ConnectionStatus get status => _connection.status;

  /// Current JID.
  JID? get jid => _connection.jid;

  Component(this.options) {
    _connection = ComponentConnection(
      options: {
        'service': options.service,
        'domain': options.domain,
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

    // Handle stream open for authentication
    _connection.on<dynamic>('open', _onOpen);

    // Set up middleware
    middleware = MiddlewareManager(entity: _connection);

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

    // Set up reconnection
    reconnect = Reconnect(entity: _connection);
  }

  /// Handle stream open event for authentication.
  Future<void> _onOpen(dynamic data) async {
    try {
      final el = data as XmlElement;
      final id = el.attrs['id'];
      if (id == null) {
        throw StateError('Stream ID not received from server');
      }
      await _connection.authenticate(id, options.password);
    } catch (err) {
      emit('error', err);
    }
  }

  /// Start the component connection.
  Future<JID?> start() async {
    reconnect.start();

    await _connection.connect(options.service);
    await _connection.open(domain: options.domain);

    // Wait for online status
    final completer = Completer<JID?>();
    _connection.once<JID>('online', completer.complete);

    return completer.future;
  }

  /// Stop the component connection.
  Future<void> stop() async {
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

/// Create a new XMPP component.
Component component(ComponentOptions options) {
  return Component(options);
}
