import 'package:test/test.dart';
import 'package:xmpp_websocket/xmpp_websocket.dart';

void main() {
  group('WebSocketConnection', () {
    test('has correct namespace', () {
      final conn = WebSocketConnection();
      expect(conn.ns, equals('jabber:client'));
    });

    test('socketParameters returns url for ws://', () {
      final conn = WebSocketConnection();
      final params = conn.socketParameters('ws://example.com/xmpp-websocket');

      expect(params, isNotNull);
      expect(params!['url'], equals('ws://example.com/xmpp-websocket'));
    });

    test('socketParameters returns url for wss://', () {
      final conn = WebSocketConnection();
      final params = conn.socketParameters('wss://example.com/xmpp-websocket');

      expect(params, isNotNull);
      expect(params!['url'], equals('wss://example.com/xmpp-websocket'));
    });

    test('socketParameters returns null for non-websocket', () {
      final conn = WebSocketConnection();
      final params = conn.socketParameters('xmpp://example.com');

      expect(params, isNull);
    });

    test('headerElement creates open element', () {
      final conn = WebSocketConnection();
      final header = conn.headerElement();

      expect(header.name, equals('open'));
      expect(header.attrs['xmlns'], equals(nsFraming));
    });

    test('footerElement creates close element', () {
      final conn = WebSocketConnection();
      final footer = conn.footerElement();

      expect(footer?.name, equals('close'));
      expect(footer?.attrs['xmlns'], equals(nsFraming));
    });

    test('canHandle returns true for WebSocket URLs', () {
      expect(WebSocketConnection.canHandle('ws://example.com'), isTrue);
      expect(WebSocketConnection.canHandle('wss://example.com'), isTrue);
      expect(WebSocketConnection.canHandle('xmpp://example.com'), isFalse);
    });
  });

  group('nsFraming', () {
    test('has correct value', () {
      expect(nsFraming, equals('urn:ietf:params:xml:ns:xmpp-framing'));
    });
  });

  group('nsClient', () {
    test('has correct value', () {
      expect(nsClient, equals('jabber:client'));
    });
  });
}
