import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_reconnect/xmpp_reconnect.dart';

/// Mock entity for testing.
class MockEntity extends EventEmitter {
  String status = 'disconnect';
  Map<String, dynamic> options = {
    'service': 'xmpp://example.com',
    'domain': 'example.com',
  };
  bool connectCalled = false;
  bool openCalled = false;

  Future<void> connect(String service) async {
    connectCalled = true;
    status = 'connecting';
  }

  Future<void> open({required String domain, String? lang}) async {
    openCalled = true;
    status = 'online';
  }
}

void main() {
  group('Reconnect', () {
    test('creates with entity and delay', () {
      final entity = MockEntity();
      final r = Reconnect(entity: entity, delay: 2000);

      expect(r.entity, equals(entity));
      expect(r.delay, equals(2000));
    });

    test('default delay is 1000ms', () {
      final entity = MockEntity();
      final r = Reconnect(entity: entity);

      expect(r.delay, equals(1000));
    });

    test('schedules reconnect on disconnect', () async {
      final entity = MockEntity();
      final r = Reconnect(entity: entity, delay: 10);
      r.start();

      var reconnectingEmitted = false;
      r.on<dynamic>('reconnecting', (_) => reconnectingEmitted = true);

      entity.emit('disconnect', null);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(reconnectingEmitted, isTrue);
      expect(entity.connectCalled, isTrue);
    });

    test('emits reconnected on success', () async {
      final entity = MockEntity();
      final r = Reconnect(entity: entity, delay: 10);
      r.start();

      var reconnectedEmitted = false;
      r.on<dynamic>('reconnected', (_) => reconnectedEmitted = true);

      entity.emit('disconnect', null);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(reconnectedEmitted, isTrue);
    });

    test('stop cancels reconnection', () async {
      final entity = MockEntity();
      final r = Reconnect(entity: entity, delay: 100);
      r.start();

      entity.emit('disconnect', null);
      r.stop();

      await Future<void>.delayed(const Duration(milliseconds: 150));

      expect(entity.connectCalled, isFalse);
    });
  });

  group('reconnect function', () {
    test('creates and starts Reconnect', () async {
      final entity = MockEntity();
      final r = reconnect(entity: entity, delay: 10);

      var reconnectingEmitted = false;
      r.on<dynamic>('reconnecting', (_) => reconnectingEmitted = true);

      entity.emit('disconnect', null);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(reconnectingEmitted, isTrue);

      r.stop();
    });
  });
}
