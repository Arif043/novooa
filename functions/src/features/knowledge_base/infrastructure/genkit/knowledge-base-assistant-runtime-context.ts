import {type ActionContext} from "genkit";
import {type AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";

export function genkitContextFrom(
  context: AssistantExecutionContext,
): ActionContext {
  return {assistant: {actorId: context.actor.id}};
}

export function assistantActorIdFromContext(context: unknown): string {
  const actorId = (context as AssistantGenkitContext | undefined)
    ?.assistant?.actorId;
  if (!actorId) throw new Error("Assistant actor context is missing.");
  return actorId;
}

type AssistantGenkitContext = {
  assistant?: {actorId?: string};
};
