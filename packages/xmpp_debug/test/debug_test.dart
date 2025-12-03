import 'package:talker/talker.dart';
import 'package:test/test.dart';
import 'package:xmpp_debug/xmpp_debug.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('XmppInLog', () {
    test('has correct title', () {
      final log = XmppInLog('test message');
      expect(log.title, equals('XMPP IN'));
    });

    test('has green pen color', () {
      final log = XmppInLog('test message');
      expect(log.pen, isNotNull);
    });
  });

  group('XmppOutLog', () {
    test('has correct title', () {
      final log = XmppOutLog('test message');
      expect(log.title, equals('XMPP OUT'));
    });

    test('has blue pen color', () {
      final log = XmppOutLog('test message');
      expect(log.pen, isNotNull);
    });
  });

  group('XmppStatusLog', () {
    test('has correct title', () {
      final log = XmppStatusLog('test message');
      expect(log.title, equals('XMPP STATUS'));
    });

    test('has yellow pen color', () {
      final log = XmppStatusLog('test message');
      expect(log.pen, isNotNull);
    });
  });

  group('XmppDebug', () {
    late EventEmitter entity;
    late Talker talker;
    late XmppDebug debugger;
    late List<TalkerData> logs;

    setUp(() {
      entity = EventEmitter();
      logs = [];
      talker = Talker(
        settings: TalkerSettings(
          useConsoleLogs: false,
          useHistory: true,
        ),
      );
      talker.stream.listen(logs.add);
      debugger = XmppDebug(entity: entity, talker: talker);
    });

    tearDown(() {
      debugger.dispose();
      entity.dispose();
    });

    test('starts logging on start()', () async {
      debugger.start();

      final element = xml('message', {}, [xml('body', {}, ['Hello'])]);
      entity.emit('element', element);

      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(1));
    });

    test('logs incoming elements', () async {
      debugger.start();

      final element = xml('message', {'type': 'chat'}, [
        xml('body', {}, ['Hello']),
      ]);
      entity.emit('element', element);

      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(1));
      expect(logs.first, isA<XmppInLog>());
    });

    test('logs outgoing elements', () async {
      debugger.start();

      final element = xml('message', {'type': 'chat'}, [
        xml('body', {}, ['Hello']),
      ]);
      entity.emit('send', element);

      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(1));
      expect(logs.first, isA<XmppOutLog>());
    });

    test('logs status changes', () async {
      debugger.start();

      entity.emit('status', 'online');

      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(1));
      expect(logs.first, isA<XmppStatusLog>());
    });

    test('logs errors', () async {
      debugger.start();

      entity.emit('error', Exception('Test error'));

      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(1));
    });

    test('logs non-exception errors', () async {
      debugger.start();

      entity.emit('error', 'String error');

      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(1));
    });

    test('stops logging on stop()', () async {
      debugger.start();
      debugger.stop();

      final element = xml('message', {}, [xml('body', {}, ['Hello'])]);
      entity.emit('element', element);

      await Future<void>.delayed(Duration.zero);

      expect(logs, isEmpty);
    });

    test('hides sensitive data in logs', () async {
      debugger.start();

      final element = xml('auth', {'xmlns': nsSASL}, [
        xml('mechanism', {}, ['PLAIN']),
      ]);
      entity.emit('element', element);

      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(1));
      final logMessage = logs.first.message;
      expect(logMessage, contains('hidden'));
      expect(logMessage, isNot(contains('PLAIN')));
    });

    test('dispose calls stop', () async {
      debugger.start();
      debugger.dispose();

      final element = xml('message', {}, [xml('body', {}, ['Hello'])]);
      entity.emit('element', element);

      await Future<void>.delayed(Duration.zero);

      expect(logs, isEmpty);
    });
  });

  group('debug()', () {
    late EventEmitter entity;

    setUp(() {
      entity = EventEmitter();
    });

    tearDown(() {
      entity.dispose();
    });

    test('returns XmppDebug when force is true', () {
      final result = debug(entity, force: true);
      expect(result, isNotNull);
      expect(result, isA<XmppDebug>());
      result?.dispose();
    });

    test('returns null when force is false and XMPP_DEBUG not set', () {
      // Note: This test assumes XMPP_DEBUG env var is not set
      final result = debug(entity, force: false);
      expect(result, isNull);
    });

    test('accepts custom Talker instance', () {
      final customTalker = Talker(
        settings: TalkerSettings(useConsoleLogs: false),
      );
      final result = debug(entity, force: true, talker: customTalker);

      expect(result, isNotNull);
      expect(result?.talker, equals(customTalker));
      result?.dispose();
    });

    test('starts debugging automatically', () async {
      final talker = Talker(
        settings: TalkerSettings(
          useConsoleLogs: false,
          useHistory: true,
        ),
      );
      final logs = <TalkerData>[];
      talker.stream.listen(logs.add);

      final result = debug(entity, force: true, talker: talker);

      final element = xml('message', {}, [xml('body', {}, ['Hello'])]);
      entity.emit('element', element);

      await Future<void>.delayed(Duration.zero);

      expect(logs, hasLength(1));
      result?.dispose();
    });
  });
}
