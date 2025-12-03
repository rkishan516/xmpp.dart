import 'dart:async';
import 'package:xmpp_error/xmpp_error.dart';
import 'delay.dart';

/// Add a timeout to a Future.
///
/// If the Future doesn't complete within the specified duration,
/// a [TimeoutError] is thrown.
///
/// Example:
/// ```dart
/// try {
///   final result = await timeout(
///     someAsyncOperation(),
///     Duration(seconds: 30),
///   );
/// } on TimeoutError {
///   print('Operation timed out');
/// }
/// ```
Future<T> timeout<T>(Future<T> future, Duration duration) {
  final delayedFuture = delay(duration);

  return Future.any([
    future.whenComplete(delayedFuture.cancel),
    delayedFuture.future.then((_) {
      throw TimeoutError(duration);
    }),
  ]);
}

/// Add a timeout to a Future with a custom error.
///
/// Similar to [timeout], but allows specifying a custom error.
Future<T> timeoutWithError<T>(
  Future<T> future,
  Duration duration,
  Exception error,
) {
  final delayedFuture = delay(duration);

  return Future.any([
    future.whenComplete(delayedFuture.cancel),
    delayedFuture.future.then((_) {
      throw error;
    }),
  ]);
}
