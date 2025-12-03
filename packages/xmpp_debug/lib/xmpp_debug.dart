/// Debug logging for XMPP connections.
///
/// Provides logging capabilities for XMPP traffic using the Talker logger.
/// Automatically hides sensitive data like authentication credentials.
///
/// Example:
/// ```dart
/// final client = Client(options);
/// debug(client); // Enable debug logging
///
/// // Or with custom Talker instance
/// final talker = Talker(settings: TalkerSettings(enabled: true));
/// debug(client, talker: talker);
/// ```
library;

export 'src/debug.dart';
export 'src/sensitive.dart';
