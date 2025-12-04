import 'dart:async';

import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_iq/xmpp_iq.dart';

import 'stanza.dart';

/// Result of a ping operation.
class PingResult {
  /// Whether the ping was successful.
  final bool success;

  /// Round-trip time in milliseconds (if successful).
  final int? rtt;

  /// Error message (if failed).
  final String? error;

  PingResult.success(this.rtt)
      : success = true,
        error = null;

  PingResult.failure(this.error)
      : success = false,
        rtt = null;

  PingResult.timeout()
      : success = false,
        rtt = null,
        error = 'timeout';
}

/// XMPP Ping handler for XEP-0199.
///
/// Provides methods to send pings and handles incoming ping requests.
class Ping {
  final EventEmitter _entity;
  final IQCaller _iqCaller;
  final IQCallee _iqCallee;

  /// Timeout for ping requests.
  final Duration timeout;

  /// Ping keepalive timer.
  Timer? _keepAliveTimer;

  /// Interval for keepalive pings in seconds.
  int _keepAliveInterval = 180;

  /// Whether keepalive is enabled.
  bool _keepAliveEnabled = false;

  Ping({
    required EventEmitter entity,
    required IQCaller iqCaller,
    required IQCallee iqCallee,
    this.timeout = const Duration(seconds: 30),
  })  : _entity = entity,
        _iqCaller = iqCaller,
        _iqCallee = iqCallee;

  /// Start the ping handler.
  ///
  /// Registers middleware to handle incoming ping requests.
  void start() {
    // Handle incoming ping requests (respond with pong)
    _iqCallee.get(nsPing, 'ping', (ctx, next) async {
      // Return empty result (pong)
      return true;
    });
  }

  /// Send a ping to an entity.
  ///
  /// If [to] is null, pings the server.
  /// Returns a [PingResult] with success/failure and round-trip time.
  Future<PingResult> ping([String? to]) async {
    final startTime = DateTime.now();

    try {
      final pingStanza = PingStanza();
      await _iqCaller.get(pingStanza.toXml(), to, timeout);

      final rtt = DateTime.now().difference(startTime).inMilliseconds;
      return PingResult.success(rtt);
    } on TimeoutException {
      return PingResult.timeout();
    } catch (err) {
      return PingResult.failure(err.toString());
    }
  }

  /// Send a ping and throw on failure.
  ///
  /// Use this for simple keepalive where you just need to know if it succeeded.
  Future<void> sendPing([String? to]) async {
    final pingStanza = PingStanza();
    await _iqCaller.get(pingStanza.toXml(), to, timeout);
  }

  /// Start keepalive pings.
  ///
  /// Sends periodic pings to keep the connection alive.
  /// [interval] is the time between pings in seconds (default: 180).
  void startKeepAlive({int interval = 180}) {
    _keepAliveInterval = interval;
    _keepAliveEnabled = true;
    _scheduleKeepAlive();
  }

  /// Stop keepalive pings.
  void stopKeepAlive() {
    _keepAliveEnabled = false;
    _keepAliveTimer?.cancel();
    _keepAliveTimer = null;
  }

  /// Schedule the next keepalive ping.
  void _scheduleKeepAlive() {
    _keepAliveTimer?.cancel();
    if (!_keepAliveEnabled) return;

    _keepAliveTimer = Timer(
      Duration(seconds: _keepAliveInterval),
      _sendKeepAlive,
    );
  }

  /// Send a keepalive ping.
  Future<void> _sendKeepAlive() async {
    if (!_keepAliveEnabled) return;

    try {
      await sendPing();
      _entity.emit('ping:success', null);
    } catch (err) {
      _entity.emit('ping:error', err);
    }

    _scheduleKeepAlive();
  }
}

/// Create and set up a Ping handler.
Ping ping({
  required EventEmitter entity,
  required IQCaller iqCaller,
  required IQCallee iqCallee,
  Duration timeout = const Duration(seconds: 30),
}) {
  final p = Ping(
    entity: entity,
    iqCaller: iqCaller,
    iqCallee: iqCallee,
    timeout: timeout,
  );
  p.start();
  return p;
}
