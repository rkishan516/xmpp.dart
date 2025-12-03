import 'dart:async';

import 'package:xmpp_base64/xmpp_base64.dart';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_stream_features/xmpp_stream_features.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'credentials.dart';
import 'sasl_error.dart';
import 'sasl_factory.dart';

/// SASL namespace.
const nsSASL = 'urn:ietf:params:xml:ns:xmpp-sasl';

/// Get available mechanisms from the server's feature element.
List<String> getAvailableMechanisms(
  XmlElement element,
  String ns,
  SASLFactory saslFactory,
) {
  // Get mechanism children - they don't have their own xmlns,
  // they inherit from the parent mechanisms element
  final offered = element
      .getChildren('mechanism')
      .map((m) => m.text())
      .toSet();

  final supported = saslFactory.mechs.map((e) => e.name);
  return supported.where(offered.contains).toList();
}

/// Callback type for authentication.
///
/// [done] - Call this function to proceed with authentication.
/// [mechanisms] - List of available mechanisms.
/// [entity] - The connection entity.
typedef OnAuthenticate = FutureOr<void> Function(
  Future<void> Function(Map<String, dynamic> credentials, String mechanism) done,
  List<String> mechanisms,
  dynamic context,
  EventEmitter entity,
);

/// Authenticate with the server using SASL.
Future<void> authenticate({
  required SASLFactory saslFactory,
  required EventEmitter entity,
  required String mechanism,
  required Map<String, dynamic> credentials,
}) async {
  final mech = saslFactory.create([mechanism]);
  if (mech == null) {
    throw SASLError('invalid-mechanism', 'Mechanism $mechanism not found.');
  }

  // Get domain from entity options
  String? domain;
  try {
    final dynamic e = entity;
    final options = e.options as Map<String, dynamic>?;
    domain = options?['domain'] as String?;
  } catch (_) {}

  final creds = Credentials(
    username: credentials['username'] as String?,
    password: credentials['password'] as String?,
    server: domain,
    host: domain,
    realm: domain,
    serviceType: 'xmpp',
    serviceName: domain,
  );

  // Send initial auth element if client-first
  if (mech.clientFirst) {
    final response = await mech.response(creds);
    final dynamic e = entity;
    await e.send(xml('auth', {'xmlns': nsSASL, 'mechanism': mech.name}, [
      if (response.isNotEmpty) encode(response),
    ]));
  }

  // Process challenges and send responses
  final completer = Completer<void>();

  void handleElement(XmlElement element) async {
    if (element.attrs['xmlns'] != nsSASL) return;

    if (element.name == 'challenge') {
      try {
        await mech.challenge(decode(element.text()));
        final resp = await mech.response(creds);
        final dynamic e = entity;
        await e.send(xml('response', {'xmlns': nsSASL}, [
          if (resp.isNotEmpty) encode(resp),
        ]));
      } catch (err) {
        completer.completeError(err);
      }
      return;
    }

    if (element.name == 'failure') {
      completer.completeError(SASLError.fromElement(element));
      return;
    }

    if (element.name == 'success') {
      completer.complete();
      return;
    }
  }

  final subscription = entity.on<XmlElement>('element', handleElement);

  try {
    await completer.future;
  } finally {
    await subscription.cancel();
  }
}

/// Set up SASL authentication for stream features.
void sasl(
  StreamFeatures streamFeatures,
  SASLFactory saslFactory,
  OnAuthenticate onAuthenticate,
) {
  streamFeatures.use('mechanisms', nsSASL, (ctx, next, element) async {
    final entity = ctx.entity;
    final mechanisms = getAvailableMechanisms(element, nsSASL, saslFactory);

    if (mechanisms.isEmpty) {
      throw SASLError('invalid-mechanism', 'No compatible mechanism available.');
    }

    Future<void> done(Map<String, dynamic> credentials, String mechanism) async {
      await authenticate(
        saslFactory: saslFactory,
        entity: entity,
        mechanism: mechanism,
        credentials: credentials,
      );
    }

    await onAuthenticate(done, mechanisms, null, entity);

    // Restart the stream after authentication
    try {
      final dynamic e = entity;
      await e.restart();
    } catch (_) {
      // Entity might not have restart method
    }
  });
}
