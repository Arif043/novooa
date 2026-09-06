import {AssistantActor} from "../../domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../domain/entities/assistant-execution-context.js";

export function assistantExecutionContextFrom(
  context: {auth?: {uid?: string}} | undefined,
): AssistantExecutionContext {
  const auth = context?.auth;
  if (!auth?.uid) throw new Error("Auth context is missing.");
  return new AssistantExecutionContext(new AssistantActor(auth.uid));
}
