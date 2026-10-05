import assert from "node:assert/strict";
import test from "node:test";
import {type TaskRunContext} from "./node-executor.js";
import {readWebhookNodeExecutor} from "./read-webhook-node-executor.js";

const node = {id: "n1", primitive: "readWebhook", title: "Webhook", description: "", outputName: "ereignis", config: {primitive: "readWebhook"}} as never;

const event = {
  type: "webhookReceived", method: "POST", query: {a: "1"}, headers: {"x-test": "ja"},
  body: {bestellung: 42}, receivedAt: "2026-10-05T10:00:00.000Z",
};

const contextWith = (input: Record<string, unknown>) => ({input}) as unknown as TaskRunContext;

test("liefert Inhalt, Methode, Query, Kopfzeilen und Zeitpunkt als typisierte Werte", async () => {
  const result = await readWebhookNodeExecutor.execute(node, contextWith({event}));
  assert.deepEqual(result.outputs, {
    value: {type: "json", value: {bestellung: 42}},
    method: {type: "string", value: "POST"},
    query: {type: "json", value: {a: "1"}},
    headers: {type: "json", value: {"x-test": "ja"}},
    receivedAt: {type: "datetime", value: "2026-10-05T10:00:00.000Z"},
  });
});

test("ein Textinhalt bleibt Text und wird nicht als JSON in Anführungszeichen ausgegeben", async () => {
  const result = await readWebhookNodeExecutor.execute(node, contextWith({event: {...event, body: "Hallo"}}));
  assert.deepEqual(result.outputs.value, {type: "string", value: "Hallo"});
});

test("ein Lauf ohne Webhook meldet das verständlich", async () => {
  await assert.rejects(readWebhookNodeExecutor.execute(node, contextWith({})), /nicht durch einen Webhook gestartet/);
  await assert.rejects(
    readWebhookNodeExecutor.execute(node, contextWith({event: {type: "emailReceived"}})),
    /nicht durch einen Webhook gestartet/,
  );
});
