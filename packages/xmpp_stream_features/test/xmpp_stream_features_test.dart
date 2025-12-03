import 'package:test/test.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_middleware/xmpp_middleware.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('StreamFeatures', () {
    test('creates with middleware', () {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);

      expect(sf, isNotNull);
      expect(sf.middleware, equals(mw));
    });

    test('calls handler for matching feature', () async {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      var handlerCalled = false;
      XmlElement? capturedFeature;

      sf.use('bind', 'urn:ietf:params:xml:ns:xmpp-bind', (ctx, next, feature) {
        handlerCalled = true;
        capturedFeature = feature;
        return next();
      });

      final features = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('bind', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-bind'}, []),
      ]);

      entity.emit('element', features);
      await Future<void>.delayed(Duration.zero);

      expect(handlerCalled, isTrue);
      expect(capturedFeature?.name, equals('bind'));
    });

    test('does not call handler for non-matching feature', () async {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      var handlerCalled = false;

      sf.use('bind', 'urn:ietf:params:xml:ns:xmpp-bind', (ctx, next, feature) {
        handlerCalled = true;
        return next();
      });

      final features = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('mechanisms', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-sasl'}, []),
      ]);

      entity.emit('element', features);
      await Future<void>.delayed(Duration.zero);

      expect(handlerCalled, isFalse);
    });

    test('does not call handler for non-features element', () async {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      var handlerCalled = false;

      sf.use('bind', 'urn:ietf:params:xml:ns:xmpp-bind', (ctx, next, feature) {
        handlerCalled = true;
        return next();
      });

      final message = xml('message', {'type': 'chat'}, [
        xml('body', {}, ['Hello']),
      ]);

      entity.emit('element', message);
      await Future<void>.delayed(Duration.zero);

      expect(handlerCalled, isFalse);
    });

    test('passes feature element to handler', () async {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      XmlElement? capturedFeature;

      sf.use('mechanisms', 'urn:ietf:params:xml:ns:xmpp-sasl', (ctx, next, feature) {
        capturedFeature = feature;
        return next();
      });

      final features = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('mechanisms', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-sasl'}, [
          xml('mechanism', {}, ['PLAIN']),
          xml('mechanism', {}, ['SCRAM-SHA-1']),
        ]),
      ]);

      entity.emit('element', features);
      await Future<void>.delayed(Duration.zero);

      expect(capturedFeature?.name, equals('mechanisms'));
      expect(capturedFeature?.getChildElements().length, equals(2));
    });

    test('multiple features handlers work correctly', () async {
      final entity = EventEmitter();
      final mw = middleware(entity: entity);
      final sf = streamFeatures(middleware: mw);
      var bindHandlerCalled = false;
      var saslHandlerCalled = false;

      sf.use('bind', 'urn:ietf:params:xml:ns:xmpp-bind', (ctx, next, feature) {
        bindHandlerCalled = true;
        return next();
      });

      sf.use('mechanisms', 'urn:ietf:params:xml:ns:xmpp-sasl', (ctx, next, feature) {
        saslHandlerCalled = true;
        return next();
      });

      // Test with bind feature
      final bindFeatures = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('bind', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-bind'}, []),
      ]);

      entity.emit('element', bindFeatures);
      await Future<void>.delayed(Duration.zero);

      expect(bindHandlerCalled, isTrue);
      expect(saslHandlerCalled, isFalse);

      // Reset
      bindHandlerCalled = false;

      // Test with sasl feature
      final saslFeatures = xml('features', {'xmlns': 'http://etherx.jabber.org/streams'}, [
        xml('mechanisms', {'xmlns': 'urn:ietf:params:xml:ns:xmpp-sasl'}, []),
      ]);

      entity.emit('element', saslFeatures);
      await Future<void>.delayed(Duration.zero);

      expect(bindHandlerCalled, isFalse);
      expect(saslHandlerCalled, isTrue);
    });
  });
}
