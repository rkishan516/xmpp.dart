import 'dart:async';
import 'event_emitter.dart';

/// Create a batch listener manager.
///
/// Allows subscribing and unsubscribing multiple event handlers at once.
///
/// Example:
/// ```dart
/// final manager = listeners({
///   'message': (data) => print('Message: $data'),
///   'error': (err) => print('Error: $err'),
///   'close': (_) => print('Closed'),
/// });
///
/// // Subscribe all listeners
/// manager.subscribe(emitter);
///
/// // Later, unsubscribe all
/// manager.unsubscribe();
/// ```
ListenerManager listeners(Map<String, void Function(dynamic)> events) {
  return ListenerManager(events);
}

/// Manages multiple event listeners as a group.
class ListenerManager {
  final Map<String, void Function(dynamic)> _events;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  ListenerManager(this._events);

  /// Subscribe all listeners to the target.
  void subscribe(EventEmitter target) {
    for (final entry in _events.entries) {
      final subscription = target.on<dynamic>(entry.key, entry.value);
      _subscriptions.add(subscription);
    }
  }

  /// Unsubscribe all listeners.
  void unsubscribe() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Check if currently subscribed.
  bool get isSubscribed => _subscriptions.isNotEmpty;
}
