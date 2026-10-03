/** Welches Modell der KI-Agent nutzt, solange die Cloud es festlegt. */
export interface AssistantModelSettings {
  /** Der Modellname oder `null`, wenn nichts (Gültiges) hinterlegt ist. */
  modelName(): Promise<string | null>;
}
