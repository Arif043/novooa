import {type GenerationOptions} from "../../../language_models/domain/entities/generation-options.js";
import {type TeamworkOutputField} from "./teamwork-config.js";

/** Was der Orchestrator für einen Lauf braucht; Mitarbeiter und Arbeitsordner kommen aus dem Workspace. */
export type TeamworkExecutionRequest = {
  teamId: string;
  instruction: string;
  languageModelId?: string;
  generationOptions: GenerationOptions;
  outputFields: TeamworkOutputField[];
  mediaUrls: string[];
};

/**
 * Das Endergebnis des Orchestrators je Feld, noch roh: Werte wie vom Modell geliefert, bei Datei-Feldern
 * der Pfad im Arbeitsordner. Zu Workflow-Werten werden sie erst im Node-Executor.
 */
export type TeamworkExecutionResult = {
  answer: string;
  fields: Record<string, unknown>;
};
