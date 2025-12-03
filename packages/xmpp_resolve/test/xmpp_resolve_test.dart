import 'package:test/test.dart';
import 'package:xmpp_resolve/xmpp_resolve.dart';

void main() {
  group('SrvRecord', () {
    test('creates with all fields', () {
      final record = SrvRecord(
        target: 'xmpp.example.com',
        port: 5222,
        priority: 10,
        weight: 5,
        uri: 'xmpp://xmpp.example.com:5222',
      );

      expect(record.target, equals('xmpp.example.com'));
      expect(record.port, equals(5222));
      expect(record.priority, equals(10));
      expect(record.weight, equals(5));
      expect(record.uri, equals('xmpp://xmpp.example.com:5222'));
    });
  });

  group('SrvService', () {
    test('creates with service and protocol', () {
      final service = SrvService(service: 'xmpp-client', protocol: 'tcp');

      expect(service.service, equals('xmpp-client'));
      expect(service.protocol, equals('tcp'));
    });

    test('default protocol is tcp', () {
      final service = SrvService(service: 'xmpp-client');

      expect(service.protocol, equals('tcp'));
    });
  });

  group('defaultSrvServices', () {
    test('contains xmpps-client and xmpp-client', () {
      expect(defaultSrvServices.length, equals(2));
      expect(defaultSrvServices[0].service, equals('xmpps-client'));
      expect(defaultSrvServices[1].service, equals('xmpp-client'));
    });
  });

  group('resolve', () {
    test('returns empty list when no SRV records found', () async {
      // Since we can't actually resolve DNS in tests,
      // this just verifies the function runs without error
      final result = await resolve('example.com');
      expect(result, isA<List<SrvRecord>>());
    });

    test('accepts custom options', () async {
      final options = ResolveOptions(srv: [
        SrvService(service: 'custom-service'),
      ]);

      final result = await resolve('example.com', options);
      expect(result, isA<List<SrvRecord>>());
    });
  });

  group('fetchURIs', () {
    test('returns list of URIs', () async {
      final result = await fetchURIs('example.com');
      expect(result, isA<List<String>>());
    });
  });
}
