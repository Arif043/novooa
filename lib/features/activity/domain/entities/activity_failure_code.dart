/// Stabile Ursache eines gescheiterten Bausteins, wie sie die Runtime
/// speichert (`LanguageModelFailure` im Backend). Übersetzt wird in der
/// Presentation.
enum ActivityFailureCode {
  outputSchemaViolated,
  responseTruncated,
  emptyResponse,
  providerUnavailable,
  requestRejected,
  timedOut,
  capabilityMissing,

  /// Ein Wert passt nicht zum Vergleich einer Bedingung; die Felder
  /// `operator`, `expected` und `received` stehen in den Details.
  conditionOperandMismatch;

  /// Unbekannte Codes (auch `unknown`) ergeben `null`: dann zählt nur der
  /// gespeicherte Text.
  static ActivityFailureCode? fromName(Object? name) {
    for (final code in values) {
      if (code.name == name) return code;
    }
    return null;
  }
}
