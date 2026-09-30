import {testingRoutes} from "./local-runtime-http-test-support.js";
import assert from "node:assert/strict";
import test from "node:test";
import {LocalAssistantHttpHandler} from "./local-assistant-http-handler.js";
import {type TestRequest as LocalRuntimeRequest} from "./local-runtime-http-test-support.js";
import {type AssistantExecutionContext} from "../../features/assistant/domain/entities/assistant-execution-context.js";
import {type AssistantRequest} from "../../features/assistant/domain/entities/assistant-request.js";
import {type TaskBuilderAssistant} from "../../features/task_execution/domain/usecases/task-builder-assistant.js";
import {type TaskBuilderAssistantResponse} from "../../features/task_execution/domain/entities/task-builder-assistant-response.js";
import {type KnowledgeBaseAssistant} from "../../features/knowledge_base/domain/usecases/knowledge-base-assistant.js";
import {type KnowledgeBaseAssistantResponse} from "../../features/knowledge_base/domain/entities/knowledge-base-assistant-response.js";

// Deckt das lokale Pendant zu askTaskBuilderAssistant/askKnowledgeBaseAssistant
// ab: gleicher Anfrage-/Antwort-Vertrag, nur über die reguläre Runtime-API.

class FakeTaskBuilderAssistant implements TaskBuilderAssistant {
  lastRequest: AssistantRequest | null = null;
  lastContext: AssistantExecutionContext | null = null;

  async ask(
    request: AssistantRequest,
    context: AssistantExecutionContext,
  ): Promise<TaskBuilderAssistantResponse> {
    this.lastRequest = request;
    this.lastContext = context;
    return {answer: "Klar, hier ist ein Vorschlag.", commands: [], knowledgeCommands: []};
  }
}

class FakeKnowledgeBaseAssistant implements KnowledgeBaseAssistant {
  lastRequest: AssistantRequest | null = null;

  async ask(request: AssistantRequest): Promise<KnowledgeBaseAssistantResponse> {
    this.lastRequest = request;
    return {answer: "Notiz gefunden.", commands: [], knowledgeCommands: []};
  }
}

function handlerFor(
  taskBuilderAssistant: TaskBuilderAssistant,
  knowledgeBaseAssistant: KnowledgeBaseAssistant,
) {
  return testingRoutes(new LocalAssistantHttpHandler(
    async () => taskBuilderAssistant,
    async () => knowledgeBaseAssistant,
    "local-user",
  ));
}

function postRequest(url: string, body: unknown): LocalRuntimeRequest {
  return {method: "POST", url, body} as LocalRuntimeRequest;
}

test("beantwortet eine Aufgabenstudio-Frage und übergibt den lokalen Actor", async () => {
  const taskBuilderAssistant = new FakeTaskBuilderAssistant();
  const handler = handlerFor(taskBuilderAssistant, new FakeKnowledgeBaseAssistant());

  const response = await handler.handle(
    postRequest("/v1/assistant/task-builder", {question: "Wie baue ich eine Aufgabe?", history: []}),
  );

  assert.equal(response?.statusCode, 200);
  assert.deepEqual(response?.body, {
    answer: "Klar, hier ist ein Vorschlag.",
    commands: [],
    knowledgeCommands: [],
  });
  assert.equal(taskBuilderAssistant.lastRequest?.question, "Wie baue ich eine Aufgabe?");
  assert.equal(taskBuilderAssistant.lastContext?.actor.id, "local-user");
});

test("beantwortet eine Wissensbasis-Frage über den eigenen Endpunkt", async () => {
  const knowledgeBaseAssistant = new FakeKnowledgeBaseAssistant();
  const handler = handlerFor(new FakeTaskBuilderAssistant(), knowledgeBaseAssistant);

  const response = await handler.handle(
    postRequest("/v1/assistant/knowledge-base", {question: "Was steht in meinen Notizen?", history: []}),
  );

  assert.equal(response?.statusCode, 200);
  assert.equal(knowledgeBaseAssistant.lastRequest?.question, "Was steht in meinen Notizen?");
});

test("übernimmt den bisherigen Verlauf mit Rolle und Text", async () => {
  const taskBuilderAssistant = new FakeTaskBuilderAssistant();
  const handler = handlerFor(taskBuilderAssistant, new FakeKnowledgeBaseAssistant());

  await handler.handle(
    postRequest("/v1/assistant/task-builder", {
      question: "Und jetzt?",
      history: [
        {role: "user", text: "Erste Frage"},
        {role: "agent", text: "Erste Antwort"},
      ],
    }),
  );

  const history = taskBuilderAssistant.lastRequest?.history ?? [];
  assert.equal(history.length, 2);
  assert.equal(history[0]?.role, "user");
  assert.equal(history[0]?.text, "Erste Frage");
  assert.equal(history[1]?.role, "agent");
});

test("weist eine leere Frage zurück", async () => {
  const handler = handlerFor(new FakeTaskBuilderAssistant(), new FakeKnowledgeBaseAssistant());

  const response = await handler.handle(
    postRequest("/v1/assistant/task-builder", {question: "   ", history: []}),
  );

  assert.equal(response?.statusCode, 400);
});

test("weist einen zu langen Verlauf zurück", async () => {
  const handler = handlerFor(new FakeTaskBuilderAssistant(), new FakeKnowledgeBaseAssistant());
  const tooLong = Array.from({length: 9}, () => ({role: "user", text: "Frage"}));

  const response = await handler.handle(
    postRequest("/v1/assistant/task-builder", {question: "Frage", history: tooLong}),
  );

  assert.equal(response?.statusCode, 400);
});

test("weist eine ungültige Rolle im Verlauf zurück", async () => {
  const handler = handlerFor(new FakeTaskBuilderAssistant(), new FakeKnowledgeBaseAssistant());

  const response = await handler.handle(
    postRequest("/v1/assistant/task-builder", {
      question: "Frage",
      history: [{role: "system", text: "Unbekannte Rolle"}],
    }),
  );

  assert.equal(response?.statusCode, 400);
});

test("lässt unbeteiligte Pfade für andere Handler übrig", async () => {
  const handler = handlerFor(new FakeTaskBuilderAssistant(), new FakeKnowledgeBaseAssistant());

  const response = await handler.handle(
    {method: "GET", url: "/v1/tasks", body: {}} as LocalRuntimeRequest,
  );

  assert.equal(response, null);
});
