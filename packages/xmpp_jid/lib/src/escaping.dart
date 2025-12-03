/// JID Escaping utilities.
///
/// Implements XEP-0106: JID Escaping.
/// @see http://xmpp.org/extensions/xep-0106.html
library;

/// Detect if a local part needs escaping.
///
/// Returns true if the local part contains characters that need escaping.
bool detectEscape(String? local) {
  if (local == null || local.isEmpty) {
    return false;
  }

  // Remove all escaped sequences
  final tmp = local
      .replaceAll(r'\20', '')
      .replaceAll(r'\22', '')
      .replaceAll(r'\26', '')
      .replaceAll(r'\27', '')
      .replaceAll(r'\2f', '')
      .replaceAll(r'\3a', '')
      .replaceAll(r'\3c', '')
      .replaceAll(r'\3e', '')
      .replaceAll(r'\40', '')
      .replaceAll(r'\5c', '');

  // Detect if we have unescaped sequences
  final search = RegExp(r'[ "&' "'" r'/:<>@\\]').hasMatch(tmp);
  return search;
}

/// Escape the local part of a JID.
///
/// @see http://xmpp.org/extensions/xep-0106.html
/// @param local local part of a jid
/// @return An escaped local part
String? escapeLocal(String? local) {
  if (local == null) {
    return null;
  }

  return local
      .trim()
      .replaceAll(r'\', r'\5c')
      .replaceAll(' ', r'\20')
      .replaceAll('"', r'\22')
      .replaceAll('&', r'\26')
      .replaceAll("'", r'\27')
      .replaceAll('/', r'\2f')
      .replaceAll(':', r'\3a')
      .replaceAll('<', r'\3c')
      .replaceAll('>', r'\3e')
      .replaceAll('@', r'\40');
}

/// Unescape a local part of a JID.
///
/// @see http://xmpp.org/extensions/xep-0106.html
/// @param local local part of a jid
/// @return unescaped local part
String? unescapeLocal(String? local) {
  if (local == null) {
    return null;
  }

  return local
      .replaceAll(r'\20', ' ')
      .replaceAll(r'\22', '"')
      .replaceAll(r'\26', '&')
      .replaceAll(r'\27', "'")
      .replaceAll(r'\2f', '/')
      .replaceAll(r'\3a', ':')
      .replaceAll(r'\3c', '<')
      .replaceAll(r'\3e', '>')
      .replaceAll(r'\40', '@')
      .replaceAll(r'\5c', r'\');
}
