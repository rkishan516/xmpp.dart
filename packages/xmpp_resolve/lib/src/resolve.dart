import 'dart:async';
import 'package:xmpp_events/xmpp_events.dart';

/// SRV record result.
class SrvRecord {
  final String target;
  final int port;
  final int priority;
  final int weight;
  final String uri;

  SrvRecord({
    required this.target,
    required this.port,
    required this.priority,
    required this.weight,
    required this.uri,
  });
}

/// SRV service configuration.
class SrvService {
  final String service;
  final String protocol;

  SrvService({required this.service, this.protocol = 'tcp'});
}

/// Resolve options.
class ResolveOptions {
  final List<SrvService> srv;

  ResolveOptions({required this.srv});
}

/// Default SRV services for XMPP client connections.
final defaultSrvServices = [
  SrvService(service: 'xmpps-client', protocol: 'tcp'),
  SrvService(service: 'xmpp-client', protocol: 'tcp'),
];

/// Resolve a domain to XMPP server URIs using DNS SRV records.
///
/// Returns a list of SRV records sorted by priority and weight.
Future<List<SrvRecord>> resolve(String domain, [ResolveOptions? options]) async {
  final services = options?.srv ?? defaultSrvServices;
  final records = <SrvRecord>[];

  for (final service in services) {
    final srvName = '_${service.service}._${service.protocol}.$domain';

    try {
      final results = await _lookupSrv(srvName);
      for (final result in results) {
        final isSecure = service.service.contains('xmpps');
        final protocol = isSecure ? 'xmpps:' : 'xmpp:';
        final uri = '$protocol//${result.target}:${result.port}';

        records.add(SrvRecord(
          target: result.target,
          port: result.port,
          priority: result.priority,
          weight: result.weight,
          uri: uri,
        ));
      }
    } catch (_) {
      // DNS lookup failed, continue with next service
    }
  }

  // Sort by priority (lower is better), then by weight (higher is better)
  records.sort((a, b) {
    final priorityCompare = a.priority.compareTo(b.priority);
    if (priorityCompare != 0) return priorityCompare;
    return b.weight.compareTo(a.weight);
  });

  return records;
}

/// Internal SRV lookup result.
class _SrvResult {
  final String target;
  final int port;
  final int priority;
  final int weight;

  _SrvResult({
    required this.target,
    required this.port,
    required this.priority,
    required this.weight,
  });
}

/// Lookup SRV records using system DNS resolver.
Future<List<_SrvResult>> _lookupSrv(String name) async {
  // Dart's InternetAddress doesn't support SRV records directly.
  // We use a simple fallback approach.
  // In production, you might want to use a dedicated DNS library.

  // For now, return empty list and rely on direct connection
  // A full implementation would use native DNS or a DNS library
  return [];
}

/// Fetch URIs for a domain.
Future<List<String>> fetchURIs(String domain) async {
  final result = await resolve(domain);

  // Remove duplicates while preserving order
  final seen = <String>{};
  return result
      .map((record) => record.uri)
      .where(seen.add)
      .toList();
}

/// Set up resolve functionality for an entity.
///
/// This wraps the entity's connect method to support domain-based
/// service discovery.
void setupResolve(EventEmitter entity) {
  // Store original connect method
  dynamic originalConnect;

  try {
    final dynamic e = entity;
    originalConnect = e.connect;

    // Replace connect method
    e.connect = (String service) async {
      // If service already has a protocol, use original connect
      if (service.isEmpty || service.contains('://')) {
        return originalConnect(service);
      }

      // Try to resolve the domain
      final uris = await fetchURIs(service);

      if (uris.isEmpty) {
        // Fall back to default connection
        return originalConnect('xmpp://$service');
      }

      // Try each URI until one works
      for (final uri in uris) {
        try {
          await originalConnect(uri);
          return;
        } catch (_) {
          // Try next URI
        }
      }

      throw StateError('Could not connect to any resolved server');
    };
  } catch (_) {
    // Entity doesn't support method replacement
  }
}
