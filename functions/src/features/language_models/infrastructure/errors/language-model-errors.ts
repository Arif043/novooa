/**
 * Unsere Fehler eines Modellaufrufs. Adapter werfen sie direkt; Framework-Fehler (Genkit, fetch)
 * werden vorher von `translateGenkitError` in eine davon umgewandelt.
 */
export abstract class LanguageModelError extends Error {
  /** Der ursprüngliche Framework-Fehler, falls dieser Fehler aus einer Übersetzung stammt. */
  readonly originalError?: unknown;

  constructor(message: string, originalError?: unknown) {
    super(message);
    this.name = new.target.name;
    this.originalError = originalError;
  }
}

/** Die Antwort passt nicht zur verlangten Ausgabestruktur. */
export class ModelOutputSchemaError extends LanguageModelError {}

/** Das Modell hat aufgehört, weil das Kontextfenster oder die Antwortlänge erschöpft war. */
export class ModelResponseTruncatedError extends LanguageModelError {}

/** Das Modell hat keine Antwort geschrieben, z. B. nur nachgedacht. */
export class ModelEmptyResponseError extends LanguageModelError {}

/** Der Anbieter ist nicht erreichbar oder meldet einen Serverfehler. */
export class ModelProviderUnavailableError extends LanguageModelError {}

/** Der Anbieter hat die Anfrage abgelehnt (4xx), z. B. ungültige Optionen oder fehlende Berechtigung. */
export class ModelRequestRejectedError extends LanguageModelError {}

/** Der Anbieter hat nicht rechtzeitig geantwortet. */
export class ModelTimeoutError extends LanguageModelError {}

/** Das gewählte Modell kann die verlangte Ein- oder Ausgabe nicht (z. B. keine Bilder). */
export class ModelCapabilityMissingError extends LanguageModelError {}
