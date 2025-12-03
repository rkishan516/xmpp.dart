# xmpp.dart

A pure Dart implementation of the XMPP protocol, providing full feature parity with [xmpp.js](https://github.com/xmppjs/xmpp.js).

## Features

- Pure Dart (no Flutter dependencies)
- Modular architecture with 36 packages
- Support for TCP, TLS, and WebSocket transports
- SASL authentication (PLAIN, SCRAM-SHA-1, ANONYMOUS, SASL2)
- Stream Management (XEP-0198)
- Auto-reconnection
- Client and Component support

## Packages

| Package | Description |
|---------|-------------|
| `xmpp` | Main package - re-exports all public APIs |
| `xmpp_client` | High-level XMPP client |
| `xmpp_component` | XMPP component (server extension) |
| `xmpp_connection` | Connection state machine |
| `xmpp_xml` | XML parsing and building |
| `xmpp_jid` | JID (Jabber ID) handling |
| `xmpp_middleware` | Middleware system for stanza routing |
| `xmpp_sasl` | SASL authentication |
| `xmpp_stream_management` | XEP-0198 Stream Management |

## Installation

Add the main package to your `pubspec.yaml`:

```yaml
dependencies:
  xmpp: ^0.1.0
```

Or install individual packages as needed.

## Quick Start

```dart
import 'package:xmpp/xmpp.dart';

void main() async {
  final xmpp = Client(ClientOptions(
    service: 'wss://example.com:5281/xmpp-websocket',
    domain: 'example.com',
    username: 'user',
    password: 'password',
  ));

  xmpp.on<XmlElement>('stanza', (stanza) {
    print('Received: $stanza');
  });

  xmpp.on<dynamic>('online', (jid) {
    print('Connected as $jid');
  });

  await xmpp.start();

  // Send a message
  await xmpp.send(xml('message', {'to': 'friend@example.com', 'type': 'chat'}, [
    xml('body', {}, ['Hello from Dart!']),
  ]));

  // Disconnect
  await xmpp.stop();
}
```

## Development

### Building all packages

```bash
dart run scripts/build.dart
```

### Running tests

```bash
dart run scripts/test.dart
```

### Running analysis

```bash
dart run scripts/analyze.dart
```

## Cross-Language Testing

This library is tested for interoperability with xmpp.js:

- **JS Component + Dart Client**: Dart client connects to JS server component
- **Dart Component + JS Client**: JS client connects to Dart server component

## License

MIT

## Related Projects

- [xmpp.js](https://github.com/xmppjs/xmpp.js) - JavaScript XMPP library (reference implementation)
