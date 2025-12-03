import 'escaping.dart';
import 'parse.dart';

/// JID implements XMPP addresses according to RFC6122 and XEP-0106.
///
/// @see http://tools.ietf.org/html/rfc6122#section-2
/// @see http://xmpp.org/extensions/xep-0106.html
class JID {
  String _local = '';
  String _domain = '';
  String _resource = '';

  /// Creates a new JID.
  ///
  /// - [local] - The local part (optional)
  /// - [domain] - The domain (required)
  /// - [resource] - The resource (optional)
  /// - [escape] - Whether to auto-escape the local part (default: auto-detect)
  JID(String? local, String domain, [String? resource, bool? escape]) {
    if (domain.isEmpty) {
      throw ArgumentError('Invalid domain.');
    }

    setDomain(domain);
    setLocal(local ?? '', escape);
    setResource(resource ?? '');
  }

  /// Parse a JID from a string.
  ///
  /// Example:
  /// ```dart
  /// final jid = JID.parse('user@example.com/resource');
  /// ```
  factory JID.parse(String s) => parse(s);

  /// Get the local part.
  ///
  /// If [unescape] is true, the local part will be unescaped.
  String getLocal([bool unescape = false]) {
    if (unescape) {
      return unescapeLocal(_local) ?? '';
    }
    return _local;
  }

  /// Set the local part.
  ///
  /// If [escape] is null, auto-detection will be used.
  void setLocal(String local, [bool? escape]) {
    escape ??= detectEscape(local);

    if (escape) {
      local = escapeLocal(local) ?? '';
    }

    _local = local.toLowerCase();
  }

  /// Get the local part.
  String get local => getLocal();

  /// Set the local part.
  set local(String value) => setLocal(value);

  /// Get the domain.
  String getDomain() => _domain;

  /// Set the domain.
  void setDomain(String domain) {
    _domain = domain.toLowerCase();
  }

  /// Get the domain.
  String get domain => getDomain();

  /// Set the domain.
  set domain(String value) => setDomain(value);

  /// Get the resource.
  String getResource() => _resource;

  /// Set the resource.
  void setResource(String resource) {
    _resource = resource;
  }

  /// Get the resource.
  String get resource => getResource();

  /// Set the resource.
  set resource(String value) => setResource(value);

  /// Get a bare JID (without resource).
  ///
  /// If this JID already has no resource, returns itself.
  JID bare() {
    if (_resource.isNotEmpty) {
      return JID(_local, _domain);
    }
    return this;
  }

  /// Check if this JID equals another.
  bool equals(JID other) {
    return _local == other._local &&
        _domain == other._domain &&
        _resource == other._resource;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JID) return false;
    return equals(other);
  }

  @override
  int get hashCode => Object.hash(_local, _domain, _resource);

  /// Convert to string.
  ///
  /// If [unescape] is true, the local part will be unescaped.
  @override
  String toString([bool unescape = false]) {
    var s = _domain;

    if (_local.isNotEmpty) {
      s = '${getLocal(unescape)}@$s';
    }

    if (_resource.isNotEmpty) {
      s = '$s/$_resource';
    }

    return s;
  }
}

/// Check if two JIDs are equal.
bool equal(JID a, JID b) => a.equals(b);

/// Create a JID from parts or parse from string.
///
/// If only one argument is provided and it's a string without domain/resource,
/// it will be parsed as a JID string.
JID jid(dynamic localOrString, [String? domain, String? resource]) {
  if (domain == null && resource == null) {
    if (localOrString is String) {
      return JID.parse(localOrString);
    }
    if (localOrString is JID) {
      return localOrString;
    }
    throw ArgumentError('Invalid JID argument');
  }

  return JID(localOrString as String?, domain!, resource);
}
