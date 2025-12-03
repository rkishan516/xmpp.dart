import 'dart:async';

import 'package:test/test.dart';
import 'package:xmpp_error/xmpp_error.dart';
import 'package:xmpp_events/xmpp_events.dart';

void main() {
  group('EventEmitter', () {
    late EventEmitter emitter;

    setUp(() {
      emitter = EventEmitter();
    });

    tearDown(() {
      emitter.dispose();
    });

    test('emits and receives events', () async {
      final completer = Completer<String>();
      emitter.on<String>('test', completer.complete);
      emitter.emit('test', 'hello');
      expect(await completer.future, equals('hello'));
    });

    test('once only fires once', () async {
      var count = 0;
      emitter.once<String>('test', (_) => count++);
      emitter.emit('test', 'first');
      emitter.emit('test', 'second');
      await tick();
      expect(count, equals(1));
    });

    test('waitFor returns first event', () async {
      Future.delayed(const Duration(milliseconds: 10), () {
        emitter.emit('test', 'value');
      });
      final result = await emitter.waitFor<String>('test');
      expect(result, equals('value'));
    });

    test('removeListener removes specific listener', () async {
      var count = 0;
      void handler(String _) => count++;

      emitter.on<String>('test', handler);
      emitter.emit('test', 'first');
      await tick();
      expect(count, equals(1));

      emitter.removeListener('test', handler);
      emitter.emit('test', 'second');
      await tick();
      expect(count, equals(1));
    });

    test('removeAllListeners removes all listeners', () {
      emitter.on<String>('a', (_) {});
      emitter.on<String>('b', (_) {});
      expect(emitter.listenerCount('a'), equals(1));
      expect(emitter.listenerCount('b'), equals(1));

      emitter.removeAllListeners();
      expect(emitter.listenerCount('a'), equals(0));
      expect(emitter.listenerCount('b'), equals(0));
    });

    test('listenerCount returns correct count', () {
      expect(emitter.listenerCount('test'), equals(0));
      emitter.on<String>('test', (_) {});
      expect(emitter.listenerCount('test'), equals(1));
      emitter.on<String>('test', (_) {});
      expect(emitter.listenerCount('test'), equals(2));
    });

    test('eventNames returns active events', () {
      expect(emitter.eventNames(), isEmpty);
      emitter.on<String>('a', (_) {});
      emitter.on<String>('b', (_) {});
      expect(emitter.eventNames(), containsAll(['a', 'b']));
    });

    test('stream provides event stream', () async {
      final events = <String>[];
      final subscription = emitter.stream<String>('test').listen(events.add);

      emitter.emit('test', 'one');
      await tick();
      emitter.emit('test', 'two');
      await tick();

      expect(events, equals(['one', 'two']));
      await subscription.cancel();
    });
  });

  group('Deferred', () {
    test('resolve completes the future', () async {
      final deferred = Deferred<String>();
      deferred.resolve('success');
      expect(await deferred.future, equals('success'));
    });

    test('reject completes with error', () async {
      final deferred = Deferred<String>();
      deferred.reject(Exception('error'));
      expect(deferred.future, throwsException);
    });

    test('isCompleted returns correct state', () {
      final deferred = Deferred<String>();
      expect(deferred.isCompleted, isFalse);
      deferred.resolve('done');
      expect(deferred.isCompleted, isTrue);
    });

    test('multiple resolve calls are ignored', () async {
      final deferred = Deferred<String>();
      deferred.resolve('first');
      deferred.resolve('second');
      expect(await deferred.future, equals('first'));
    });
  });

  group('promise', () {
    late EventEmitter emitter;

    setUp(() {
      emitter = EventEmitter();
    });

    tearDown(() {
      emitter.dispose();
    });

    test('resolves on event', () async {
      Future.delayed(const Duration(milliseconds: 10), () {
        emitter.emit('success', 'value');
      });

      final result = await promise<String>(emitter, 'success');
      expect(result, equals('value'));
    });

    test('rejects on error event', () async {
      Future.delayed(const Duration(milliseconds: 10), () {
        emitter.emit('error', Exception('test error'));
      });

      expect(
        promise<String>(emitter, 'success'),
        throwsException,
      );
    });

    test('rejects on timeout', () async {
      expect(
        promise<String>(
          emitter,
          'success',
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutError>()),
      );
    });
  });

  group('delay', () {
    test('completes after duration', () async {
      final start = DateTime.now();
      final delayed = delay(const Duration(milliseconds: 50));
      await delayed.future;
      final elapsed = DateTime.now().difference(start);
      expect(elapsed.inMilliseconds, greaterThanOrEqualTo(40));
    });

    test('can be cancelled', () async {
      final delayed = delay(const Duration(seconds: 10));
      delayed.cancel();
      expect(delayed.isCancelled, isTrue);
    });
  });

  group('timeout', () {
    test('returns value if completed in time', () async {
      final result = await timeout(
        Future.delayed(const Duration(milliseconds: 10), () => 'done'),
        const Duration(milliseconds: 100),
      );
      expect(result, equals('done'));
    });

    test('throws TimeoutError if not completed in time', () async {
      expect(
        timeout(
          Future<void>.delayed(const Duration(seconds: 10)),
          const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutError>()),
      );
    });
  });

  group('listeners', () {
    late EventEmitter emitter;

    setUp(() {
      emitter = EventEmitter();
    });

    tearDown(() {
      emitter.dispose();
    });

    test('subscribe adds all listeners', () async {
      final received = <String, dynamic>{};
      final manager = listeners({
        'a': (data) => received['a'] = data,
        'b': (data) => received['b'] = data,
      });

      manager.subscribe(emitter);
      emitter.emit('a', 1);
      emitter.emit('b', 2);
      await tick();

      expect(received, equals({'a': 1, 'b': 2}));
    });

    test('unsubscribe removes all listeners', () async {
      var count = 0;
      final manager = listeners({
        'test': (_) => count++,
      });

      manager.subscribe(emitter);
      emitter.emit('test', null);
      await tick();
      expect(count, equals(1));

      manager.unsubscribe();
      emitter.emit('test', null);
      await tick();
      expect(count, equals(1));
    });
  });

  group('tick', () {
    test('executes after current microtask', () async {
      final order = <int>[];
      order.add(1);
      await tick();
      order.add(2);
      expect(order, equals([1, 2]));
    });
  });
}
