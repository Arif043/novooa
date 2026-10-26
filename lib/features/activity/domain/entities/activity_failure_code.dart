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
  conditionOperandMismatch,

  // Geschäftsfehler der Bausteine (`node-failures.ts` im Backend); ihre
  // Felder stehen in den Details.
  configurationMissing,
  settingMissing,
  settingInvalid,
  valueTypeMismatch,
  tensorShapeMismatch,
  modelOutputInvalid,
  triggerMismatch,
  capabilityUnavailable,
  httpBodyInvalidJson,
  httpStatusFailed,
  forEachUnsupported,
  scriptFailed,
  scriptOutputInvalid,
  scriptPackagesUnavailable,

  /// Der Baustein gehört zu einem deaktivierten Plugin (Detail `plugin`).
  pluginDisabled;

  /// Unbekannte Codes (auch `unknown`) ergeben `null`: dann zählt nur der
  /// gespeicherte Text.
  static ActivityFailureCode? fromName(Object? name) {
    for (final code in values) {
      if (code.name == name) return code;
    }
    return null;
  }
}
