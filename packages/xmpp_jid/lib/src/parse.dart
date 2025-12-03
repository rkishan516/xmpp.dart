import 'jid.dart';

/// Parse a JID from a string.
///
/// Format: `local@domain/resource`
/// - `local` - The local part (optional)
/// - `domain` - The domain (required)
/// - `resource` - The resource (optional)
///
/// Example:
/// ```dart
/// final jid = parse('user@example.com/resource');
/// print(jid.local); // user
/// print(jid.domain); // example.com
/// print(jid.resource); // resource
/// ```
JID parse(String s) {
  String? local;
  String? resource;

  // Extract resource
  final resourceStart = s.indexOf('/');
  if (resourceStart != -1) {
    resource = s.substring(resourceStart + 1);
    s = s.substring(0, resourceStart);
  }

  // Extract local
  final atStart = s.indexOf('@');
  if (atStart != -1) {
    local = s.substring(0, atStart);
    s = s.substring(atStart + 1);
  }

  return JID(local, s, resource);
}
