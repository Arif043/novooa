import assert from "node:assert/strict";
import test from "node:test";
import {type TaskRunContext} from "./node-executor.js";
import {readChannelEventNodeExecutor} from "./read-email-node-executor.js";
import {succeeded} from "./node-executor-test-support.js";

const nodeWith = (kind: string) =>
  ({id: "n1", primitive: "readChannelEvent", title: "", description: "", outputs: [{key: "value", name: "Nachricht", showOnCanvas: true}],
    config: {primitive: "readChannelEvent", kind}}) as never;

const contextWith = (event: Record<string, unknown>) => ({input: {event}}) as unknown as TaskRunContext;

test("liefert den Nachrichtentext als Hauptwert und Absender, Betreff, Ankunftszeit als weitere Werte", async () => {
  const email = {
    type: "emailReceived", senderEmail: "kunde@example.com", subject: "Rechnung",
    message: "Anbei die Rechnung.", receivedAt: "2026-10-09T08:00:00.000Z",
  };

  const result = succeeded(await readChannelEventNodeExecutor.execute(nodeWith("email"), contextWith(email)));

  assert.deepEqual(result.outputs, {
    value: {type: "string", value: "Anbei die Rechnung."},
    sender: {type: "string", value: "kunde@example.com"},
    subject: {type: "string", value: "Rechnung"},
    receivedAt: {type: "datetime", value: "2026-10-09T08:00:00.000Z"},
  });
});

test("WhatsApp und SMS haben keinen Betreff", async () => {
  const sms = {type: "smsMessageReceived", senderPhoneNumber: "+491701234567", message: "Hallo", receivedAt: "2026-10-09T08:00:00.000Z"};

  const result = succeeded(await readChannelEventNodeExecutor.execute(nodeWith("sms"), contextWith(sms)));

  assert.deepEqual(Object.keys(result.outputs).sort(), ["receivedAt", "sender", "value"]);
});
