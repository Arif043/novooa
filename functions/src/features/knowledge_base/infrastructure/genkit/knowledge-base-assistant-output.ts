import {z} from "genkit";
import {
  type KnowledgeBaseAssistantCommand,
  type KnowledgeBaseAssistantResponse,
} from "../../domain/entities/knowledge-base-assistant-response.js";

const commandTypeSchema = z.enum([
  "createKnowledgeNote",
  "updateKnowledgeNote",
  "deleteKnowledgeNote",
]);

const rawKnowledgeCommandSchema = z.object({
  type: commandTypeSchema,
  label: z.string().optional(),
  noteId: z.string().optional(),
  title: z.string().optional(),
  content: z.string().optional(),
});

export const rawAssistantOutputSchema = z.object({
  answer: z.string(),
  commands: z.array(z.unknown()).optional(),
  knowledgeCommands: z.array(z.unknown()).optional(),
});

const knowledgeCommandSchema = rawKnowledgeCommandSchema.extend({
  label: z.string(),
});

export const knowledgeBaseAssistantOutputSchema = z.object({
  answer: z.string(),
  commands: z.array(z.object({type: z.string(), label: z.string()}).passthrough()),
  knowledgeCommands: z.array(knowledgeCommandSchema),
});

type KnowledgeCommand = KnowledgeBaseAssistantCommand;
type RawKnowledgeCommand = z.infer<typeof rawKnowledgeCommandSchema>;

/**
 * `output` stammt aus Genkits strukturiertem Ausgabe-Pfad (`ai.generate`
 * mit `output: {schema: rawAssistantOutputSchema}`), der ```json-Codezäune
 * und ähnliche Formatierungen schwacher (z. B. lokaler) Modelle bereits
 * robust herausgelöst hat. `text` dient nur noch als Fallback, falls die
 * Modellantwort gar keine gültige JSON-Struktur enthielt.
 */
export function assistantOutputFromModelOutput(
  output: unknown,
  text: string,
): KnowledgeBaseAssistantResponse {
  const parsed = rawAssistantOutputSchema.safeParse(output);
  if (!parsed.success) return emptyOutput(text);
  return {
    answer: parsed.data.answer,
    commands: [],
    knowledgeCommands: (parsed.data.knowledgeCommands ?? [])
        .map(knowledgeCommandFrom)
        .filter(isKnowledgeCommand),
  };
}

function emptyOutput(text: string): KnowledgeBaseAssistantResponse {
  return {answer: text, commands: [], knowledgeCommands: []};
}

function knowledgeCommandFrom(value: unknown): KnowledgeCommand | null {
  const candidate = rawKnowledgeCommandSchema.safeParse(value);
  if (!candidate.success) return null;
  if (candidate.data.type === "createKnowledgeNote") {
    return createCommand(candidate.data);
  }
  if (candidate.data.type === "updateKnowledgeNote") {
    return updateCommand(candidate.data);
  }
  return deleteCommand(candidate.data);
}

function createCommand(command: RawKnowledgeCommand): KnowledgeCommand | null {
  if (!hasText(command.title) || !hasText(command.content)) return null;
  return {...command, label: command.label ?? `Notiz „${command.title}“ erstellen`};
}

function updateCommand(command: RawKnowledgeCommand): KnowledgeCommand | null {
  if (!hasText(command.noteId) || !hasText(command.title) || !hasText(command.content)) {
    return null;
  }
  return {...command, label: command.label ?? `Notiz „${command.title}“ aktualisieren`};
}

function deleteCommand(command: RawKnowledgeCommand): KnowledgeCommand | null {
  if (!hasText(command.noteId)) return null;
  return {...command, label: command.label ?? "Notiz löschen"};
}

function hasText(value: string | undefined): value is string {
  return (value?.trim().length ?? 0) > 0;
}

function isKnowledgeCommand(value: KnowledgeCommand | null): value is KnowledgeCommand {
  return value !== null;
}
