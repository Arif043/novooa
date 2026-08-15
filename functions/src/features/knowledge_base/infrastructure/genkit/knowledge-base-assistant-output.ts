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

const rawAssistantOutputSchema = z.object({
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

export function assistantOutputFromText(
  text: string,
): KnowledgeBaseAssistantResponse {
  const rawOutput = rawOutputFrom(text);
  if (!rawOutput) return emptyOutput(text);
  return {
    answer: rawOutput.answer,
    commands: [],
    knowledgeCommands: (rawOutput.knowledgeCommands ?? [])
        .map(knowledgeCommandFrom)
        .filter(isKnowledgeCommand),
  };
}

function rawOutputFrom(text: string) {
  try {
    return rawAssistantOutputSchema.parse(JSON.parse(text));
  } catch (_) {
    return null;
  }
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
