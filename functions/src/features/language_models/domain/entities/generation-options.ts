export const thinkingModes = ["modelDefault", "off", "low", "medium", "high"] as const;

/** Wie stark das Modell vor der Antwort nachdenkt; `modelDefault` überlässt es dem Modell. */
export type ThinkingMode = (typeof thinkingModes)[number];

export class InvalidGenerationOptionError extends Error {}

/** Zufälligkeit der Antwort, 0 (bestimmt) bis 2 (frei). */
export class Temperature {
  private constructor(readonly value: number) {}

  static of(value: number): Temperature {
    if (!Number.isFinite(value) || value < 0 || value > 2) {
      throw new InvalidGenerationOptionError("Die Temperatur muss zwischen 0 und 2 liegen.");
    }
    return new Temperature(value);
  }
}

/** Eine Anzahl Tokens, z. B. die maximale Antwortlänge oder das Kontextfenster. */
export class TokenLimit {
  private constructor(readonly value: number) {}

  static of(value: number): TokenLimit {
    if (!Number.isInteger(value) || value < 1 || value > 10_000_000) {
      throw new InvalidGenerationOptionError("Eine Token-Angabe muss eine ganze Zahl größer als 0 sein.");
    }
    return new TokenLimit(value);
  }
}

/** Optionen eines Modellaufrufs. Fehlt eine Angabe, gilt der Standard des Modells. */
export type GenerationOptions = {
  temperature?: Temperature;
  maxOutputTokens?: TokenLimit;
  /** Nur bei Anbietern mit einstellbarem Fenster (Ollama); sonst ohne Wirkung. */
  contextWindow?: TokenLimit;
  thinking: ThinkingMode;
};

export const defaultGenerationOptions: GenerationOptions = {thinking: "modelDefault"};

export type GenerationOptionsRecord = {
  temperature?: number;
  maxOutputTokens?: number;
  contextWindow?: number;
  thinking?: ThinkingMode;
};

/** Baut die Optionen aus gespeicherten Werten und lehnt ungültige ab. */
export function generationOptionsFrom(record: GenerationOptionsRecord | undefined): GenerationOptions {
  if (record === undefined) return defaultGenerationOptions;
  return {
    temperature: optional(record.temperature, (value) => Temperature.of(value)),
    maxOutputTokens: optional(record.maxOutputTokens, (value) => TokenLimit.of(value)),
    contextWindow: optional(record.contextWindow, (value) => TokenLimit.of(value)),
    thinking: record.thinking ?? "modelDefault",
  };
}

function optional<T>(value: number | undefined, create: (value: number) => T): T | undefined {
  return value === undefined ? undefined : create(value);
}
