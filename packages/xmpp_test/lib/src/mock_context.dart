import 'dart:async';
import 'package:xmpp_events/xmpp_events.dart';
import 'package:xmpp_jid/xmpp_jid.dart';
import 'package:xmpp_xml/xmpp_xml.dart';

import 'mock_socket.dart';

/// Test context for XMPP entity testing.
///
/// Provides utilities for mocking incoming/outgoing stanzas
/// and testing XMPP client behavior.
class MockContext {
  /// The XMPP entity being tested.
  final EventEmitter entity;

  /// The mock socket.
  late final MockSocket socket;

  MockContext(this.entity) {
    socket = MockSocket();
  }

  /// Sanitize a stanza by removing id and xmlns.
  ({XmlElement stanza, String? id}) sanitize(XmlElement stanza) {
    final clone = stanza.clone();
    final id = clone.attrs['id'];
    clone.attrs.remove('id');
    clone.attrs.remove('xmlns');
    return (stanza: clone, id: id);
  }

  /// Catch the next outgoing stanza.
  Future<({XmlElement stanza, String? id})> catchNext() async {
    final completer = Completer<XmlElement>();
    entity.once<XmlElement>('send', completer.complete);
    final stanza = await completer.future;
    return sanitize(stanza);
  }

  /// Catch the next outgoing stanza matching a predicate.
  Future<XmlElement> catchOutgoing([bool Function(XmlElement)? match]) async {
    match ??= (_) => true;
    final completer = Completer<XmlElement>();

    void onSend(XmlElement stanza) {
      if (match!(stanza)) {
        entity.removeListener('send', onSend);
        completer.complete(stanza);
      }
    }

    entity.on<XmlElement>('send', onSend);
    return completer.future;
  }

  /// Catch the next outgoing IQ.
  Future<XmlElement> catchOutgoingIq([bool Function(XmlElement)? match]) {
    return catchOutgoing((stanza) =>
        stanza.name == 'iq' && (match?.call(stanza) ?? true));
  }

  /// Catch the next outgoing IQ get.
  Future<XmlElement?> catchOutgoingGet([bool Function(XmlElement)? match]) async {
    final stanza = await catchOutgoingIq((s) =>
        s.attrs['type'] == 'get' && (match?.call(s) ?? true));
    final children = stanza.getChildElements();
    if (children.isNotEmpty) {
      final child = children.first;
      child.parent = null;
      return child;
    }
    return null;
  }

  /// Catch the next outgoing IQ set.
  Future<XmlElement?> catchOutgoingSet([bool Function(XmlElement)? match]) async {
    final stanza = await catchOutgoingIq((s) =>
        s.attrs['type'] == 'set' && (match?.call(s) ?? true));
    final children = stanza.getChildElements();
    if (children.isNotEmpty) {
      final child = children.first;
      child.parent = null;
      return child;
    }
    return null;
  }

  /// Schedule an incoming result after the next send.
  Future<XmlElement?> scheduleIncomingResult([XmlElement? child]) async {
    final stanza = await catchOutgoing();
    final id = stanza.attrs['id'];
    return fakeIncomingResult(child, id);
  }

  /// Schedule an incoming error after the next send.
  Future<XmlElement?> scheduleIncomingError([XmlElement? child]) async {
    final stanza = await catchOutgoing();
    final id = stanza.attrs['id'];
    return fakeIncomingError(child, id);
  }

  /// Fake an incoming IQ get.
  Future<XmlElement?> fakeIncomingGet(XmlElement? child,
      [Map<String, String>? attrs]) async {
    final stanza = await fakeIncomingIq(
        xml('iq', {...?attrs, 'type': 'get'}, child != null ? [child] : []));
    final children = stanza.getChildElements();
    if (children.isNotEmpty) {
      final c = children.first;
      c.parent = null;
      return c;
    }
    return null;
  }

  /// Fake an incoming IQ set.
  Future<XmlElement?> fakeIncomingSet(XmlElement? child,
      [Map<String, String>? attrs]) async {
    final stanza = await fakeIncomingIq(
        xml('iq', {...?attrs, 'type': 'set'}, child != null ? [child] : []));
    final children = stanza.getChildElements();
    if (children.isNotEmpty) {
      final c = children.first;
      c.parent = null;
      return c;
    }
    return null;
  }

  /// Fake an incoming IQ result.
  Future<XmlElement?> fakeIncomingResult(XmlElement? child, String? id) async {
    final stanza = await fakeIncomingIq(
        xml('iq', {'type': 'result', if (id != null) 'id': id},
            child != null ? [child] : []));
    final children = stanza.getChildElements();
    if (children.isNotEmpty) {
      final c = children.first;
      c.parent = null;
      return c;
    }
    return null;
  }

  /// Fake an incoming IQ error.
  Future<XmlElement?> fakeIncomingError(XmlElement? child, String? id) async {
    final stanza = await fakeIncomingIq(
        xml('iq', {'type': 'error', if (id != null) 'id': id},
            child != null ? [child] : []));
    final children = stanza.getChildElements();
    if (children.isNotEmpty) {
      final c = children.first;
      c.parent = null;
      return c;
    }
    return null;
  }

  /// Fake an incoming IQ.
  Future<XmlElement> fakeIncomingIq(XmlElement el) async {
    final stanza = el.clone();
    if (stanza.name == 'iq' && stanza.attrs['id'] == null) {
      stanza.attrs['id'] = 'fake';
    }
    return fakeIncoming(stanza);
  }

  /// Fake an incoming stanza.
  Future<XmlElement> fakeIncoming(XmlElement el) async {
    final completer = Completer<XmlElement>();
    entity.once<XmlElement>('send', completer.complete);

    final stanza = el.clone();
    stanza.attrs.remove('xmlns');

    await Future<void>.delayed(Duration.zero);
    mockInput(el);
    await completer.future;

    return sanitize(el).stanza;
  }

  /// Fake an outgoing stanza.
  void fakeOutgoing(XmlElement el) {
    entity.emit('send', el);
  }

  /// Mock input data.
  void mockInput(XmlElement el) {
    entity.emit('input', el.toString());
    entity.emit('element', el);
  }
}

/// Create a mock context for an entity.
MockContext mockContext(EventEmitter entity) {
  return MockContext(entity);
}

/// Create a mock JID for testing.
JID mockJid([String? jid]) {
  return JID.parse(jid ?? 'test@example.com/resource');
}
