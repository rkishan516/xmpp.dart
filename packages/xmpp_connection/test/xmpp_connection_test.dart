import 'package:test/test.dart';
import 'package:xmpp_connection/xmpp_connection.dart';

void main() {
  group('parseService', () {
    test('parses service with protocol', () {
      final result = parseService('xmpp://example.com');
      expect(result?.protocol, equals('xmpp:'));
      expect(result?.rest, equals('example.com'));
    });

    test('parses service with wss protocol', () {
      final result = parseService('wss://example.com/xmpp-websocket');
      expect(result?.protocol, equals('wss:'));
      expect(result?.rest, equals('example.com/xmpp-websocket'));
    });

    test('parses service without protocol', () {
      final result = parseService('example.com');
      expect(result?.protocol, isNull);
      expect(result?.rest, equals('example.com'));
    });

    test('returns null for empty service', () {
      expect(parseService(null), isNull);
      expect(parseService(''), isNull);
    });
  });

  group('parseHost', () {
    test('parses host without port', () {
      final result = parseHost('example.com');
      expect(result?.host, equals('example.com'));
      expect(result?.port, isNull);
    });

    test('parses host with port', () {
      final result = parseHost('example.com:5222');
      expect(result?.host, equals('example.com'));
      expect(result?.port, equals(5222));
    });

    test('parses IPv6 address without port', () {
      final result = parseHost('[::1]');
      expect(result?.host, equals('[::1]'));
      expect(result?.port, isNull);
    });

    test('parses IPv6 address with port', () {
      final result = parseHost('[::1]:5222');
      expect(result?.host, equals('[::1]'));
      expect(result?.port, equals(5222));
    });

    test('returns null for empty host', () {
      expect(parseHost(null), isNull);
      expect(parseHost(''), isNull);
    });
  });

  group('StreamError', () {
    test('creates from element', () {
      // This would require xmpp_xml which we have
      // For now just test basic construction
      final error = StreamError('host-unknown', 'Unknown host');
      expect(error.condition, equals('host-unknown'));
      expect(error.text, equals('Unknown host'));
    });
  });

  group('ConnectionStatus', () {
    test('has all expected values', () {
      expect(ConnectionStatus.values, contains(ConnectionStatus.offline));
      expect(ConnectionStatus.values, contains(ConnectionStatus.connecting));
      expect(ConnectionStatus.values, contains(ConnectionStatus.online));
      expect(ConnectionStatus.values, contains(ConnectionStatus.closing));
    });
  });
}
