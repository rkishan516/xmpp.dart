import 'package:xml/xml.dart' as xmlpkg;
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'stanza.dart';

/// Message types as defined in XMPP RFC 6121.
enum MessageType {
  /// A one-to-one chat message.
  chat,

  /// An error message.
  error,

  /// A group chat message (MUC).
  groupchat,

  /// A message that generates no reply (news, alerts).
  headline,

  /// A standalone message (default type).
  normal,
}

/// Extension to convert MessageType to/from string.
extension MessageTypeExtension on MessageType {
  /// Convert to XMPP string value.
  String get value {
    switch (this) {
      case MessageType.chat:
        return 'chat';
      case MessageType.error:
        return 'error';
      case MessageType.groupchat:
        return 'groupchat';
      case MessageType.headline:
        return 'headline';
      case MessageType.normal:
        return 'normal';
    }
  }

  /// Parse from XMPP string value.
  static MessageType fromString(String? value) {
    switch (value) {
      case 'chat':
        return MessageType.chat;
      case 'error':
        return MessageType.error;
      case 'groupchat':
        return MessageType.groupchat;
      case 'headline':
        return MessageType.headline;
      case 'normal':
      default:
        return MessageType.normal;
    }
  }
}

/// XMPP Message stanza.
///
/// Represents an XMPP `<message>` stanza for sending/receiving messages.
///
/// Example:
/// ```dart
/// // Create a chat message
/// final msg = Message(
///   to: JID.parse('user@example.com'),
///   type: MessageType.chat,
///   body: 'Hello, World!',
/// );
///
/// // Parse from XML
/// final msg = Message.fromXml(element);
/// print(msg.body); // Message content
/// ```
class Message extends Stanza {
  /// Create a new message stanza.
  ///
  /// [to] - Recipient JID
  /// [from] - Sender JID (usually set by server)
  /// [type] - Message type (default: normal)
  /// [id] - Stanza ID
  /// [body] - Message body text
  /// [subject] - Message subject
  /// [thread] - Thread ID for conversation tracking
  /// [lang] - Language code
  Message({
    JID? to,
    JID? from,
    MessageType type = MessageType.normal,
    String? id,
    String? body,
    String? subject,
    String? thread,
    String? lang,
  }) : super(xml('message', {
          if (to != null) 'to': to.toString(),
          if (from != null) 'from': from.toString(),
          if (type != MessageType.normal) 'type': type.value,
          if (id != null) 'id': id,
          if (lang != null) 'xml:lang': lang,
        }, [
          if (body != null) xml('body', {}, [body]),
          if (subject != null) xml('subject', {}, [subject]),
          if (thread != null) xml('thread', {}, [thread]),
        ]));

  /// Create a message from an XML element.
  Message.fromXml(super.element);

  /// Parse a message from an XML string.
  factory Message.fromString(String xmlString) {
    final doc = xmlpkg.XmlDocument.parse(xmlString);
    final element = _convertXmlElement(doc.rootElement);
    return Message.fromXml(element);
  }

  /// The message type.
  MessageType get messageType =>
      MessageTypeExtension.fromString(element.attrs['type']);

  set messageType(MessageType value) {
    if (value == MessageType.normal) {
      element.attrs.remove('type');
    } else {
      element.attrs['type'] = value.value;
    }
  }

  /// The message body text.
  String? get body => element.getChildText('body');

  set body(String? value) {
    final existing = element.getChild('body');
    if (existing != null) {
      element.remove(existing);
    }
    if (value != null) {
      element.append(xml('body', {}, [value]));
    }
  }

  /// The message subject.
  String? get subject => element.getChildText('subject');

  set subject(String? value) {
    final existing = element.getChild('subject');
    if (existing != null) {
      element.remove(existing);
    }
    if (value != null) {
      element.append(xml('subject', {}, [value]));
    }
  }

  /// The thread ID for conversation tracking.
  String? get thread => element.getChildText('thread');

  set thread(String? value) {
    final existing = element.getChild('thread');
    if (existing != null) {
      element.remove(existing);
    }
    if (value != null) {
      element.append(xml('thread', {}, [value]));
    }
  }

  /// The parent thread ID (for nested threads).
  String? get parentThread {
    final threadEl = element.getChild('thread');
    return threadEl?.attrs['parent'];
  }

  set parentThread(String? value) {
    final threadEl = element.getChild('thread');
    if (threadEl != null && value != null) {
      threadEl.attrs['parent'] = value;
    }
  }

  /// Get all body elements (for multi-language support).
  List<MessageBody> get bodies {
    return element.getChildren('body').map((el) {
      return MessageBody(
        text: el.text(),
        lang: el.attrs['xml:lang'],
      );
    }).toList();
  }

  /// Add a body with language.
  void addBody(String text, {String? lang}) {
    element.append(xml('body', {
      if (lang != null) 'xml:lang': lang,
    }, [text]));
  }

  /// Get body text for a specific language.
  String? getBodyForLang(String lang) {
    final bodies = element.getChildren('body');
    for (final body in bodies) {
      if (body.attrs['xml:lang'] == lang) {
        return body.text();
      }
    }
    return null;
  }

  /// Check if this is a chat message.
  bool get isChat => messageType == MessageType.chat;

  /// Check if this is a group chat message.
  bool get isGroupChat => messageType == MessageType.groupchat;

  /// Check if this is an error message.
  bool get isError => messageType == MessageType.error;

  /// Create a reply to this message.
  Message reply({String? body, String? subject}) {
    return Message(
      to: from,
      type: messageType,
      body: body,
      subject: subject,
      thread: thread,
    );
  }

  @override
  Message copy() {
    return Message.fromXml(element.clone());
  }
}

/// Represents a message body with optional language.
class MessageBody {
  /// The body text.
  final String text;

  /// The language code (xml:lang).
  final String? lang;

  const MessageBody({required this.text, this.lang});

  @override
  String toString() => lang != null ? '[$lang] $text' : text;
}

/// Extension on XmlElement for message parsing.
extension MessageParsing on XmlElement {
  /// Check if this element is a message stanza.
  bool get isMessage => name == 'message';

  /// Convert to Message if this is a message element.
  Message? toMessage() => isMessage ? Message.fromXml(this) : null;
}

/// Convert xml package element to xmpp_xml element.
XmlElement _convertXmlElement(xmlpkg.XmlElement source) {
  final attrs = <String, String>{};
  for (final attr in source.attributes) {
    final name = attr.name.prefix != null
        ? '${attr.name.prefix}:${attr.name.local}'
        : attr.name.local;
    attrs[name] = attr.value;
  }

  final children = <dynamic>[];
  for (final node in source.children) {
    if (node is xmlpkg.XmlElement) {
      children.add(_convertXmlElement(node));
    } else if (node is xmlpkg.XmlText) {
      final text = node.value.trim();
      if (text.isNotEmpty) {
        children.add(text);
      }
    }
  }

  return xml(source.name.qualified, attrs, children);
}
