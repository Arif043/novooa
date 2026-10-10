import assert from "node:assert/strict";
import test from "node:test";
import {genkit} from "genkit/beta";
import {taskDefinitionSchema} from "./task-definition.js";
import {executeTaskGraph} from "./task-graph-runner.js";

const silentLogger = {info() {}, error() {}, exception() {}, readableInfo() {}, readableError() {}};

const read = {
  id: "lesen", primitive: "readWebhook", title: "Webhook", description: "", outputs: [{key: "value", name: "ereignis", showOnCanvas: true}, {key: "method", name: "Methode", showOnCanvas: false}], config: {primitive: "readWebhook"},
};
const follow = {
  id: "danach", primitive: "stringInput", title: "Danach", description: "", outputs: [{key: "value", name: "danach", showOnCanvas: true}],
  config: {primitive: "stringInput", value: "Bestellung {{ereignis.bestellung}} per {{Methode}}"},
};

function run(input: Record<string, unknown> | undefined) {
  const taskDefinition = taskDefinitionSchema.parse({
    id: "t", title: "T", objective: "", nodes: [read, follow], edges: [{from: "lesen", to: "danach"}],
  });
  return executeTaskGraph(genkit({}), {taskDefinition, context: "", teamId: "team-1", input}, {logger: silentLogger} as never);
}

test("im echten Runner sind die Felder des Webhook-Inhalts in Folgebausteinen als {{ereignis.feld}} nutzbar, weitere Werte unter ihrem Namen", async () => {
  const output = await run({event: {type: "webhookReceived", method: "POST", query: {}, headers: {}, body: {bestellung: 42}, receivedAt: "2026-10-05T10:00:00.000Z"}});
  assert.equal(output.isOk(), true, output.isErr() ? String(output.error.cause) : "");
  assert.ok(JSON.stringify(output._unsafeUnwrap()).includes("Bestellung 42 per POST"));
});

test("ohne Webhook-Ereignis scheitert der Lauf mit verständlicher Meldung", async () => {
  const output = await run(undefined);
  assert.equal(output.isErr(), true);
  assert.match(output._unsafeUnwrapErr().failedNode.message, /nicht durch einen Webhook gestartet/);
});
