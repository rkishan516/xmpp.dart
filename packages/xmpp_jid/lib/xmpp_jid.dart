/// XMPP JID (Jabber ID) parsing and manipulation.
///
/// Implements XMPP addresses according to RFC6122 and XEP-0106 (JID Escaping).
///
/// A JID has the format: `local@domain/resource`
/// - `local` - The local part (optional)
/// - `domain` - The domain (required)
/// - `resource` - The resource (optional)
///
/// Example:
/// ```dart
/// // Parse a JID from string
/// final jid = JID.parse('user@example.com/resource');
///
/// // Create a JID from parts
/// final jid2 = JID('user', 'example.com', 'resource');
///
/// // Get the bare JID
/// final bare = jid.bare();
/// print(bare); // user@example.com
/// ```
library;

export 'src/escaping.dart';
export 'src/jid.dart';
export 'src/parse.dart';
