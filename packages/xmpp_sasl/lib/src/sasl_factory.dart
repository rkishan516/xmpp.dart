import 'mechanism.dart';

/// Factory type for creating SASL mechanisms.
typedef MechanismFactory = SASLMechanism Function();

/// Entry for a registered mechanism.
class MechanismEntry {
  final String name;
  final MechanismFactory factory;

  MechanismEntry(this.name, this.factory);
}

/// SASL mechanism factory.
///
/// Registers and creates SASL mechanisms.
class SASLFactory {
  final List<MechanismEntry> _mechs = [];

  /// List of registered mechanism entries.
  List<MechanismEntry> get mechs => List.unmodifiable(_mechs);

  /// Register a mechanism.
  void use(String name, MechanismFactory factory) {
    _mechs.add(MechanismEntry(name, factory));
  }

  /// Create a mechanism instance.
  ///
  /// Takes a list of mechanism names to try (in preference order).
  /// Returns the first matching mechanism.
  SASLMechanism? create(List<String> mechanisms) {
    for (final mech in mechanisms) {
      final entry = _mechs.where((e) => e.name == mech).firstOrNull;
      if (entry != null) {
        return entry.factory();
      }
    }
    return null;
  }

  /// Get the names of all registered mechanisms.
  List<String> get mechanismNames => _mechs.map((e) => e.name).toList();
}
