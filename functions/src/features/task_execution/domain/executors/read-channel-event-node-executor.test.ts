import assert from "node:assert/strict";
import test from "node:test";
import {type TaskRunContext} from "./node-executor.js";
import {readChannelEventNodeExecutor} from "./read-email-node-executor.js";

const nodeWith = (config: Record<string, unknown>) =>
  ({id: "n1", primitive: "readChannelEvent", title: "", description: "", outputName: "", config}) as never;

const contextWith = (event: Record<string, unknown>) => ({input: {event}}) as unknown as TaskRunContext;

const email = {
  type: "emailReceived", senderEmail: "kunde@example.com", subject: "Rechnung",
  message: "Anbei die Rechnung.", receivedAt: "2026-10-09T08:00:00.000Z",
};

test("liefert die E-Mail-Werte flach unter den konfigurierten Namen, ohne value", async () => {
  const node = nodeWith({
    primitive: "readChannelEvent", kind: "email",
    outputNames: {sender: "absender", subject: "betreff", message: "text", receivedAt: "eingang"},
  });

  const result = await readChannelEventNodeExecutor.execute(node, contextWith(email));

  assert.deepEqual(result.outputs, {
    absender: {type: "string", value: "kunde@example.com"},
    betreff: {type: "string", value: "Rechnung"},
    text: {type: "string", value: "Anbei die Rechnung."},
    eingang: {type: "datetime", value: "2026-10-09T08:00:00.000Z"},
  });
});

test("WhatsApp und SMS haben keinen Betreff; fehlende Namen fallen auf die Standardnamen zurück", async () => {
  const node = nodeWith({primitive: "readChannelEvent", kind: "sms"});
  const sms = {type: "smsMessageReceived", senderPhoneNumber: "+491701234567", message: "Hallo", receivedAt: "2026-10-09T08:00:00.000Z"};

  const result = await readChannelEventNodeExecutor.execute(node, contextWith(sms));

  assert.deepEqual(Object.keys(result.outputs).sort(), ["message", "receivedAt", "sender"]);
});
