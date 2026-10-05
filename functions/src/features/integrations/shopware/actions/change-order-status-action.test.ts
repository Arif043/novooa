import assert from "node:assert/strict";
import test from "node:test";
import {ShopwareError} from "../domain/shopware-error.js";
import {fakeShopware, resolveTemplates} from "../infrastructure/shopware-test-support.js";
import {changeOrderStatusAction} from "./change-order-status-action.js";

const orderId = "a".repeat(32);
const paymentId = "b".repeat(32);
const deliveryId = "c".repeat(32);

const orderWith = (states: {order: string; payment?: string; delivery?: string}, extra: Record<string, unknown> = {}) => ({
  id: orderId, orderNumber: "10001",
  stateMachineState: {technicalName: states.order},
  transactions: states.payment === undefined ? [] : [{id: paymentId, stateMachineState: {technicalName: states.payment}}, {id: "z".repeat(32), stateMachineState: {technicalName: "open"}}],
  deliveries: states.delivery === undefined ? [] : [{id: deliveryId, stateMachineState: {technicalName: states.delivery}}],
  ...extra,
});

const search = (...orders: unknown[]) => orders.map((order) => ({body: {data: [order], total: 1}}));

const run = (shop: ReturnType<typeof fakeShopware>, params: Record<string, unknown>) =>
  changeOrderStatusAction.execute({client: shop.client, params, resolveText: resolveTemplates});

test("ändert den Status der Bestellung, sendet standardmäßig keine Mail und meldet alten und neuen Status", async () => {
  const shop = fakeShopware({
    "POST /api/search/order": search(orderWith({order: "open"}), orderWith({order: "in_progress"})),
    [`POST /api/_action/order/${orderId}/state/process`]: {body: {}},
  });

  const outputs = await run(shop, {orderNumber: "10001", transition: "order.process"});

  assert.deepEqual(shop.bodies(`POST /api/_action/order/${orderId}/state/process`), [{sendMail: false}]);
  assert.deepEqual({previous: outputs.previousStatus, now: outputs.newStatus, changed: outputs.changed}, {
    previous: {type: "string", value: "open"}, now: {type: "string", value: "in_progress"}, changed: {type: "boolean", value: true},
  });
  assert.equal((outputs.value as {value: {status: string}}).value.status, "in_progress", "die Bestellung wird nach dem Wechsel neu gelesen");
});

test("Mail an den Kunden nur auf ausdrückliche Anweisung", async () => {
  const shop = fakeShopware({
    "POST /api/search/order": search(orderWith({order: "open"}), orderWith({order: "cancelled"})),
    [`POST /api/_action/order/${orderId}/state/cancel`]: {body: {}},
  });

  await run(shop, {orderNumber: "10001", transition: "order.cancel", sendMail: true});

  assert.deepEqual(shop.bodies(`POST /api/_action/order/${orderId}/state/cancel`), [{sendMail: true}]);
});

test("Zahlung und Lieferung wirken auf die jüngste Zahlung bzw. die erste Lieferung", async () => {
  const shop = fakeShopware({
    "POST /api/search/order": search(
      orderWith({order: "open", payment: "open", delivery: "open"}), orderWith({order: "open", payment: "paid", delivery: "open"}),
      orderWith({order: "open", payment: "paid", delivery: "open"}), orderWith({order: "open", payment: "paid", delivery: "shipped"}),
    ),
    [`POST /api/_action/order_transaction/${paymentId}/state/paid`]: {body: {}},
    [`POST /api/_action/order_delivery/${deliveryId}/state/ship`]: {body: {}},
  });

  const paid = await run(shop, {orderNumber: "10001", transition: "payment.paid"});
  const shipped = await run(shop, {orderNumber: "10001", transition: "delivery.ship"});

  assert.deepEqual([paid.previousStatus, paid.newStatus], [{type: "string", value: "open"}, {type: "string", value: "paid"}]);
  assert.deepEqual([shipped.previousStatus, shipped.newStatus], [{type: "string", value: "open"}, {type: "string", value: "shipped"}]);
});

test("ohne Zahlung oder Lieferung wird nichts gesendet", async () => {
  const shop = fakeShopware({"POST /api/search/order": search(orderWith({order: "open"}))});

  await assert.rejects(() => run(shop, {orderNumber: "10001", transition: "payment.paid"}), /keine Zahlung/);
  await assert.rejects(() => run(shop, {orderNumber: "10001", transition: "delivery.ship"}), /keine Lieferung/);
  assert.equal(shop.sent.filter((request) => request.url.includes("/_action/")).length, 0);
});

test("ein unzulässiger Übergang nennt den aktuellen Status und die möglichen Übergänge", async () => {
  const shop = fakeShopware({
    "POST /api/search/order": search(orderWith({order: "completed"})),
    [`POST /api/_action/order/${orderId}/state/process`]: {status: 400, body: {errors: [{detail: "Illegal transition"}]}},
    [`GET /api/_action/state-machine/order/${orderId}/state`]: {body: {transitions: [{actionName: "reopen"}, {actionName: "cancel"}]}},
  });

  await assert.rejects(
    () => run(shop, {orderNumber: "10001", transition: "order.process"}),
    (error: unknown) => error instanceof ShopwareError && /„process“ ist für die Bestellung im Status „completed“ nicht möglich\. Möglich sind: reopen, cancel\./.test(error.message),
  );
});

test("die Hilfe zu möglichen Übergängen ist optional; andere Fehler bleiben unverändert", async () => {
  const noHelp = fakeShopware({
    "POST /api/search/order": search(orderWith({order: "completed"})),
    [`POST /api/_action/order/${orderId}/state/process`]: {status: 400, body: {}},
  });
  await assert.rejects(() => run(noHelp, {orderNumber: "10001", transition: "order.process"}), /nicht möglich\.$/);

  const forbidden = fakeShopware({
    "POST /api/search/order": search(orderWith({order: "open"})),
    [`POST /api/_action/order/${orderId}/state/process`]: {status: 403, body: {errors: [{detail: "Missing privilege order:update"}]}},
  });
  await assert.rejects(() => run(forbidden, {orderNumber: "10001", transition: "order.process"}), /Berechtigung: Missing privilege order:update/);
});

test("ohne Statuswechsel, mit unbekanntem Wechsel oder ohne Bestellung wird nichts gesendet", async () => {
  const shop = fakeShopware({"POST /api/search/order": search(orderWith({order: "open"}))});

  await assert.rejects(() => run(shop, {orderNumber: "10001"}), /Statuswechsel/);
  await assert.rejects(() => run(shop, {orderNumber: "10001", transition: "order.loeschen"}), /nicht erlaubt/);
  await assert.rejects(() => run(shop, {transition: "order.process"}), /Bestellnummer/);
  await assert.rejects(() => run(shop, {orderNumber: "10001", transition: "order.process", sendMail: "vielleicht"}), /ein\/aus/);
  assert.equal(shop.sent.length, 0);
});
