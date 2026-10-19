import {type GenerationOptionsRecord} from "../../../language_models/domain/entities/generation-options.js";
import {type KnowledgeAttachment, type NodeAttachment} from "./attachments.js";
import {type StructuredOutputField} from "./task.js";

/** Höchstens so viele Mitarbeiter arbeiten in einem Baustein „Teamarbeit“ zusammen. */
export const maximumTeamMembers = 5;

/** Textformate, die Agenten als Ergebnisdatei schreiben können. */
export const outputFileFormats = ["markdown", "csv", "json", "text"] as const;
export type OutputFileFormat = (typeof outputFileFormats)[number];

export const outputFileContentTypes: Record<OutputFileFormat, string> = {
  markdown: "text/markdown", csv: "text/csv", json: "application/json", text: "text/plain",
};

/**
 * Ein Mitarbeiter im Team: `responsibility` steht im Baustein, nicht beim Mitarbeiter, weil sie
 * je Aufgabe verschieden ist. Sie wird die Beschreibung des Delegations-Werkzeugs.
 */
export type TeamMember = {
  employeeId: string;
  responsibility: string;
  languageModelId?: string;
};

/** Ein Feld des Endergebnisses; `file` verweist auf eine Textdatei, die das Team geschrieben hat. */
export type TeamworkOutputField =
  | StructuredOutputField
  | {name: string; description: string; type: "file"; fileFormat: OutputFileFormat};

export type TeamworkNodeConfig = {
  primitive: "teamwork";
  /** Anweisung an den Orchestrator. */
  instruction: string;
  /** Modell des Orchestrators; leer = Standardmodell. */
  languageModelId?: string;
  generationOptions?: GenerationOptionsRecord;
  members: TeamMember[];
  outputFields: TeamworkOutputField[];
  attachments: NodeAttachment[];
  knowledgeAttachments: KnowledgeAttachment[];
};
