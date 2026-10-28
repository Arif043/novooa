import {type GenerateOptions, type ModelArgument} from "genkit";
import {type GenkitBeta} from "genkit/beta";

/**
 * Was die Domain als `Binding` nicht kennt: Genkit-Instanz, Modell, anbieterspezifische
 * Konfiguration und Middleware (Retry, Dateisystem, Skills). Baut die Aufrufstelle.
 */
export type GenkitLlmBinding = {
  ai: GenkitBeta;
  model: ModelArgument;
  /** Aus den Generierungsoptionen übersetzte Konfiguration; bei Bildern ersetzt der Gateway sie. */
  config: Record<string, unknown>;
  /** Wie das Modell im Protokoll heißt (Anbieter, Name). */
  logContext: unknown;
  use?: GenerateOptions["use"];
};
