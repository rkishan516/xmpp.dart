/// Credentials for SASL authentication.
class Credentials {
  /// The username for authentication.
  final String? username;

  /// The password for authentication.
  final String? password;

  /// The server name.
  final String? server;

  /// The host name.
  final String? host;

  /// The realm for authentication.
  final String? realm;

  /// The service type (usually 'xmpp').
  final String serviceType;

  /// The service name.
  final String? serviceName;

  Credentials({
    this.username,
    this.password,
    this.server,
    this.host,
    this.realm,
    this.serviceType = 'xmpp',
    this.serviceName,
  });

  /// Create credentials from a map.
  factory Credentials.fromMap(Map<String, dynamic> map) {
    return Credentials(
      username: map['username'] as String?,
      password: map['password'] as String?,
      server: map['server'] as String?,
      host: map['host'] as String?,
      realm: map['realm'] as String?,
      serviceType: (map['serviceType'] as String?) ?? 'xmpp',
      serviceName: map['serviceName'] as String?,
    );
  }

  /// Copy with overridden values.
  Credentials copyWith({
    String? username,
    String? password,
    String? server,
    String? host,
    String? realm,
    String? serviceType,
    String? serviceName,
  }) {
    return Credentials(
      username: username ?? this.username,
      password: password ?? this.password,
      server: server ?? this.server,
      host: host ?? this.host,
      realm: realm ?? this.realm,
      serviceType: serviceType ?? this.serviceType,
      serviceName: serviceName ?? this.serviceName,
    );
  }
}
