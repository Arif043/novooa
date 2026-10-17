import {type GenerationOptions} from "../../../domain/entities/generation-options.js";

/** Übersetzt die anbieterneutralen Optionen in die Genkit-Konfiguration eines Anbieters (Strategy). */
export interface GenkitGenerationConfig {
  configFor(options: GenerationOptions): Record<string, unknown>;
}

/** Entfernt fehlende Werte, damit der Anbieter seinen eigenen Standard nimmt. */
export function definedEntries(config: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(Object.entries(config).filter(([, value]) => value !== undefined));
}
