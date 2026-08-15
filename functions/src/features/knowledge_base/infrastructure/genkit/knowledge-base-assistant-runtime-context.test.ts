import assert from "node:assert/strict";
import test from "node:test";
import {AssistantActor} from "../../../assistant/domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {
  assistantActorIdFromContext,
  genkitContextFrom,
} from "./knowledge-base-assistant-runtime-context.js";

test("passes the domain actor to Genkit tools without Firebase auth", () => {
  const context = new AssistantExecutionContext(new AssistantActor("user-1"));

  const genkitContext = genkitContextFrom(context);

  assert.equal(assistantActorIdFromContext(genkitContext), "user-1");
  assert.equal("auth" in genkitContext, false);
});

test("rejects a Genkit tool context without an actor", () => {
  assert.throws(() => assistantActorIdFromContext({}));
});
