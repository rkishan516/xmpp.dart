import 'dart:async';
import 'package:xmpp_events/xmpp_events.dart';

/// Automatic reconnection handler for XMPP connections.
class Reconnect extends EventEmitter {
  /// The entity (connection) to monitor.
  final EventEmitter entity;

  /// Delay before reconnecting (milliseconds).
  int delay;

  Timer? _timeout;
  StreamSubscription<dynamic>? _disconnectSubscription;

  Reconnect({
    required this.entity,
    this.delay = 1000,
  });

  /// Schedule a reconnection attempt.
  void scheduleReconnect() {
    _timeout?.cancel();
    _timeout = Timer(Duration(milliseconds: delay), () async {
      // Check if still disconnected
      try {
        final dynamic e = entity;
        if (e.status.toString() != 'disconnect' &&
            e.status.toString() != 'ConnectionStatus.disconnect') {
          return;
        }
      } catch (_) {
        // Can't check status, try reconnecting anyway
      }

      try {
        await reconnect();
      } catch (_) {
        // Error is emitted on entity, ignore here
      }
    });
  }

  /// Attempt to reconnect.
  Future<void> reconnect() async {
    emit('reconnecting', null);

    try {
      final dynamic e = entity;
      final options = e.options as Map<String, dynamic>;
      final service = options['service'] as String;
      final domain = options['domain'] as String;
      final lang = options['lang'] as String?;

      await e.connect(service);
      await e.open(domain: domain, lang: lang);

      emit('reconnected', null);
    } catch (err) {
      emit('error', err);
      rethrow;
    }
  }

  /// Start monitoring for disconnections.
  void start() {
    _disconnectSubscription = entity.on<dynamic>('disconnect', (_) {
      scheduleReconnect();
    });
  }

  /// Stop monitoring and cancel any pending reconnection.
  void stop() {
    _disconnectSubscription?.cancel();
    _disconnectSubscription = null;
    _timeout?.cancel();
    _timeout = null;
  }
}

/// Create and start a reconnect handler for an entity.
Reconnect reconnect({
  required EventEmitter entity,
  int delay = 1000,
}) {
  final r = Reconnect(entity: entity, delay: delay);
  r.start();
  return r;
}
