import 'package:test/test.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

void main() {
  group('XmlElement', () {
    test('creates element with name', () {
      final el = XmlElement('message');
      expect(el.name, equals('message'));
      expect(el.attrs, isEmpty);
      expect(el.children, isEmpty);
    });

    test('creates element with attributes', () {
      final el = XmlElement('message', {'to': 'user@example.com', 'type': 'chat'});
      expect(el.attrs['to'], equals('user@example.com'));
      expect(el.attrs['type'], equals('chat'));
    });

    test('creates element with children', () {
      final body = XmlElement('body', {}, ['Hello']);
      final el = XmlElement('message', {}, [body]);
      expect(el.children.length, equals(1));
      expect(el.children[0], equals(body));
    });
  });

  group('xml factory', () {
    test('creates element', () {
      final el = xml('message', {'to': 'user@example.com'});
      expect(el.name, equals('message'));
      expect(el.attrs['to'], equals('user@example.com'));
    });

    test('creates element with children', () {
      final el = xml('message', {}, [
        xml('body', {}, ['Hello']),
      ]);
      expect(el.children.length, equals(1));
      final body = el.children[0] as XmlElement;
      expect(body.name, equals('body'));
      expect(body.text(), equals('Hello'));
    });

    test('sets parent on children', () {
      final el = xml('message', {}, [
        xml('body', {}, ['Hello']),
      ]);
      final body = el.children[0] as XmlElement;
      expect(body.parent, equals(el));
    });
  });

  group('element methods', () {
    test('is_ checks name and namespace', () {
      final el = xml('message', {'xmlns': 'jabber:client'});
      expect(el.is_('message'), isTrue);
      expect(el.is_('message', 'jabber:client'), isTrue);
      expect(el.is_('message', 'other'), isFalse);
      expect(el.is_('other'), isFalse);
    });

    test('getNS returns namespace', () {
      final el = xml('message', {'xmlns': 'jabber:client'});
      expect(el.getNS(), equals('jabber:client'));
    });

    test('getChild returns child element', () {
      final el = xml('message', {}, [
        xml('body', {}, ['Hello']),
        xml('subject', {}, ['Test']),
      ]);
      final body = el.getChild('body');
      expect(body, isNotNull);
      expect(body!.name, equals('body'));
    });

    test('getChild with namespace', () {
      final el = xml('message', {}, [
        xml('body', {'xmlns': 'ns1'}, ['Hello']),
        xml('body', {'xmlns': 'ns2'}, ['World']),
      ]);
      final body = el.getChild('body', 'ns2');
      expect(body, isNotNull);
      expect(body!.text(), equals('World'));
    });

    test('getChildren returns all matching children', () {
      final el = xml('message', {}, [
        xml('body', {}, ['Hello']),
        xml('body', {}, ['World']),
      ]);
      final bodies = el.getChildren('body');
      expect(bodies.length, equals(2));
    });

    test('getChildText returns text content', () {
      final el = xml('message', {}, [
        xml('body', {}, ['Hello']),
      ]);
      expect(el.getChildText('body'), equals('Hello'));
    });

    test('text returns text content', () {
      final el = xml('body', {}, ['Hello', ' ', 'World']);
      expect(el.text(), equals('Hello World'));
    });

    test('t appends text', () {
      final el = xml('body');
      el.t('Hello').t(' ').t('World');
      expect(el.text(), equals('Hello World'));
    });

    test('append adds child', () {
      final el = xml('message');
      el.append(xml('body'));
      expect(el.children.length, equals(1));
    });

    test('prepend adds child at beginning', () {
      final el = xml('message', {}, [xml('body')]);
      el.prepend(xml('subject'));
      expect((el.children[0] as XmlElement).name, equals('subject'));
    });

    test('remove removes child', () {
      final body = xml('body');
      final el = xml('message', {}, [body]);
      expect(el.remove(body), isTrue);
      expect(el.children, isEmpty);
    });

    test('clone creates deep copy', () {
      final el = xml('message', {'to': 'user@example.com'}, [
        xml('body', {}, ['Hello']),
      ]);
      final cloned = el.clone();
      expect(cloned.name, equals('message'));
      expect(cloned.attrs['to'], equals('user@example.com'));
      expect((cloned.children[0] as XmlElement).text(), equals('Hello'));
      expect(identical(el, cloned), isFalse);
    });
  });

  group('toString', () {
    test('serializes empty element', () {
      final el = xml('br');
      expect(el.toString(), equals('<br/>'));
    });

    test('serializes element with attributes', () {
      final el = xml('message', {'to': 'user@example.com'});
      expect(el.toString(), equals('<message to="user@example.com"/>'));
    });

    test('serializes element with children', () {
      final el = xml('message', {}, [
        xml('body', {}, ['Hello']),
      ]);
      expect(el.toString(), equals('<message><body>Hello</body></message>'));
    });

    test('escapes attribute values', () {
      final el = xml('message', {'data': '<>&"\''});
      expect(el.toString(), contains('&lt;'));
      expect(el.toString(), contains('&gt;'));
      expect(el.toString(), contains('&amp;'));
      expect(el.toString(), contains('&quot;'));
      expect(el.toString(), contains('&apos;'));
    });

    test('escapes text content', () {
      final el = xml('body', {}, ['<script>alert("hi")</script>']);
      expect(el.toString(), contains('&lt;script&gt;'));
    });
  });

  group('escaping', () {
    test('escapeXML escapes special characters', () {
      expect(escapeXML('<>&"\''), equals('&lt;&gt;&amp;&quot;&apos;'));
    });

    test('unescapeXML unescapes special characters', () {
      expect(unescapeXML('&lt;&gt;&amp;&quot;&apos;'), equals('<>&"\''));
    });

    test('escapeXMLText escapes text characters', () {
      expect(escapeXMLText('<>&'), equals('&lt;&gt;&amp;'));
    });

    test('unescapeXMLText unescapes text characters', () {
      expect(unescapeXMLText('&lt;&gt;&amp;'), equals('<>&'));
    });
  });

  group('XmlParser', () {
    test('parses simple element', () async {
      final parser = XmlParser();
      XmlElement? received;

      parser.on<XmlElement>('element', (el) {
        received = el;
      });

      parser.write('<root><message>Hello</message></root>');

      // Wait for parsing
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(received, isNotNull);
      expect(received!.name, equals('message'));
      expect(received!.text(), equals('Hello'));
    });

    test('emits start event for root', () async {
      final parser = XmlParser();
      XmlElement? root;

      parser.on<XmlElement>('start', (el) {
        root = el;
      });

      parser.write('<stream:stream xmlns="jabber:client">');

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(root, isNotNull);
      expect(root!.name, equals('stream:stream'));
    });
  });

  group('XMLError', () {
    test('creates error with message', () {
      final error = XMLError('test error');
      expect(error.message, equals('test error'));
      expect(error.toString(), contains('test error'));
    });
  });
}
