import {type GenerateOptions, type Genkit, type MessageData, type ModelArgument} from "genkit";

/**
 * Was die Domain als `Binding` nicht kennt: Genkit-Instanz, Modell, anbieterspezifische
 * Konfiguration und Middleware (Retry, Dateisystem, Skills). Baut die Aufrufstelle.
 */
export type GenkitLlmBinding = {
  /** Nur `generate` wird gebraucht; so passen `Genkit` wie `GenkitBeta`. */
  ai: Pick<Genkit, "generate">;
  model: ModelArgument;
  /** Aus den Generierungsoptionen übersetzte Konfiguration; bei Bildern ersetzt der Gateway sie. */
  config: Record<string, unknown>;
  /** Wie das Modell im Protokoll heißt (Anbieter, Name). */
  logContext: unknown;
  use?: GenerateOptions["use"];
  /** Werkzeuge, die das Modell aufrufen darf, z. B. die Aufträge an Mitarbeiter. */
  tools?: GenerateOptions["tools"];
  /** Höchstzahl der Modell-Runden mit Werkzeugaufrufen. */
  maxTurns?: number;
  /**
   * Bisheriges Gespräch (`LlmResponse.conversation` eines früheren Aufrufs). Es enthält den Systemteil
   * schon; der neue Prompt bringt dann nur die Folgenachricht.
   */
  continuation?: MessageData[];
  /** Aktionskontext für Werkzeuge, z. B. Team und Berechtigung des Agenten-Aufrufs. */
  context?: GenerateOptions["context"];
};
