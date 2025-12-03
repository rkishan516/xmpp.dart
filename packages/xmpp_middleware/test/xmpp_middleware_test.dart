import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('compose', () {
    test('executes middleware in order', () async {
      final order = <int>[];

      Future<void> middleware1(Context ctx, Future<dynamic> Function() next) async {
        order.add(1);
        await next();
        order.add(4);
      }

      Future<void> middleware2(Context ctx, Future<dynamic> Function() next) async {
        order.add(2);
        await next();
        order.add(3);
      }

      final entity = EventEmitter();
      final stanza = xml('message', {'type': 'chat'}, []);
      final ctx = Context(entity, stanza);

      final composed = compose<Context>([middleware1, middleware2]);
      await composed(ctx, () async => null);

      expect(order, equals([1, 2, 3, 4]));
    });

    test('passes context to all middleware', () async {
      String? capturedName;
      String? capturedType;

      Future<dynamic> middleware1(Context ctx, Future<dynamic> Function() next) async {
        capturedName = ctx.name;
        return next();
      }

      Future<dynamic> middleware2(Context ctx, Future<dynamic> Function() next) async {
        capturedType = ctx.type;
        return next();
      }

      final entity = EventEmitter();
      final stanza = xml('iq', {'type': 'get', 'id': '123'}, []);
      final ctx = Context(entity, stanza);

      final composed = compose<Context>([middleware1, middleware2]);
      await composed(ctx, () async => null);

      expect(capturedName, equals('iq'));
      expect(capturedType, equals('get'));
    });

    test('stops if next is not called', () async {
      final order = <int>[];

      Future<void> middleware1(Context ctx, Future<dynamic> Function() next) async {
        order.add(1);
        // Not calling next()
      }

      Future<dynamic> middleware2(Context ctx, Future<dynamic> Function() next) async {
        order.add(2);
        return next();
      }

      final entity = EventEmitter();
      final stanza = xml('message', {}, []);
      final ctx = Context(entity, stanza);

      final composed = compose<Context>([middleware1, middleware2]);
      await composed(ctx, () async => null);

      expect(order, equals([1]));
    });

    test('returns value from middleware', () async {
      Future<String> middleware1(Context ctx, Future<dynamic> Function() next) async {
        return 'result';
      }

      final entity = EventEmitter();
      final stanza = xml('message', {}, []);
      final ctx = Context(entity, stanza);

      final composed = compose<Context>([middleware1]);
      final result = await composed(ctx, () async => null);

      expect(result, equals('result'));
    });
  });

  group('Context', () {
    test('extracts name and type from stanza', () {
      final entity = EventEmitter();
      final stanza = xml('iq', {'type': 'result', 'id': 'abc'}, []);
      final ctx = Context(entity, stanza);

      expect(ctx.name, equals('iq'));
      expect(ctx.type, equals('result'));
      expect(ctx.id, equals('abc'));
    });

    test('defaults message type to normal', () {
      final entity = EventEmitter();
      final stanza = xml('message', {}, []);
      final ctx = Context(entity, stanza);

      expect(ctx.type, equals('normal'));
    });

    test('defaults presence type to available', () {
      final entity = EventEmitter();
      final stanza = xml('presence', {}, []);
      final ctx = Context(entity, stanza);

      expect(ctx.type, equals('available'));
    });

    test('defaults other stanza types to empty string', () {
      final entity = EventEmitter();
      final stanza = xml('iq', {}, []);
      final ctx = Context(entity, stanza);

      expect(ctx.type, equals(''));
    });
  });

  group('IncomingContext', () {
    test('extracts from and to JIDs', () {
      final entity = EventEmitter();
      final stanza = xml('message', {
        'from': 'alice@example.com/res',
        'to': 'bob@example.com',
      }, []);
      final ctx = IncomingContext(entity, stanza);

      expect(ctx.from?.toString(), equals('alice@example.com/res'));
      expect(ctx.to?.toString(), equals('bob@example.com'));
      expect(ctx.local, equals('alice'));
      expect(ctx.domain, equals('example.com'));
      expect(ctx.resource, equals('res'));
    });
  });

  group('OutgoingContext', () {
    test('extracts from and to JIDs', () {
      final entity = EventEmitter();
      final stanza = xml('message', {
        'from': 'bob@example.com',
        'to': 'alice@example.com/mobile',
      }, []);
      final ctx = OutgoingContext(entity, stanza);

      expect(ctx.from?.toString(), equals('bob@example.com'));
      expect(ctx.to?.toString(), equals('alice@example.com/mobile'));
      expect(ctx.local, equals('alice'));
      expect(ctx.domain, equals('example.com'));
      expect(ctx.resource, equals('mobile'));
    });
  });

  group('StanzaError', () {
    test('creates with condition and type', () {
      final error = StanzaError('item-not-found', type: 'cancel');
      expect(error.condition, equals('item-not-found'));
      expect(error.type, equals('cancel'));
    });

    test('defaults type to cancel', () {
      final error = StanzaError('forbidden');
      expect(error.type, equals('cancel'));
    });

    test('creates from element', () {
      final element = xml('error', {'type': 'modify'}, [
        xml('bad-request', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-stanzas'}, []),
        xml('text', {}, ['Invalid data']),
      ]);
      final error = StanzaError.fromElement(element);

      expect(error.condition, equals('bad-request'));
      expect(error.text, equals('Invalid data'));
      expect(error.type, equals('modify'));
    });

    test('types list is valid', () {
      expect(StanzaError.types, containsAll(['auth', 'cancel', 'modify', 'wait']));
    });

    test('conditions list is not empty', () {
      expect(StanzaError.conditions, isNotEmpty);
      expect(StanzaError.conditions, contains('bad-request'));
      expect(StanzaError.conditions, contains('item-not-found'));
    });
  });

  group('MiddlewareManager', () {
    test('creates with entity', () {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      expect(mw, isNotNull);
    });

    test('use adds incoming middleware', () async {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      var called = false;

      mw.use((ctx, next) async {
        called = true;
        return next();
      });

      entity.emit('element', xml('message', {}, []));
      await Future<void>.delayed(Duration.zero);

      expect(called, isTrue);
    });

    test('filter adds outgoing middleware', () async {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      var called = false;

      mw.filter((ctx, next) async {
        called = true;
        return next();
      });

      entity.emit('send', xml('message', {}, []));
      await Future<void>.delayed(Duration.zero);

      expect(called, isTrue);
    });
  });
}
