import assert from "node:assert/strict";
import test from "node:test";
import {AssistantActor} from "../../../assistant/domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {createKnowledgeBaseAssistant} from "./knowledge-base-assistant.js";

test("delegates knowledge-base requests through the supplied assistant responder", async () => {
  const requests: unknown[] = [];
  const assistant = createKnowledgeBaseAssistant({
    async respond(request, context) {
      requests.push({request, context});
      return {answer: "Erledigt", commands: [], knowledgeCommands: []};
    },
  });
  const request = new AssistantRequest("Durchsuche meine Notizen", []);
  const context = new AssistantExecutionContext(new AssistantActor("user-1"));

  const output = await assistant.ask(request, context);

  assert.deepEqual(output, {answer: "Erledigt", commands: [], knowledgeCommands: []});
  assert.deepEqual(requests, [{request, context}]);
});
