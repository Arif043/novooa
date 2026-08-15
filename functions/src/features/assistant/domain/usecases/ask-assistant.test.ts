import assert from "node:assert/strict";
import test from "node:test";
import {AssistantActor} from "../entities/assistant-actor.js";
import {AssistantExecutionContext} from "../entities/assistant-execution-context.js";
import {AssistantMessage} from "../entities/assistant-message.js";
import {AssistantRequest} from "../entities/assistant-request.js";
import {type AssistantResponder} from "../repositories/assistant-responder.js";
import {AskAssistant} from "./ask-assistant.js";

test("delegates a request and actor context to the responder", async () => {
  const responder = new FakeAssistantResponder();
  const useCase = new AskAssistant(responder);
  const request = new AssistantRequest("Erstelle eine Notiz.", []);
  const context = new AssistantExecutionContext(new AssistantActor("user-1"));

  const response = await useCase.execute(request, context);

  assert.equal(response, "Antwort");
  assert.equal(responder.actorId, "user-1");
});

class FakeAssistantResponder implements AssistantResponder<string> {
  actorId = "";

  async respond(
    request: AssistantRequest,
    context: AssistantExecutionContext,
  ): Promise<string> {
    assert.equal(request.question, "Erstelle eine Notiz.");
    assert.deepEqual(request.history, [] as AssistantMessage[]);
    this.actorId = context.actor.id;
    return "Antwort";
  }
}
