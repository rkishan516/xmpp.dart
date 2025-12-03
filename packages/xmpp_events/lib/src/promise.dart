import 'dart:async';
import 'package:xmpp_error/xmpp_error.dart';
import 'event_emitter.dart';

/// Convert an event to a Future.
///
/// Waits for the specified [event] to be emitted on [target].
/// Optionally, can reject on a [rejectEvent] (defaults to 'error').
/// Can also specify a [timeout] duration.
///
/// Example:
/// ```dart
/// final result = await promise(
///   emitter,
///   'online',
///   rejectEvent: 'error',
///   timeout: Duration(seconds: 30),
/// );
/// ```
Future<T> promise<T>(
  EventEmitter target,
  String event, {
  String? rejectEvent = 'error',
  Duration? timeout,
}) {
  final completer = Completer<T>();

  StreamSubscription<T>? eventSub;
  StreamSubscription<dynamic>? errorSub;
  Timer? timeoutTimer;

  void cleanup() {
    eventSub?.cancel();
    errorSub?.cancel();
    timeoutTimer?.cancel();
  }

  void onEvent(T value) {
    if (!completer.isCompleted) {
      cleanup();
      completer.complete(value);
    }
  }

  void onError(dynamic error) {
    if (!completer.isCompleted) {
      cleanup();
      completer.completeError(error is Exception ? error : Exception(error.toString()));
    }
  }

  eventSub = target.on<T>(event, onEvent);

  if (rejectEvent != null) {
    errorSub = target.on<dynamic>(rejectEvent, onError);
  }

  if (timeout != null) {
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        cleanup();
        completer.completeError(TimeoutError(timeout));
      }
    });
  }

  return completer.future;
}

/// Wait for any of multiple events.
///
/// Returns a record containing the event name and the value.
Future<({String event, T value})> promiseAny<T>(
  EventEmitter target,
  List<String> events, {
  String? rejectEvent = 'error',
  Duration? timeout,
}) {
  final completer = Completer<({String event, T value})>();
  final subscriptions = <StreamSubscription<dynamic>>[];
  Timer? timeoutTimer;

  void cleanup() {
    for (final sub in subscriptions) {
      sub.cancel();
    }
    timeoutTimer?.cancel();
  }

  for (final event in events) {
    final sub = target.on<T>(event, (value) {
      if (!completer.isCompleted) {
        cleanup();
        completer.complete((event: event, value: value));
      }
    });
    subscriptions.add(sub);
  }

  if (rejectEvent != null) {
    final sub = target.on<dynamic>(rejectEvent, (error) {
      if (!completer.isCompleted) {
        cleanup();
        completer.completeError(error is Exception ? error : Exception(error.toString()));
      }
    });
    subscriptions.add(sub);
  }

  if (timeout != null) {
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        cleanup();
        completer.completeError(TimeoutError(timeout));
      }
    });
  }

  return completer.future;
}
