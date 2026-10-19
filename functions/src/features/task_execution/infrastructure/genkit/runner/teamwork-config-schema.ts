import {z} from "genkit";
import {maximumTeamMembers, outputFileFormats} from "../../../domain/entities/teamwork-config.js";
import {generationOptionsSchema} from "./generation-options-schema.js";
import {
  knowledgeAttachmentSchema,
  nodeAttachmentSchema,
  structuredOutputFieldSchema,
} from "./node-config-shared-schemas.js";

const teamMemberSchema = z.object({
  employeeId: z.string().min(1),
  responsibility: z.string().trim().min(1, "Gib für jeden Mitarbeiter an, wofür er zuständig ist.").max(500),
  languageModelId: z.string().optional(),
});

const fileOutputFieldSchema = z.object({
  name: z.string().default(""),
  description: z.string().default(""),
  type: z.literal("file"),
  fileFormat: z.enum(outputFileFormats).default("markdown"),
});

/** Ein Feld des Endergebnisses: ein Wert wie beim Prompt-Baustein oder eine Ergebnisdatei. */
export const teamworkOutputFieldSchema = z.union([fileOutputFieldSchema, structuredOutputFieldSchema]);

export const teamworkNodeConfigSchema = z.object({
  primitive: z.literal("teamwork").default("teamwork"),
  instruction: z.string().default(""),
  languageModelId: z.string().optional(),
  generationOptions: generationOptionsSchema.optional(),
  members: z.array(teamMemberSchema).max(maximumTeamMembers).default([])
    .refine(
      (members) => new Set(members.map((member) => member.employeeId)).size === members.length,
      "Ein Mitarbeiter kann nur einmal im Team sein.",
    ),
  outputFields: z.array(teamworkOutputFieldSchema).default([]),
  review: z.object({enabled: z.boolean(), languageModelId: z.string().optional()}),
  attachments: z.array(nodeAttachmentSchema).default([]),
  knowledgeAttachments: z.array(knowledgeAttachmentSchema).default([]),
});
