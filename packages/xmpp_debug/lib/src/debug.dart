import 'dart:async';
import 'dart:io';

import 'package:talker/talker.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'sensitive.dart';

/// Custom log for incoming XMPP elements.
class XmppInLog extends TalkerLog {
  XmppInLog(super.message);

  @override
  String get title => 'XMPP IN';

  @override
  AnsiPen get pen => AnsiPen()..green();
}

/// Custom log for outgoing XMPP elements.
class XmppOutLog extends TalkerLog {
  XmppOutLog(super.message);

  @override
  String get title => 'XMPP OUT';

  @override
  AnsiPen get pen => AnsiPen()..blue();
}

/// Custom log for XMPP status changes.
class XmppStatusLog extends TalkerLog {
  XmppStatusLog(super.message);

  @override
  String get title => 'XMPP STATUS';

  @override
  AnsiPen get pen => AnsiPen()..yellow();
}

/// Debug logger for XMPP connections.
///
/// Logs incoming/outgoing XML elements, errors, and status changes.
/// Sensitive data (authentication) is automatically hidden.
class XmppDebug {
  /// The entity (client/component) being debugged.
  final EventEmitter entity;

  /// The Talker logger instance.
  final Talker talker;

  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Create a debug logger for an XMPP entity.
  ///
  /// [entity] - The XMPP client or component to debug.
  /// [talker] - Optional custom Talker instance. If not provided, a default
  ///            logger with XMPP prefix is created.
  XmppDebug({
    required this.entity,
    Talker? talker,
  }) : talker = talker ??
            Talker(
              settings: TalkerSettings(
                useConsoleLogs: true,
                useHistory: true,
              ),
            );

  /// Start logging.
  void start() {
    // Log incoming elements
    _subscriptions.add(
      entity.on<XmlElement>('element', (element) {
        talker.logCustom(XmppInLog(formatElement(element)));
      }),
    );

    // Log outgoing elements
    _subscriptions.add(
      entity.on<XmlElement>('send', (element) {
        talker.logCustom(XmppOutLog(formatElement(element)));
      }),
    );

    // Log errors
    _subscriptions.add(
      entity.on<dynamic>('error', (error) {
        if (error is Exception) {
          talker.handle(error);
        } else {
          talker.error('XMPP Error: $error');
        }
      }),
    );

    // Log status changes
    _subscriptions.add(
      entity.on<dynamic>('status', (status) {
        talker.logCustom(XmppStatusLog(status.toString()));
      }),
    );
  }

  /// Stop logging.
  void stop() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  /// Dispose the debug logger.
  void dispose() {
    stop();
  }
}

/// Enable debug logging for an XMPP entity.
///
/// Debug logging is enabled when:
/// - [force] is true, OR
/// - The environment variable `XMPP_DEBUG` is set
///
/// Example:
/// ```dart
/// final client = Client(options);
/// debug(client); // Only logs if XMPP_DEBUG env var is set
/// debug(client, force: true); // Always logs
/// ```
XmppDebug? debug(
  EventEmitter entity, {
  bool? force,
  Talker? talker,
}) {
  final shouldDebug = force ?? _isDebugEnabled();

  if (shouldDebug) {
    final debugger = XmppDebug(entity: entity, talker: talker);
    debugger.start();
    return debugger;
  }

  return null;
}

/// Check if XMPP_DEBUG environment variable is set.
bool _isDebugEnabled() {
  try {
    return Platform.environment.containsKey('XMPP_DEBUG');
  } catch (_) {
    // Platform.environment may not be available in all environments
    return false;
  }
}
