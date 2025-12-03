import 'dart:async';

/// A Deferred represents a value that may not be available yet.
///
/// Similar to a Promise in JavaScript, but with external resolve/reject control.
/// Useful when you need to create a Future that will be completed later.
///
/// Example:
/// ```dart
/// final deferred = Deferred<String>();
///
/// // Start some async operation
/// someAsyncOperation().then((_) {
///   deferred.resolve('Success!');
/// }).catchError((error) {
///   deferred.reject(error);
/// });
///
/// // Wait for the result
/// final result = await deferred.future;
/// ```
class Deferred<T> {
  late final Completer<T> _completer;

  /// Creates a new Deferred.
  Deferred() : _completer = Completer<T>();

  /// The Future that will complete when resolve or reject is called.
  Future<T> get future => _completer.future;

  /// Whether this Deferred has been completed.
  bool get isCompleted => _completer.isCompleted;

  /// Complete the Deferred with a value.
  void resolve(T value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  /// Complete the Deferred with an error.
  void reject(Object error, [StackTrace? stackTrace]) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }
}
