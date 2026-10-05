import assert from "node:assert/strict";
import test from "node:test";
import {fakeShopware, resolveTemplates} from "../infrastructure/shopware-test-support.js";
import {readEventAction} from "./read-event-action.js";

const run = (event: unknown) => readEventAction.execute({client: fakeShopware({}).client, params: {}, resolveText: resolveTemplates, event});

test("gibt Datensatz, Art, Kennung und Zeitpunkt des Ereignisses aus; braucht keine Verbindung", async () => {
  assert.equal(readEventAction.usesConnection, false);

  const outputs = await run({type: "shopwareEvent", kind: "orderPlaced", id: "x1", receivedAt: "2026-10-05T10:00:00.000Z", value: {orderNumber: "10001"}});

  assert.deepEqual(outputs, {
    value: {type: "json", value: {orderNumber: "10001"}}, event: {type: "string", value: "orderPlaced"},
    id: {type: "string", value: "x1"}, receivedAt: {type: "datetime", value: "2026-10-05T10:00:00.000Z"},
  });
});

test("ein Lauf ohne Shopware-Ereignis scheitert verständlich", async () => {
  await assert.rejects(() => run(undefined), /nicht durch ein Shopware-Ereignis gestartet/);
  await assert.rejects(() => run({type: "webhookReceived"}), /nicht durch ein Shopware-Ereignis gestartet/);
  await assert.rejects(() => run({type: "shopwareEvent", kind: "gibtEsNicht"}), /unbekannt/);
});
