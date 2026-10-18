/// Liest die Felder zu einem Fehlercode; nur Texteinträge zählen, alles
/// andere (auch ein fehlendes Feld) ergibt keine Details.
Map<String, String> failureDetailsFrom(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      if (entry.key is String && entry.value is String)
        entry.key as String: entry.value as String,
  };
}
