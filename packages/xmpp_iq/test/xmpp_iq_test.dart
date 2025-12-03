import 'dart:async';

import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_iq/xmpp_iq.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

/// Mock entity for testing.
class MockEntity extends EventEmitter {
  final List<XmlElement> sentStanzas = [];
  Map<String, dynamic> options = {};

  Future<void> send(XmlElement stanza) async {
    sentStanzas.add(stanza);
    emit('send', stanza);
  }
}

void main() {
  group('IQCaller', () {
    test('isReply returns true for result', () {
      expect(isReply('iq', 'result'), isTrue);
    });

    test('isReply returns true for error', () {
      expect(isReply('iq', 'error'), isTrue);
    });

    test('isReply returns false for get', () {
      expect(isReply('iq', 'get'), isFalse);
    });

    test('isReply returns false for non-iq', () {
      expect(isReply('message', 'result'), isFalse);
    });

    test('generates ID if not provided', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final caller = iqCaller(entity: entity, middleware: mw);

      final stanza = xml('iq', {'type': 'get'}, [
        xml('query', {'xmlns': 'jabber:iq:roster'}, []),
      ]);

      // Start request - send immediately and provide a result so we don't timeout
      final requestFuture = caller.request(stanza);
      await Future<void>.delayed(Duration.zero);

      // Check the ID was generated
      expect(entity.sentStanzas.first.attrs['id'], isNotNull);
      expect(entity.sentStanzas.first.attrs['id']!.length, greaterThan(0));

      // Complete the request to avoid hanging
      final id = entity.sentStanzas.first.attrs['id']!;
      entity.emit('element', xml('iq', {'type': 'result', 'id': id}, []));
      await requestFuture;
    });

    test('resolves on result response', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final caller = iqCaller(entity: entity, middleware: mw);

      final stanza = xml('iq', {'type': 'get', 'id': 'test-1'}, [
        xml('query', {'xmlns': 'jabber:iq:roster'}, []),
      ]);

      final requestFuture = caller.request(stanza);
      await Future<void>.delayed(Duration.zero);

      // Simulate response
      final response = xml('iq', {'type': 'result', 'id': 'test-1'}, [
        xml('query', {'xmlns': 'jabber:iq:roster'}, []),
      ]);
      entity.emit('element', response);

      final result = await requestFuture;
      expect(result.attrs['type'], equals('result'));
    });

    test('rejects on error response', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final caller = iqCaller(entity: entity, middleware: mw);

      final stanza = xml('iq', {'type': 'get', 'id': 'test-2'}, [
        xml('query', {'xmlns': 'jabber:iq:roster'}, []),
      ]);

      final requestFuture = caller.request(stanza);
      await Future<void>.delayed(Duration.zero);

      // Simulate error response
      final response = xml('iq', {'type': 'error', 'id': 'test-2'}, [
        xml('error', {'type': 'cancel'}, [
          xml('item-not-found', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-stanzas'}, []),
        ]),
      ]);
      entity.emit('element', response);

      expect(requestFuture, throwsA(isA<StanzaError>()));
    });

    test('times out if no response', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final caller = iqCaller(entity: entity, middleware: mw);

      final stanza = xml('iq', {'type': 'get', 'id': 'test-3'}, [
        xml('query', {'xmlns': 'jabber:iq:roster'}, []),
      ]);

      expect(
        caller.request(stanza, const Duration(milliseconds: 50)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('get sends IQ get and returns child element', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final caller = iqCaller(entity: entity, middleware: mw);

      final queryElement = xml('query', {'xmlns': 'jabber:iq:roster'}, []);
      final getFuture = caller.get(queryElement, 'server.example.com');
      await Future<void>.delayed(Duration.zero);

      // Check sent stanza
      expect(entity.sentStanzas.first.attrs['type'], equals('get'));
      expect(entity.sentStanzas.first.attrs['to'], equals('server.example.com'));

      // Simulate response
      final id = entity.sentStanzas.first.attrs['id']!;
      final response = xml('iq', {'type': 'result', 'id': id}, [
        xml('query', {'xmlns': 'jabber:iq:roster'}, [
          xml('item', {'jid': 'alice@example.com'}, []),
        ]),
      ]);
      entity.emit('element', response);

      final result = await getFuture;
      expect(result?.name, equals('query'));
      expect(result?.getChildElements().length, equals(1));
    });
  });

  group('IQCallee', () {
    test('isQuery returns true for get', () {
      expect(isQuery('iq', 'get'), isTrue);
    });

    test('isQuery returns true for set', () {
      expect(isQuery('iq', 'set'), isTrue);
    });

    test('isQuery returns false for result', () {
      expect(isQuery('iq', 'result'), isFalse);
    });

    test('isQuery returns false for error', () {
      expect(isQuery('iq', 'error'), isFalse);
    });

    test('buildReply creates proper reply structure', () {
      final stanza = xml('iq', {
        'from': 'alice@example.com',
        'to': 'bob@example.com',
        'id': 'test-1',
        'type': 'get',
      }, []);

      final reply = buildReply(stanza);

      expect(reply.attrs['to'], equals('alice@example.com'));
      expect(reply.attrs['from'], equals('bob@example.com'));
      expect(reply.attrs['id'], equals('test-1'));
    });

    test('buildReplyResult adds type result', () {
      final stanza = xml('iq', {'id': 'test-1'}, []);
      final reply = buildReplyResult(stanza);

      expect(reply.attrs['type'], equals('result'));
    });

    test('buildReplyError adds type error', () {
      final stanza = xml('iq', {'id': 'test-1'}, []);
      final error = buildError('cancel', 'item-not-found');
      final reply = buildReplyError(stanza, error);

      expect(reply.attrs['type'], equals('error'));
      expect(reply.getChild('error'), isNotNull);
    });

    test('handles IQ get request', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      final callee = iqCallee(entity: entity, middleware: mw);
      var handlerCalled = false;

      callee.get('jabber:iq:roster', 'query', (ctx, next) async {
        handlerCalled = true;
        return xml('query', {'xmlns': 'jabber:iq:roster'}, []);
      });

      final request = xml('iq', {'type': 'get', 'id': 'test-1'}, [
        xml('query', {'xmlns': 'jabber:iq:roster'}, []),
      ]);

      entity.emit('element', request);
      await Future<void>.delayed(Duration.zero);

      expect(handlerCalled, isTrue);
    });

    test('returns service-unavailable if no handler', () async {
      final entity = MockEntity();
      final mw = middleware(entity: entity);
      iqCallee(entity: entity, middleware: mw);

      // The callee will send the error reply via entity.send
      final request = xml('iq', {'type': 'get', 'id': 'test-1'}, [
        xml('query', {'xmlns': 'some:unknown:ns'}, []),
      ]);

      entity.emit('element', request);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      // Check that a reply was sent
      final reply = entity.sentStanzas.isNotEmpty ? entity.sentStanzas.last : null;
      expect(reply?.attrs['type'], equals('error'));
      expect(reply?.getChild('error')?.getChild('service-unavailable'), isNotNull);
    });
  });
}
