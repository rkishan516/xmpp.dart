import 'dart:async';

import 'package:xmpp_error/xmpp_error.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
import 'package:xmpp_time/xmpp_time.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Stream Management namespace.
const nsSM = 'urn:xmpp:sm:3';

/// Queue item for tracking outbound stanzas.
class QueueItem {
  final XmlElement stanza;
  final String stamp;

  QueueItem(this.stanza, this.stamp);
}

/// Create an enable element.
XmlElement makeEnableElement(StreamManagement sm) {
  return xml('enable', {
    'xmlns': nsSM,
    if (sm.preferredMaximum != null) 'max': sm.preferredMaximum.toString(),
    'resume': 'true',
  }, []);
}

/// Create a resume element.
XmlElement makeResumeElement(StreamManagement sm) {
  return xml('resume', {
    'xmlns': nsSM,
    'h': sm.inbound.toString(),
    'previd': sm.id,
  }, []);
}

/// Stream Management state and event emitter.
class StreamManagement extends EventEmitter {
  /// Preferred maximum resumption time.
  int? preferredMaximum;

  /// Whether stream management is enabled.
  bool enabled = false;

  /// Whether enable has been sent.
  bool enableSent = false;

  /// The resumption ID.
  String id = '';

  /// Queue of outbound stanzas pending acknowledgement.
  List<QueueItem> outboundQueue = [];

  /// Count of outbound stanzas acknowledged.
  int outbound = 0;

  /// Count of inbound stanzas received.
  int inbound = 0;

  /// Maximum resumption time from server.
  int? max;

  /// Timeout before disconnecting (ms).
  int timeout = 60000;

  /// Interval for requesting acknowledgement (ms).
  int requestAckInterval = 30000;

  /// Debounce time for acknowledgement requests (ms).
  int requestAckDebounceMs = 250;

  Timer? _timeoutTimer;
  Timer? _requestAckTimer;
  Timer? _requestAckDebounceTimer;

  final EventEmitter entity;

  StreamManagement({required this.entity});

  /// Cancel all timers.
  void cancelTimers() {
    _timeoutTimer?.cancel();
    _requestAckTimer?.cancel();
    _requestAckDebounceTimer?.cancel();
    _timeoutTimer = null;
    _requestAckTimer = null;
    _requestAckDebounceTimer = null;
  }

  /// Send an acknowledgement.
  Future<void> sendAck() async {
    try {
      final dynamic e = entity;
      await e.send(xml('a', {'xmlns': nsSM, 'h': inbound.toString()}, []));
    } catch (_) {}
  }

  /// Process acknowledgement from server.
  void ackQueue(int h) {
    final oldOutbound = outbound;
    for (var i = 0; i < h - oldOutbound; i++) {
      if (outboundQueue.isEmpty) break;
      final item = outboundQueue.removeAt(0);
      outbound++;
      emit('ack', item.stanza);
    }
  }

  /// Fail all queued stanzas.
  void failQueue() {
    for (final item in outboundQueue) {
      emit('fail', item.stanza);
    }
    outboundQueue.clear();
    outbound = 0;
  }

  /// Reset state on disconnect.
  void reset() {
    cancelTimers();
    enabled = false;
    enableSent = false;
  }

  /// Reset state on offline.
  void offline() {
    failQueue();
    inbound = 0;
    enabled = false;
    enableSent = false;
    id = '';
  }

  /// Enable stream management with server response.
  void onEnabled(String? serverId, int? serverMax) {
    enabled = true;
    id = serverId ?? '';
    max = serverMax;
    inbound = 0;
    scheduleRequestAck();
  }

  /// Handle resumed state.
  void onResumed(int h) {
    enabled = true;
    ackQueue(h);
    emit('resumed');
    scheduleRequestAck();
  }

  /// Handle failed resumption.
  void onFailed() {
    enabled = false;
    enableSent = false;
    id = '';
    failQueue();
  }

  /// Schedule a request for acknowledgement.
  void scheduleRequestAck([int? timeout]) {
    _requestAckTimer?.cancel();
    if (!enabled) return;

    final interval = timeout ?? requestAckInterval;
    if (interval <= 0) return;

    _requestAckTimer = Timer(Duration(milliseconds: interval), requestAck);
  }

  /// Request acknowledgement from server.
  void requestAck() {
    _requestAckTimer?.cancel();
    _requestAckDebounceTimer?.cancel();

    if (!enabled) return;

    // Set up timeout
    if (timeout > 0 && _timeoutTimer == null) {
      _timeoutTimer = Timer(Duration(milliseconds: timeout), () {
        _requestAckTimer?.cancel();
        try {
          final dynamic e = entity;
          e.disconnect();
        } catch (_) {}
      });
    }

    try {
      final dynamic e = entity;
      e.send(xml('r', {'xmlns': nsSM}, []));
    } catch (_) {}

    scheduleRequestAck();
  }

  /// Queue an outbound stanza.
  void queueOutbound(XmlElement stanza) {
    outboundQueue.add(QueueItem(stanza, datetime()));

    // Debounce acknowledgement request
    _requestAckTimer?.cancel();
    _requestAckDebounceTimer?.cancel();
    _requestAckDebounceTimer = Timer(
      Duration(milliseconds: requestAckDebounceMs),
      requestAck,
    );
  }

  /// Handle incoming element.
  void handleIncoming(XmlElement stanza) {
    _timeoutTimer?.cancel();
    _timeoutTimer = null;

    final name = stanza.name;
    if (['presence', 'message', 'iq'].contains(name)) {
      inbound++;
    } else if (stanza.is_('r', nsSM)) {
      sendAck();
    } else if (stanza.is_('a', nsSM)) {
      final h = int.tryParse(stanza.attrs['h'] ?? '') ?? 0;
      ackQueue(h);
    }

    scheduleRequestAck();
  }

  /// Check if stanza should be queued.
  bool shouldQueue(XmlElement stanza) {
    if (stanza.is_('enable', nsSM)) {
      enableSent = true;
    }
    if (!enabled && !enableSent) return false;
    return ['presence', 'message', 'iq'].contains(stanza.name);
  }
}

/// Set up stream management.
StreamManagement streamManagement({
  required EventEmitter entity,
  required MiddlewareManager middleware,
  StreamFeatures? streamFeatures,
}) {
  final sm = StreamManagement(entity: entity);

  // Handle disconnect
  entity.on<dynamic>('disconnect', (_) => sm.reset());
  entity.on<dynamic>('offline', (_) => sm.offline());

  // Handle close hook if available
  try {
    final dynamic e = entity;
    e.hook('close', () async {
      if (sm.enabled) {
        await sm.sendAck();
      }
    });
  } catch (_) {}

  // Middleware for incoming stanzas
  middleware.use((ctx, next) async {
    sm.handleIncoming(ctx.stanza);
    return next();
  });

  // Middleware for outgoing stanzas
  middleware.filter((ctx, next) async {
    if (sm.shouldQueue(ctx.stanza)) {
      sm.queueOutbound(ctx.stanza);
    }
    return next();
  });

  // Stream feature handler
  if (streamFeatures != null) {
    streamFeatures.use('sm', nsSM, (ctx, next, feature) async {
      // Try to resume if we have an ID
      if (sm.id.isNotEmpty) {
        try {
          final resumed = await _resume(entity, sm);
          final h = int.tryParse(resumed.attrs['h'] ?? '') ?? 0;
          sm.onResumed(h);

          // Re-send queued stanzas
          final queue = List<QueueItem>.from(sm.outboundQueue);
          sm.outboundQueue.clear();
          for (final item in queue) {
            final dynamic e = entity;
            await e.send(item.stanza);
          }

          try {
            final dynamic e = entity;
            e.ready(resumed: true);
          } catch (_) {}

          return;
        } catch (_) {
          sm.onFailed();
        }
      }

      // Resource binding first
      await next();

      // Enable stream management
      sm.outbound = 0;

      try {
        final response = await _enable(entity, sm);
        final id = response.attrs['id'];
        final max = int.tryParse(response.attrs['max'] ?? '');
        sm.onEnabled(id, max);
      } catch (_) {
        sm.enabled = false;
        sm.enableSent = false;
      }
    });
  }

  return sm;
}

/// Enable stream management.
Future<XmlElement> _enable(EventEmitter entity, StreamManagement sm) async {
  final completer = Completer<XmlElement>();

  void handleElement(XmlElement element) {
    if (element.is_('enabled', nsSM)) {
      completer.complete(element);
    } else if (element.is_('failed', nsSM)) {
      // Extract error condition from failed element
      final children = element.getChildElements();
      final condition = children.isNotEmpty ? children.first.name : 'undefined-condition';
      completer.completeError(XMPPError(condition));
    }
  }

  final sub = entity.on<XmlElement>('element', handleElement);

  try {
    final dynamic e = entity;
    await e.send(makeEnableElement(sm));
    return await completer.future.timeout(const Duration(seconds: 30));
  } finally {
    await sub.cancel();
  }
}

/// Resume stream management.
Future<XmlElement> _resume(EventEmitter entity, StreamManagement sm) async {
  final completer = Completer<XmlElement>();

  void handleElement(XmlElement element) {
    if (element.is_('resumed', nsSM)) {
      completer.complete(element);
    } else if (element.is_('failed', nsSM)) {
      // Extract error condition from failed element
      final children = element.getChildElements();
      final condition = children.isNotEmpty ? children.first.name : 'undefined-condition';
      completer.completeError(XMPPError(condition));
    }
  }

  final sub = entity.on<XmlElement>('element', handleElement);

  try {
    final dynamic e = entity;
    await e.send(makeResumeElement(sm));
    return await completer.future.timeout(const Duration(seconds: 30));
  } finally {
    await sub.cancel();
  }
}
