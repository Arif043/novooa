import {type LlmPrompt} from "./llm-prompt.js";

export type LlmStructuredFieldType = "string" | "number" | "boolean" | "datetime" | "json";

export type LlmStructuredField = {
  readonly name: string;
  readonly description: string;
  readonly type: LlmStructuredFieldType;
  /** Text darf leer bleiben, z. B. die Befunde einer Prüfung, die nichts beanstandet. */
  readonly allowEmpty?: boolean;
};

/** Was der Aufruf liefern soll; das Schema dazu baut der Adapter, nicht die Aufrufstelle. */
export type LlmOutputSpec =
  | {readonly kind: "text"}
  | {readonly kind: "choice"; readonly choices: readonly string[]}
  | {readonly kind: "structured"; readonly fields: readonly LlmStructuredField[]}
  | {readonly kind: "image"}
  /**
   * Ein fertiges Schema der Infrastruktur (z. B. Zod) für Ausgaben, die sich nicht als einfache Felder
   * beschreiben lassen, etwa Commands der Agenten. Für die Domain opak.
   */
  | {readonly kind: "schema"; readonly schema: unknown};

/**
 * Ein Aufruf eines Sprachmodells. `Binding` ist für die Domain opak: Modell, Konfiguration und
 * Werkzeuge stellt die Infrastruktur (z. B. Genkit) bereit.
 */
export type LlmRequest<Binding> = {
  readonly binding: Binding;
  readonly prompt: LlmPrompt;
  /** Lesbare Bezeichnung für das Protokoll, z. B. „Prompt / Text (Mitarbeiter: Rezeption)“. */
  readonly label: string;
  readonly output: LlmOutputSpec;
};

export type LlmResponse = {
  readonly text: string;
  /** Gewählte Option (`choice`) oder Objekt mit den Feldern (`structured`). */
  readonly data?: unknown;
  /** Data-URL des erzeugten Bilds (`image`). */
  readonly mediaUrl?: string;
  /**
   * Gesprächsstand nach dem Aufruf (inklusive Werkzeugaufrufen), um ihn fortzusetzen. Für die Domain
   * opak — nur der Adapter, der ihn geliefert hat, versteht ihn.
   */
  readonly conversation?: unknown;
};

/** Der eine Weg zu einem Sprachmodell; Protokoll und Fehlerübersetzung legen sich als Decorator darum. */
export interface LlmGateway<Binding> {
  generate(request: LlmRequest<Binding>): Promise<LlmResponse>;
}
