/// XML parsing error.
class XMLError implements Exception {
  /// The error message.
  final String message;

  XMLError(this.message);

  @override
  String toString() => 'XMLError: $message';
}
