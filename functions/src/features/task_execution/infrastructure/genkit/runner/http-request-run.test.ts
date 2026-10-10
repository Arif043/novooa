import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {type OutboundHttpClient, type OutboundHttpRequest} from "../../../../connections/domain/repositories/outbound-http-client.js";
import {taskDefinitionSchema} from "./task-definition.js";
import {executeTaskGraph} from "./task-graph-runner.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

const input = {id: "kunde", primitive: "stringInput", title: "Kunde", description: "", outputs: [{key: "value", name: "kunde", showOnCanvas: true}], config: {primitive: "stringInput", value: "Anna"}};
const request = {
  id: "abruf", primitive: "httpRequest", title: "Abruf", description: "", outputs: [{key: "value", name: "antwort", showOnCanvas: true}, {key: "status", name: "Status", showOnCanvas: false}, {key: "ok", name: "Erfolgreich", showOnCanvas: false}],
  config: {primitive: "httpRequest", connectionId: "c1", url: "/customers/{{kunde}}", headers: [{name: "X-Kunde", value: "{{kunde}}"}]},
};
const follow = {
  id: "danach", primitive: "stringInput", title: "Danach", description: "", outputs: [{key: "value", name: "danach", showOnCanvas: true}],
  config: {primitive: "stringInput", value: "{{antwort.name}} ({{Status}}, ok={{Erfolgreich}})"},
};

function taskWith(nodes: unknown[]) {
  const edges = nodes.slice(1).map((node, index) => ({from: (nodes[index] as {id: string}).id, to: (node as {id: string}).id}));
  // Wie im Betrieb: Die Definition läuft vor der Ausführung durchs Schema, das die Standardwerte ergänzt.
  const taskDefinition = taskDefinitionSchema.parse({id: "t", title: "T", objective: "", nodes, edges});
  return {taskDefinition, context: "", teamId: "team-1"} as never;
}

test("der Dienst erreicht den Baustein im echten Runner; Antwortfelder sind als {{antwort.feld}}, Status und ok unter ihren Namen nutzbar", async () => {
  const sent: OutboundHttpRequest[] = [];
  const outboundHttpClient: OutboundHttpClient = {
    send: (call) => { sent.push(call); return Promise.resolve({status: 200, headers: {}, body: '{"name":"Anna Muster"}'}); },
  };

  const outputOrFailure = await executeTaskGraph(genkit({}), taskWith([input, request, follow]), {logger: silentLogger, outboundHttpClient} as never);

  assert.equal(outputOrFailure.isOk(), true, outputOrFailure.isErr() ? String(outputOrFailure.error.cause) : "");
  assert.equal(sent.length, 1);
  assert.equal(sent[0].url, "/customers/Anna");
  assert.deepEqual(sent[0].headers, {"X-Kunde": "Anna"});
  assert.equal(sent[0].connectionId, "c1");
  const finalOutput = JSON.stringify(outputOrFailure._unsafeUnwrap());
  assert.ok(finalOutput.includes("Anna Muster (200, ok=true)"), finalOutput);
});

test("ohne Dienst (Cloud) scheitert der Baustein mit einer verständlichen Meldung statt mit einem Absturz", async () => {
  const outputOrFailure = await executeTaskGraph(genkit({}), taskWith([request]), {logger: silentLogger} as never);

  assert.equal(outputOrFailure.isErr(), true);
  assert.match(outputOrFailure._unsafeUnwrapErr().failedNode.message, /nicht verfügbar/);
});
