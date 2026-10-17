export const languageModelFailureCodes = [
  "outputSchemaViolated",
  "responseTruncated",
  "emptyResponse",
  "providerUnavailable",
  "requestRejected",
  "timedOut",
  "capabilityMissing",
  "unknown",
] as const;

export type LanguageModelFailureCode = (typeof languageModelFailureCodes)[number];

/**
 * Ein Modellaufruf ist gescheitert. `code` ist stabil und wird im Client übersetzt;
 * `message` ist der deutsche Rückfalltext für Protokoll und ältere Clients.
 */
export class LanguageModelFailure {
  constructor(
    readonly code: LanguageModelFailureCode,
    readonly message: string,
  ) {}
}
