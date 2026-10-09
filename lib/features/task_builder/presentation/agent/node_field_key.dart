/// Felder eines Bausteins, die der Agent befüllen darf.
enum NodeFieldKey {
  title,
  description,
  outputName,
  value,
  instruction,
  modelId,
  recipient,
  message,
  script,
  inputTemplate;

  /// Felder mit sichtbarem Eingabefeld, in das der Cursor tippt.
  bool get isTypedByCursor => switch (this) {
    value || instruction || recipient || message || inputTemplate => true,
    _ => false,
  };

  static NodeFieldKey? parse(String name) {
    for (final key in values) {
      if (key.name == name) return key;
    }
    return null;
  }
}
