import {z} from "genkit";

/** Schemas, die mehrere Baustein-Konfigurationen teilen (Prompt, Teamarbeit, Script, …). */
export const structuredOutputFieldTypeSchema = z.enum([
  "string",
  "number",
  "boolean",
  "datetime",
  "json",
]);

export const structuredOutputFieldSchema = z.object({
  name: z.string().default(""),
  description: z.string().default(""),
  type: structuredOutputFieldTypeSchema.default("string"),
});

export const nodeAttachmentSchema = z.object({
  id: z.string().min(1),
  storagePath: z.string().min(1),
  generation: z.string().min(1),
  displayName: z.string().min(1),
  contentType: z.string().default("application/octet-stream"),
  sizeBytes: z.number().int().nonnegative().default(0),
  versionCreatedAt: z.number().int().nonnegative().optional(),
});

export const knowledgeAttachmentSchema = z.object({
  knowledgeBaseId: z.string().min(1).default("default"),
  noteId: z.string().min(1),
  title: z.string().min(1),
  path: z.string().default(""),
});

/** Verweis auf einen Skill im Skills-Ordner; `name` ist der Ordnername, `description` nur zur Anzeige. */
export const skillAttachmentSchema = z.object({
  name: z.string().min(1),
  description: z.string().default(""),
});
