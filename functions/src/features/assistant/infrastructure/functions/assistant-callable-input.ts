import {z} from "genkit";
import {AssistantMessage} from "../../domain/entities/assistant-message.js";
import {AssistantRequest} from "../../domain/entities/assistant-request.js";

const messageSchema = z.object({
  role: z.enum(["user", "agent"]),
  text: z.string().max(12000),
});

export const assistantCallableInputSchema = z.object({
  question: z.string().min(1).max(12000),
  history: z.array(messageSchema).max(8),
});

export type AssistantCallableInput = z.infer<typeof assistantCallableInputSchema>;

export function assistantRequestFromInput(
  input: AssistantCallableInput,
): AssistantRequest {
  return new AssistantRequest(
    input.question,
    input.history.map(({role, text}) => new AssistantMessage(role, text)),
  );
}
