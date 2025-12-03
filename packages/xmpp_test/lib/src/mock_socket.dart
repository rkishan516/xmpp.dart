import 'package:xmpp_events/xmpp_events.dart';

/// Mock socket for testing.
///
/// Provides an EventEmitter-based socket that can be used for testing
/// without actual network connections.
class MockSocket extends EventEmitter {
  final List<String> sentData = [];
  bool _closed = false;

  /// Check if socket is closed.
  bool get isClosed => _closed;

  /// Simulate data received from the socket.
  void fakeData(String data) {
    emit('data', data);
  }

  /// Simulate socket error.
  void fakeError(dynamic error) {
    emit('error', error);
  }

  /// Simulate socket close.
  void fakeClose() {
    _closed = true;
    emit('close', null);
  }

  /// Simulate connection.
  void fakeConnect() {
    emit('connect', null);
  }

  /// Write data to the socket (captured for testing).
  void write(String data) {
    sentData.add(data);
  }

  /// Clear sent data.
  void clearSentData() {
    sentData.clear();
  }
}
