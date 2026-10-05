import assert from "node:assert/strict";
import test from "node:test";
import {type EventTaskTrigger} from "../../../scheduling/domain/repositories/task-trigger-store.js";
import {fakeShopware} from "../infrastructure/shopware-test-support.js";
import {ShopwareTriggerInterpreter} from "./shopware-trigger-interpreter.js";

const orderId = "a".repeat(32);
const order = {
  id: orderId, orderNumber: "10001", amountTotal: 119, amountNet: 100, currency: {isoCode: "EUR"},
  stateMachineState: {technicalName: "open"}, orderCustomer: {email: "anna@example.com"},
};

function triggerFor(params: Record<string, unknown>): EventTaskTrigger {
  return {
    id: "t1", teamId: "team-1", taskId: "task-1", type: "event",
    eventConfig: {source: "shopware", target: {kind: "any"}, fileKinds: [], filter: "", params: {connectionId: "conn-1", ...params}},
  };
}

function run(shop: ReturnType<typeof fakeShopware>, params: Record<string, unknown>, body: unknown) {
  const interpreter = new ShopwareTriggerInterpreter(shop.http, () => new Date("2026-10-05T10:00:00Z"));
  const raw = Buffer.from(typeof body === "string" ? body : JSON.stringify(body));
  return interpreter.interpret(triggerFor(params), {triggerId: "t1", token: "x", method: "POST", query: {}, headers: {}, rawBody: raw});
}

const hook = (event: string, payload: unknown) => ({data: {event, payload}, source: {url: "http://shop"}});

test("Neue Bestellung: lädt die Bestellung nach und gibt sie im einfachen Modell weiter", async () => {
  const shop = fakeShopware({"POST /api/search/order": {body: {data: [order], total: 1}}});

  const runs = await run(shop, {event: "orderPlaced"}, hook("checkout.order.placed", {order: {id: orderId}}));

  assert.equal(runs.length, 1);
  assert.equal(runs[0]?.context, "Shopware: Neue Bestellung 10001");
  const event = runs[0]?.event as Record<string, unknown>;
  assert.deepEqual({...event, value: undefined}, {
    type: "shopwareEvent", kind: "orderPlaced", eventName: "checkout.order.placed", id: orderId,
    receivedAt: "2026-10-05T10:00:00.000Z", value: undefined,
  });
  assert.equal((event.value as {orderNumber: string}).orderNumber, "10001");
  assert.deepEqual(shop.bodies("POST /api/search/order")[0]?.ids, [orderId]);
});

test("ein anderes Ereignis, kaputtes JSON oder fehlende Kennung startet nichts", async () => {
  const shop = fakeShopware({"POST /api/search/order": {body: {data: [order], total: 1}}});

  assert.deepEqual(await run(shop, {event: "orderPlaced"}, hook("checkout.customer.register", {order: {id: orderId}})), []);
  assert.deepEqual(await run(shop, {event: "orderPlaced"}, "kein json"), []);
  assert.deepEqual(await run(shop, {event: "orderPlaced"}, hook("checkout.order.placed", {})), []);
  assert.equal(shop.sent.length, 0);
});

test("Bestellstatus: lauscht auf den Zustandsnamen und findet die Bestellung auch über die Zahlung", async () => {
  const shop = fakeShopware({"POST /api/search/order": {body: {data: [order], total: 1}}});
  const params = {event: "orderStatus", scope: "order_transaction", state: "paid"};

  assert.deepEqual(await run(shop, params, hook("state_enter.order_transaction.state.authorized", {orderTransaction: {orderId}})), []);
  const runs = await run(shop, params, hook("state_enter.order_transaction.state.paid", {orderTransaction: {orderId}}));

  assert.equal(runs.length, 1);
  assert.equal(runs[0]?.context, "Shopware: Bestellung 10001: Status geändert");
  assert.deepEqual(shop.bodies("POST /api/search/order")[0]?.ids, [orderId]);
});

test("Neuer Kunde und Newsletter laden ihren Datensatz", async () => {
  const shop = fakeShopware({
    "POST /api/search/customer": {body: {data: [{id: "c".repeat(32), email: "neu@example.com"}], total: 1}},
    "POST /api/search/newsletter_recipient": {body: {data: [{id: "d".repeat(32), email: "news@example.com", status: "optIn"}], total: 1}},
  });

  const customers = await run(shop, {event: "customerRegistered"}, hook("checkout.customer.register", {customer: {id: "c".repeat(32)}}));
  assert.equal(customers[0]?.context, "Shopware: Neuer Kunde neu@example.com");
  const confirmed = await run(shop, {event: "newsletterSubscribed"}, hook("newsletter.confirmed", {newsletterRecipient: {id: "d".repeat(32)}}));
  assert.equal(confirmed[0]?.context, "Shopware: Newsletter-Anmeldung news@example.com");
  assert.deepEqual(await run(shop, {event: "newsletterSubscribed"}, hook("newsletter.register", {newsletterRecipient: {id: "d".repeat(32)}})), []);
  const registered = await run(shop, {event: "newsletterSubscribed", confirmedOnly: false}, hook("newsletter.register", {newsletterRecipient: {id: "d".repeat(32)}}));
  assert.equal(registered.length, 1);
});

test("Bestand: meldet nur Produkte an oder unter der Grenze, deren Bestand sich geändert hat", async () => {
  const low = "1".repeat(32);
  const high = "2".repeat(32);
  const shop = fakeShopware({
    "POST /api/search/product": {body: {data: [
      {id: low, productNumber: "SW1", name: "Tasse", stock: 3},
      {id: high, productNumber: "SW2", name: "Teller", stock: 40},
    ], total: 2}},
  });
  const payload = [
    {entity: "product", operation: "update", primaryKey: low, updatedFields: ["stock"]},
    {entity: "product", operation: "update", primaryKey: high, updatedFields: ["stock", "price"]},
    {entity: "product", operation: "update", primaryKey: "3".repeat(32), updatedFields: ["price"]},
    {entity: "product", operation: "delete", primaryKey: "4".repeat(32)},
    {entity: "product_media", operation: "update", primaryKey: "5".repeat(32)},
  ];

  const runs = await run(shop, {event: "stockLow", threshold: 5}, hook("product.written", payload));

  assert.deepEqual(shop.bodies("POST /api/search/product")[0]?.ids, [low, high]);
  assert.equal(runs.length, 1);
  assert.equal(runs[0]?.context, "Shopware: Bestand niedrig: Tasse (3)");
  assert.equal((runs[0]?.event as {id: string}).id, low);
});

test("Bestand: ohne betroffene Produkte wird die API gar nicht gefragt", async () => {
  const shop = fakeShopware({});

  const runs = await run(shop, {event: "stockLow", threshold: 5}, hook("product.written", [{entity: "product", operation: "update", primaryKey: "1".repeat(32), updatedFields: ["name"]}]));

  assert.deepEqual(runs, []);
  assert.equal(shop.sent.length, 0);
});

test("ein Fehler der Shopware-API wird nicht verschluckt, damit der Absender es erneut versucht", async () => {
  const shop = fakeShopware({"POST /api/search/order": {status: 503, body: {}}});

  await assert.rejects(() => run(shop, {event: "orderPlaced"}, hook("checkout.order.placed", {order: {id: orderId}})));
});
