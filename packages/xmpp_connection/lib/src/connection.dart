import 'dart:async';

import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'stream_error.dart';
import 'util.dart';

/// XMPP stream namespace
const nsStream = 'urn:ietf:params:xml:ns:xmpp-streams';
const nsJabberStream = 'http://etherx.jabber.org/streams';

/// Connection status values
enum ConnectionStatus {
  offline,
  connecting,
  connect,
  opening,
  open,
  online,
  closing,
  close,
  disconnecting,
  disconnect,
}

/// Base XMPP connection class.
///
/// Implements the connection state machine and provides methods for
/// connecting, sending, and receiving XMPP stanzas.
///
/// This is an abstract class that must be extended with specific
/// transport implementations (TCP, WebSocket, etc.).
abstract class Connection extends EventEmitter {
  /// The current JID (set after authentication).
  JID? jid;

  /// Connection timeout duration.
  Duration timeout;

  /// Connection options.
  Map<String, dynamic> options;

  /// Current connection status.
  ConnectionStatus status = ConnectionStatus.offline;

  /// The underlying socket.
  dynamic socket;

  /// The XML parser.
  XmlParser? parser;

  /// The root stream element.
  XmlElement? root;

  /// Namespace for this connection type.
  String get ns;

  /// Socket class to use.
  dynamic get socketClass;

  /// Parser class to use.
  XmlParser Function() get parserFactory;

  ListenerManager? _socketListeners;
  ListenerManager? _parserListeners;
  final Map<String, Set<List<Future<void> Function()>>> _hooks = {};
  final Set<String> _hookEvents = {'close'};

  Connection({Map<String, dynamic>? options, Duration? timeout})
      : options = options ?? {},
        timeout = timeout ?? const Duration(seconds: 2);

  /// Check if the connection is secure (TLS).
  bool isSecure() => false;

  /// Update the connection status.
  void _status(ConnectionStatus newStatus, [dynamic args]) {
    if (status == newStatus) return;
    status = newStatus;
    emit('status', newStatus);
    emit(newStatus.name, args);
  }

  /// Set the JID.
  JID setJid(String id) {
    jid = JID.parse(id);
    return jid!;
  }

  /// Mark connection as ready/online.
  void ready({bool resumed = false}) {
    if (resumed) {
      status = ConnectionStatus.online;
    } else {
      _status(ConnectionStatus.online, jid);
    }
  }

  /// Handle incoming data from socket.
  void _onData(dynamic data) {
    final str = data is String ? data : String.fromCharCodes(data as List<int>);
    parser?.write(str);
  }

  /// Handle parser error.
  void _onParserError(dynamic error) {
    _streamError('bad-format');
    _detachParser();
    emit('error', error);
  }

  /// Handle socket closed.
  void _onSocketClosed([bool dirty = false, dynamic reason]) {
    _detachSocket();
    _status(ConnectionStatus.disconnect, {'clean': !dirty, 'reason': reason});
  }

  /// Handle stream closed.
  void _onStreamClosed([bool dirty = false, dynamic reason]) {
    _detachParser();
    _status(ConnectionStatus.close, {'clean': !dirty, 'reason': reason});
  }

  /// Handle incoming element.
  void _onElement(XmlElement element) {
    final isStreamError = element.is_('error', nsJabberStream);

    if (isStreamError) {
      _onStreamError(element);
    }

    emit('element', element);
    emit(isStanza(element) ? 'stanza' : 'nonza', element);

    if (isStreamError) {
      disconnect();
    }
  }

  /// Handle stream error.
  void _onStreamError(XmlElement element) {
    final error = StreamError.fromElement(element);

    if (error.condition == 'see-other-host') {
      _onSeeOtherHost(error, element);
      return;
    }

    emit('error', error);
  }

  /// Handle see-other-host redirect.
  Future<void> _onSeeOtherHost(StreamError error, XmlElement element) async {
    final protocol = parseService(options['service'] as String?)?.protocol;
    final host = element.getChildText('see-other-host');

    if (host == null) return;

    final parsedHost = parseHost(host);
    final port = parsedHost?.port;

    String service;
    if (port != null) {
      service = '${protocol ?? "xmpp:"}//$host';
    } else {
      service = (protocol != null ? '$protocol//' : '') + host;
    }

    try {
      await promise<dynamic>(this, 'disconnect');
      final domain = options['domain'] as String?;
      final lang = options['lang'] as String?;
      await connect(service);
      await open(domain: domain!, lang: lang);
    } catch (err) {
      emit('error', err);
    }
  }

  /// Attach socket listeners.
  /// This method is protected for use by subclasses.
  void attachSocket(dynamic socket) {
    this.socket = socket;
    _socketListeners ??= listeners({
      'data': _onData,
      'close': (dynamic _) => _onSocketClosed(),
      'connect': (dynamic _) => _status(ConnectionStatus.connect),
      'error': (dynamic error) => emit('error', error),
    });
    _socketListeners!.subscribe(socket as EventEmitter);
  }

  /// Detach socket listeners.
  void _detachSocket() {
    if (socket != null && _socketListeners != null) {
      _socketListeners!.unsubscribe();
    }
    socket = null;
  }

  /// Attach parser listeners.
  void _attachParser(XmlParser parser) {
    this.parser = parser;
    _parserListeners ??= listeners({
      'element': (dynamic el) => _onElement(el as XmlElement),
      'error': _onParserError,
      'end': (dynamic _) => _onStreamClosed(),
      'start': (dynamic element) => _status(ConnectionStatus.open, element),
    });
    _parserListeners!.subscribe(parser);
  }

  /// Detach parser listeners.
  void _detachParser() {
    if (parser != null && _parserListeners != null) {
      _parserListeners!.unsubscribe();
    }
    parser = null;
    root = null;
  }

  /// Send a stream error and disconnect.
  Future<void> _streamError(String condition,
      [List<XmlElement>? children]) async {
    try {
      await send(xml('stream:error', {}, [
        xml(condition, {'xmlns': nsStream}, children),
      ]));
    } catch (_) {}
    await disconnect();
  }

  /// Connect to the service.
  Future<void> connect(String service) async {
    _status(ConnectionStatus.connecting, service);
    final newSocket = createSocket();
    // Only attach socket if createSocket returns a non-null socket
    // WebSocket connections create and attach socket in socketConnect instead
    if (newSocket != null) {
      attachSocket(newSocket);
    }
    await socketConnect(newSocket, socketParameters(service));
  }

  /// Open the stream.
  Future<XmlElement> open({required String domain, String? lang}) async {
    _status(ConnectionStatus.opening);

    final headerElement = this.headerElement();
    headerElement.attrs['to'] = domain;
    if (lang != null) {
      headerElement.attrs['xml:lang'] = lang;
    }
    root = headerElement;

    _attachParser(parserFactory());

    await write(header(headerElement));
    return promise<XmlElement>(this, 'open', timeout: timeout);
  }

  /// Start the connection (connect + open + wait for online).
  Future<JID> start() async {
    if (status != ConnectionStatus.offline) {
      throw StateError('Connection is not offline');
    }

    final service = options['service'] as String;
    final domain = options['domain'] as String;
    final lang = options['lang'] as String?;

    await connect(service);

    final onlineCompleter = Completer<JID>();
    once<JID>('online', onlineCompleter.complete);

    await open(domain: domain, lang: lang);

    return onlineCompleter.future;
  }

  /// Stop the connection.
  Future<XmlElement?> stop() async {
    final el = await disconnect();
    _status(ConnectionStatus.offline, el);
    return el;
  }

  /// Disconnect (close stream + close socket).
  Future<XmlElement?> disconnect() async {
    XmlElement? el;

    try {
      el = await _closeStream();
    } catch (err) {
      _onStreamClosed(true, err);
    }

    try {
      await _closeSocket();
    } catch (err) {
      _onSocketClosed(true, err);
    }

    return el;
  }

  /// Close the stream.
  Future<XmlElement?> _closeStream() async {
    await _runHooks('close');

    final footerEl = footerElement();
    if (footerEl != null) {
      await write(footer(footerEl));
    }
    _status(ConnectionStatus.closing);
    return promise<XmlElement?>(parser!, 'end', timeout: timeout);
  }

  /// Close the socket.
  Future<void> _closeSocket() async {
    _status(ConnectionStatus.disconnecting);
    await socketEnd(socket);
  }

  /// Restart the stream.
  Future<XmlElement> restart() async {
    _detachParser();
    final domain = options['domain'] as String;
    final lang = options['lang'] as String?;
    return open(domain: domain, lang: lang);
  }

  /// Send an element.
  Future<void> send(XmlElement element) async {
    element.parent = root;
    await write(element.toString());
    emit('send', element);
  }

  /// Send an element and wait for response.
  Future<XmlElement> sendReceive(XmlElement element,
      [Duration? timeout]) async {
    timeout ??= this.timeout;
    final responseFuture =
        promise<XmlElement>(this, 'element', timeout: timeout);
    await send(element);
    return responseFuture;
  }

  /// Write raw data to socket.
  Future<void> write(String data) async {
    if (status == ConnectionStatus.closing) {
      throw StateError('Connection is closing');
    }
    await socketWrite(socket, data);
  }

  /// Check if element is a stanza.
  bool isStanza(XmlElement element) {
    final name = element.name;
    return name == 'iq' || name == 'message' || name == 'presence';
  }

  /// Check if element is a nonza.
  bool isNonza(XmlElement element) => !isStanza(element);

  // Hook system
  void hook(String event, Future<void> Function() handler) {
    _assertHookEventName(event);
    _hooks[event] ??= {};
    _hooks[event]!.add([handler]);
  }

  void unhook(String event, Future<void> Function() handler) {
    _assertHookEventName(event);
    final handlers = _hooks[event];
    if (handlers == null) return;
    handlers.removeWhere((item) => item.first == handler);
  }

  void _assertHookEventName(String event) {
    if (!_hookEvents.contains(event)) {
      throw ArgumentError('Hook event name "$event" is unknown.');
    }
  }

  Future<void> _runHooks(String event) async {
    _assertHookEventName(event);
    final hooks = _hooks[event];
    if (hooks == null) return;

    await Future.wait(hooks.map((handlerList) async {
      try {
        await handlerList.first();
      } catch (err) {
        emit('error', err);
      }
    }));
  }

  // Abstract methods to override in subclasses
  dynamic createSocket();
  Future<void> socketConnect(dynamic socket, Map<String, dynamic>? params);
  Future<void> socketWrite(dynamic socket, String data);
  Future<void> socketEnd(dynamic socket);
  Map<String, dynamic>? socketParameters(String service);
  XmlElement headerElement();
  String header(XmlElement el);
  XmlElement? footerElement();
  String footer(XmlElement el);
}
