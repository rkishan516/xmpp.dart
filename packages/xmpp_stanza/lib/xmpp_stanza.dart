/// Base stanza classes for XMPP.
///
/// Provides Message, Presence, and custom stanza support with
/// type-safe builders and parsers.
///
/// Example:
/// ```dart
/// // Create a chat message
/// final msg = Message(
///   to: 'user@example.com',
///   type: MessageType.chat,
///   body: 'Hello!',
/// );
///
/// // Create a presence
/// final presence = Presence(
///   show: PresenceShow.away,
///   status: 'Be right back',
/// );
/// ```
library;

export 'src/extension.dart';
export 'src/message.dart';
export 'src/presence.dart';
export 'src/stanza.dart';
