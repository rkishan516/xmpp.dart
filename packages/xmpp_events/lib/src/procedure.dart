import 'dart:async';
import 'event_emitter.dart';

/// Handler function type for procedure.
///
/// The handler receives the element and a done callback.
/// Call done(result) to complete the procedure successfully.
typedef ProcedureHandler<E, R> = FutureOr<void> Function(
  E element,
  void Function(R result) done,
);

/// Execute a multi-step protocol procedure.
///
/// This is used for SASL authentication and other multi-step protocols
/// where you need to send a stanza and then handle multiple responses.
///
/// [entity] - The event emitter to listen on
/// [stanza] - Optional initial stanza to send (if entity has a send method)
/// [handler] - Function that processes each nonza and calls done when complete
///
/// Example:
/// ```dart
/// final result = await procedure<XmlElement, String>(
///   connection,
///   authStanza,
///   (element, done) {
///     if (element.name == 'success') {
///       done('authenticated');
///     } else if (element.name == 'failure') {
///       throw SASLError.fromElement(element);
///     }
///   },
/// );
/// ```
Future<R> procedure<E, R>(
  EventEmitter entity,
  dynamic stanza,
  ProcedureHandler<E, R> handler,
) {
  final completer = Completer<R>();
  StreamSubscription<E>? subscription;

  void onError(Object err, [StackTrace? stackTrace]) {
    subscription?.cancel();
    if (!completer.isCompleted) {
      completer.completeError(err, stackTrace);
    }
  }

  void done(R result) {
    subscription?.cancel();
    if (!completer.isCompleted) {
      completer.complete(result);
    }
  }

  Future<void> listener(E element) async {
    try {
      await handler(element, done);
    } catch (err, stackTrace) {
      onError(err, stackTrace);
    }
  }

  subscription = entity.on<E>('nonza', listener);

  // Send the stanza if provided
  if (stanza != null) {
    // Check if entity has a send method (duck typing)
    try {
      final dynamic entityDynamic = entity;
      // ignore: avoid_dynamic_calls
      entityDynamic.send(stanza).catchError(onError);
    } catch (_) {
      // Entity doesn't have a send method, that's okay
    }
  }

  return completer.future;
}
