import {type LlmOutputSpec} from "../../../domain/prompting/llm-gateway.js";

export type LlmCallStarted = {
  label: string;
  model: unknown;
  /** Gerenderter Prompt — genau der Text, den das Modell bekommt. */
  system?: string;
  user: string;
  output: LlmOutputSpec;
  mediaCount: number;
  options: Record<string, unknown>;
};

export type LlmCallFinished = {
  label: string;
  durationMs: number;
  text: string;
  data?: unknown;
  mediaUrl?: string;
};

/** Wohin das Protokoll eines Aufrufs geht; das Format bestimmt der Nutzer des Frameworks. */
export interface LlmCallLog {
  started(entry: LlmCallStarted): void;
  finished(entry: LlmCallFinished): void;
}

/** Für Aufrufe ohne Protokoll, z. B. die In-App-Agenten. */
export const silentLlmCallLog: LlmCallLog = {
  started: () => undefined,
  finished: () => undefined,
};
