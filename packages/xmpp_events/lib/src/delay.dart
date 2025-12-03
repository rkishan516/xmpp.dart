import 'dart:async';

/// A cancellable delay.
///
/// Creates a Future that completes after the specified duration.
/// Can be cancelled before completion.
///
/// Example:
/// ```dart
/// final delayed = delay(Duration(seconds: 5));
///
/// // Cancel the delay
/// delayed.cancel();
///
/// // Or wait for it
/// await delayed.future;
/// ```
CancellableDelay delay(Duration duration) {
  return CancellableDelay(duration);
}

/// A Future that can be cancelled.
class CancellableDelay {
  final Completer<void> _completer = Completer<void>();
  late final Timer _timer;
  bool _cancelled = false;

  CancellableDelay(Duration duration) {
    _timer = Timer(duration, () {
      if (!_cancelled && !_completer.isCompleted) {
        _completer.complete();
      }
    });
  }

  /// The Future that completes when the delay is done.
  Future<void> get future => _completer.future;

  /// Whether the delay has been cancelled.
  bool get isCancelled => _cancelled;

  /// Cancel the delay.
  ///
  /// If already completed, this has no effect.
  void cancel() {
    _cancelled = true;
    _timer.cancel();
  }
}

/// Wait for a specified duration.
///
/// Simple utility for creating delays in async code.
///
/// Example:
/// ```dart
/// await wait(Duration(seconds: 1));
/// print('One second later');
/// ```
Future<void> wait(Duration duration) {
  return Future.delayed(duration);
}

/// Execute on the next event loop iteration.
///
/// Similar to `process.nextTick()` in Node.js or `setImmediate`.
Future<void> tick() {
  return Future.microtask(() {});
}
