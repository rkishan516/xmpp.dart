/// Parse a service URL.
///
/// Returns a record with protocol and rest of the URL.
({String? protocol, String? rest})? parseService(String? service) {
  if (service == null || service.isEmpty) return null;

  final match = RegExp(r'^([a-z]+:)//(.+)$').firstMatch(service);
  if (match != null) {
    return (protocol: match.group(1), rest: match.group(2));
  }

  return (protocol: null, rest: service);
}

/// Parse a host string.
///
/// Returns a record with host and optional port.
({String host, int? port})? parseHost(String? hostString) {
  if (hostString == null || hostString.isEmpty) return null;

  // Handle IPv6 addresses
  if (hostString.startsWith('[')) {
    final closeBracket = hostString.indexOf(']');
    if (closeBracket == -1) {
      return (host: hostString, port: null);
    }

    final host = hostString.substring(0, closeBracket + 1);
    final rest = hostString.substring(closeBracket + 1);

    if (rest.startsWith(':')) {
      final port = int.tryParse(rest.substring(1));
      return (host: host, port: port);
    }

    return (host: host, port: null);
  }

  // Handle IPv4 or hostname
  final colonIndex = hostString.lastIndexOf(':');
  if (colonIndex == -1) {
    return (host: hostString, port: null);
  }

  final host = hostString.substring(0, colonIndex);
  final port = int.tryParse(hostString.substring(colonIndex + 1));
  return (host: host, port: port);
}
