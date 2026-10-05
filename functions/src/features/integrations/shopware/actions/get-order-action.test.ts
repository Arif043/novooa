import assert from "node:assert/strict";
import test from "node:test";
import {ShopwareError} from "../domain/shopware-error.js";
import {fakeShopware, resolveTemplates} from "../infrastructure/shopware-test-support.js";
import {getOrderAction} from "./get-order-action.js";

const order = {
  id: "a".repeat(32), orderNumber: "10001", amountTotal: 119, amountNet: 100, currency: {isoCode: "EUR"},
  stateMachineState: {technicalName: "open"},
  orderCustomer: {email: "anna@example.com", firstName: "Anna", lastName: "Muster"},
  transactions: [{stateMachineState: {technicalName: "paid"}}],
  deliveries: [{stateMachineState: {technicalName: "shipped"}}],
};

const run = (shop: ReturnType<typeof fakeShopware>, params: Record<string, unknown>) =>
  getOrderAction.execute({client: shop.client, params, resolveText: resolveTemplates});

test("liest eine Bestellung über ihre Nummer (auch aus einem Template) samt der festen Nebenwerte", async () => {
  const shop = fakeShopware({"POST /api/search/order": {body: {data: [order], total: 1}}});

  const outputs = await run(shop, {orderNumber: "{{nummer}}"});

  const body = shop.bodies("POST /api/search/order")[0];
  assert.deepEqual(body.filter, [{type: "equals", field: "orderNumber", value: "10001"}]);
  assert.equal(body.limit, 1);
  assert.equal("ids" in body, false);
  assert.equal((outputs.value as {value: {orderNumber: string}}).value.orderNumber, "10001");
  assert.deepEqual({...outputs, value: undefined}, {
    value: undefined,
    orderNumber: {type: "string", value: "10001"}, status: {type: "string", value: "open"},
    paymentStatus: {type: "string", value: "paid"}, deliveryStatus: {type: "string", value: "shipped"},
    total: {type: "number", value: 119}, customerEmail: {type: "string", value: "anna@example.com"},
  });
});

test("die Kennung hat Vorrang vor der Nummer und wird als ids gesucht", async () => {
  const shop = fakeShopware({"POST /api/search/order": {body: {data: [order], total: 1}}});

  await run(shop, {orderId: "A".repeat(32), orderNumber: "99999"});

  const body = shop.bodies("POST /api/search/order")[0];
  assert.deepEqual(body.ids, ["a".repeat(32)]);
  assert.equal("filter" in body, false);
});

test("ohne Angabe, mit ungültiger Kennung oder ohne Treffer gibt es eine verständliche Meldung", async () => {
  const empty = fakeShopware({"POST /api/search/order": {body: {data: [], total: 0}}});

  await assert.rejects(() => run(empty, {}), (error: unknown) => error instanceof ShopwareError && /Bestellnummer.*Bestell-ID/.test(error.message));
  await assert.rejects(() => run(empty, {orderId: "kurz"}), /32 Zeichen/);
  assert.equal(empty.sent.length, 0);
  await assert.rejects(() => run(empty, {orderNumber: "424242"}), /Die Bestellung mit der Nummer 424242 wurde in Shopware nicht gefunden/);
  await assert.rejects(() => run(empty, {orderId: "b".repeat(32)}), /mit der Kennung b{32}/);
});
