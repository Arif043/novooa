import assert from "node:assert/strict";
import test, {afterEach} from "node:test";
import {AssistantActor} from "../../../assistant/domain/entities/assistant-actor.js";
import {AssistantExecutionContext} from "../../../assistant/domain/entities/assistant-execution-context.js";
import {AssistantMessage} from "../../../assistant/domain/entities/assistant-message.js";
import {AssistantRequest} from "../../../assistant/domain/entities/assistant-request.js";
import {type SignedRuntimeLicense} from "../../../licensing/domain/entities/runtime-license-lease.js";
import {createLocalTaskBuilderAssistant} from "./local-task-builder-assistant.js";
import {HttpRuntimeTaskBuilderRelayClient, UnavailableRuntimeTaskBuilderRelayClient} from "./runtime-task-builder-relay-client.js";

const license: SignedRuntimeLicense = {
  signature: "sig",
  payload: {licenseId: "l", licenseName: "n", activationId: "a", workspaceId: "w", issuedAt: "2026-01-01", expiresAt: "2027-01-01"},
};
const originalFetch = globalThis.fetch;
afterEach(() => { globalThis.fetch = originalFetch; });

function respondWith(status: number, body: unknown) {
  const calls: unknown[] = [];
  globalThis.fetch = (async (_url: URL | string, init?: RequestInit) => {
    calls.push(JSON.parse(String(init?.body)));
    return new Response(JSON.stringify(body), {status});
  }) as typeof fetch;
  return calls;
}

const input = {question: "Baue mir eine Aufgabe", history: [{role: "user" as const, text: "Hallo"}]};

test("schickt Lizenz, Frage und Verlauf und liefert die Antwort der Cloud", async () => {
  const calls = respondWith(200, {answer: "Okay", commands: [{type: "renameTask", title: "Neu"}], knowledgeCommands: []});

  const response = await new HttpRuntimeTaskBuilderRelayClient("https://relay.example/t").ask(license, input);

  assert.equal(response.answer, "Okay");
  assert.equal(response.commands.length, 1);
  assert.deepEqual(calls[0], {license, ...input});
});

test("eine abgelehnte Anfrage und eine ungültige Antwort sind Fehler", async () => {
  respondWith(401, {error: "abgelehnt"});
  await assert.rejects(new HttpRuntimeTaskBuilderRelayClient("https://relay.example/t").ask(license, input), /abgelehnt/);

  respondWith(200, {answer: 1});
  await assert.rejects(new HttpRuntimeTaskBuilderRelayClient("https://relay.example/t").ask(license, input), /ungültige Antwort/);
});

test("das Relay muss HTTPS verwenden", () => {
  assert.throws(() => new HttpRuntimeTaskBuilderRelayClient("http://relay.example/t"), /HTTPS/);
});

test("ohne Relay-URL meldet der Client, dass der Agent nicht konfiguriert ist", async () => {
  await assert.rejects(new UnavailableRuntimeTaskBuilderRelayClient().ask(), /nicht konfiguriert/);
});

test("der lokale Aufgabenstudio-Agent reicht Frage und Verlauf an die Cloud weiter", async () => {
  const seen: unknown[] = [];
  const relay = {ask: async (_license: SignedRuntimeLicense, request: unknown) => {
    seen.push(request);
    return {answer: "Antwort", commands: [], knowledgeCommands: []};
  }};
  const assistant = createLocalTaskBuilderAssistant(() => license, relay);

  const answer = await assistant.ask(
    new AssistantRequest("Frage", [new AssistantMessage("agent", "Vorher")]),
    new AssistantExecutionContext(new AssistantActor("u")),
  );

  assert.equal(answer.answer, "Antwort");
  assert.deepEqual(seen[0], {question: "Frage", history: [{role: "agent", text: "Vorher"}]});
});

test("ohne aktive Lizenz fragt die Runtime die Cloud nicht", async () => {
  let called = false;
  const relay = {ask: async () => { called = true; return {answer: "", commands: [], knowledgeCommands: []}; }};
  const assistant = createLocalTaskBuilderAssistant(() => null, relay);

  await assert.rejects(
    assistant.ask(new AssistantRequest("Frage", []), new AssistantExecutionContext(new AssistantActor("u"))),
    /keine aktive Lizenz/,
  );
  assert.equal(called, false);
});
