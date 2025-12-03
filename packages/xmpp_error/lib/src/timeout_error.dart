import 'xmpp_error.dart';

/// Timeout error for XMPP operations.
///
/// Thrown when an operation times out waiting for a response.
class TimeoutError extends XMPPError {
  /// The duration that was exceeded.
  final Duration timeout;

  TimeoutError(this.timeout, [String? message])
      : super('timeout', message ?? 'Operation timed out after ${timeout.inMilliseconds}ms');

  @override
  String toString() {
    return 'TimeoutError: ${text ?? "Operation timed out after ${timeout.inMilliseconds}ms"}';
  }
}
