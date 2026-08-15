import {type ActionContext} from "genkit";
import {AssistantActor} from "../../domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../domain/entities/assistant-execution-context.js";

export function assistantExecutionContextFrom(
  context: ActionContext | undefined,
): AssistantExecutionContext {
  const auth = (context as {auth?: {uid?: string}} | undefined)?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return new AssistantExecutionContext(new AssistantActor(auth.uid));
}
