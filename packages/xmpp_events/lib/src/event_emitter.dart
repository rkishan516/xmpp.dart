import 'dart:async';

/// A Node.js-style EventEmitter implemented using Dart Streams.
///
/// Provides a familiar API for event-based programming while leveraging
/// Dart's native Stream capabilities.
///
/// Example:
/// ```dart
/// final emitter = EventEmitter();
///
/// // Subscribe to an event
/// emitter.on('message', (data) {
///   print('Received: $data');
/// });
///
/// // Emit an event
/// emitter.emit('message', 'Hello, World!');
///
/// // Clean up
/// emitter.dispose();
/// ```
class EventEmitter {
  final Map<String, StreamController<dynamic>> _controllers = {};
  final Map<String, List<_ListenerEntry>> _listeners = {};

  /// Subscribe to an event.
  ///
  /// Returns a [StreamSubscription] that can be used to cancel the subscription.
  StreamSubscription<T> on<T>(String event, void Function(T) handler) {
    _controllers[event] ??= StreamController<dynamic>.broadcast();
    final subscription = _controllers[event]!.stream.cast<T>().listen(handler);

    // Track the listener for removeListener
    _listeners[event] ??= [];
    _listeners[event]!.add(_ListenerEntry(handler, subscription));

    return subscription;
  }

  /// Subscribe to an event once.
  ///
  /// The handler will be automatically removed after the first event.
  StreamSubscription<T> once<T>(String event, void Function(T) handler) {
    late StreamSubscription<T> subscription;
    subscription = on<T>(event, (data) {
      subscription.cancel();
      _removeListenerEntry(event, subscription);
      handler(data);
    });
    return subscription;
  }

  /// Wait for the next occurrence of an event.
  ///
  /// Returns a Future that completes with the event data.
  Future<T> waitFor<T>(String event) {
    _controllers[event] ??= StreamController<dynamic>.broadcast();
    return _controllers[event]!.stream.cast<T>().first;
  }

  /// Emit an event with optional data.
  void emit(String event, [dynamic data]) {
    _controllers[event]?.add(data);
  }

  /// Remove a specific listener.
  void removeListener(String event, Function handler) {
    final entries = _listeners[event];
    if (entries == null) return;

    for (var i = entries.length - 1; i >= 0; i--) {
      if (entries[i].handler == handler) {
        entries[i].subscription.cancel();
        entries.removeAt(i);
        break;
      }
    }
  }

  void _removeListenerEntry(String event, StreamSubscription<dynamic> subscription) {
    final entries = _listeners[event];
    if (entries == null) return;

    entries.removeWhere((e) => e.subscription == subscription);
  }

  /// Remove all listeners for a specific event.
  void removeAllListeners([String? event]) {
    if (event != null) {
      final entries = _listeners[event];
      if (entries != null) {
        for (final entry in entries) {
          entry.subscription.cancel();
        }
        entries.clear();
      }
      _controllers[event]?.close();
      _controllers.remove(event);
      _listeners.remove(event);
    } else {
      for (final event in _listeners.keys.toList()) {
        removeAllListeners(event);
      }
    }
  }

  /// Get the number of listeners for an event.
  int listenerCount(String event) {
    return _listeners[event]?.length ?? 0;
  }

  /// Get all event names that have listeners.
  List<String> eventNames() {
    return _listeners.keys.where((e) => _listeners[e]!.isNotEmpty).toList();
  }

  /// Get a stream for an event.
  ///
  /// Useful when you want to use Stream operators.
  Stream<T> stream<T>(String event) {
    _controllers[event] ??= StreamController<dynamic>.broadcast();
    return _controllers[event]!.stream.cast<T>();
  }

  /// Dispose of all resources.
  ///
  /// After calling this, the EventEmitter should not be used.
  void dispose() {
    for (final entries in _listeners.values) {
      for (final entry in entries) {
        entry.subscription.cancel();
      }
    }
    _listeners.clear();

    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}

class _ListenerEntry {
  final dynamic handler;
  final StreamSubscription<dynamic> subscription;

  _ListenerEntry(this.handler, this.subscription);
}
