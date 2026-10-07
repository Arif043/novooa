import {z} from "genkit";
import {
  type TaskBuilderAssistantCommand,
  taskBuilderAssistantPrimitives,
  type TaskBuilderAssistantResponse,
} from "../../../domain/entities/task-builder-assistant-response.js";

const commandTypeSchema = z.enum(["renameTask", "addNode"]);
const primitiveSchema = z.enum(taskBuilderAssistantPrimitives);
const rawCommandSchema = z.object({
  type: commandTypeSchema,
  label: z.string().optional(),
  primitive: primitiveSchema.optional(),
  kind: z.enum(["email", "whatsapp", "sms"]).optional(),
  title: z.string().optional(),
  outputName: z.string().optional(),
  description: z.string().optional(),
  value: z.string().optional(),
  instruction: z.string().optional(),
  modelId: z.string().optional(),
  recipient: z.string().optional(),
  message: z.string().optional(),
  script: z.string().max(20000).optional(),
  inputTemplate: z.string().max(2000).optional(),
});

export const rawOutputSchema = z.object({
  answer: z.string(),
  commands: z.array(z.unknown()).optional(),
  knowledgeCommands: z.array(z.unknown()).optional(),
});

const commandSchema = rawCommandSchema.extend({label: z.string()});

export const taskBuilderAssistantOutputSchema = z.object({
  answer: z.string(),
  commands: z.array(commandSchema),
  knowledgeCommands: z.array(z.object({type: z.string(), label: z.string()})),
});

type RawCommand = z.infer<typeof rawCommandSchema>;

/**
 * `output` stammt aus Genkits strukturiertem Ausgabe-Pfad (`ai.generate`
 * mit `output: {schema: rawOutputSchema}`), der ```json-Codezäune und
 * ähnliche Formatierungen schwacher (z. B. lokaler) Modelle bereits robust
 * herausgelöst hat. `text` dient nur noch als Fallback, falls die
 * Modellantwort gar keine gültige JSON-Struktur enthielt.
 */
export function taskBuilderOutputFromModelOutput(
  output: unknown,
  text: string,
): TaskBuilderAssistantResponse {
  const parsed = rawOutputSchema.safeParse(output);
  if (!parsed.success) return emptyOutput(text);
  return {
    answer: parsed.data.answer,
    commands: (parsed.data.commands ?? []).map(commandFrom).filter(isCommand),
    knowledgeCommands: [],
  };
}

function emptyOutput(text: string): TaskBuilderAssistantResponse {
  return {answer: text, commands: [], knowledgeCommands: []};
}

function commandFrom(value: unknown): TaskBuilderAssistantCommand | null {
  const candidate = rawCommandSchema.safeParse(value);
  if (!candidate.success) return null;
  return candidate.data.type === "renameTask" ? renameCommand(candidate.data) : addNodeCommand(candidate.data);
}

function renameCommand(command: RawCommand): TaskBuilderAssistantCommand | null {
  if (!hasText(command.title)) return null;
  return {...command, label: command.label ?? `Aufgabe „${command.title}“ umbenennen`};
}

function addNodeCommand(command: RawCommand): TaskBuilderAssistantCommand | null {
  if (!command.primitive) return null;
  return {...command, label: command.label ?? `Baustein „${command.primitive}“ hinzufügen`};
}

function hasText(value: string | undefined): value is string {
  return (value?.trim().length ?? 0) > 0;
}

function isCommand(
  command: TaskBuilderAssistantCommand | null,
): command is TaskBuilderAssistantCommand {
  return command !== null;
}
