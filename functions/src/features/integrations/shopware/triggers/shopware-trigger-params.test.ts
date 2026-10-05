import assert from "node:assert/strict";
import test from "node:test";
import {shopwareTriggerParamsFrom, shopwareTriggerProblem, shopwareWebhookEventName} from "./shopware-trigger-params.js";

const valid = {event: "orderPlaced", connectionId: "conn-1"};

test("prüft Ereignis, Verbindung, Zielstatus und Bestandsgrenze", () => {
  assert.equal(shopwareTriggerProblem(valid), null);
  assert.match(shopwareTriggerProblem({...valid, event: "gibtEsNicht"}) ?? "", /unbekannt/);
  assert.match(shopwareTriggerProblem({event: "orderPlaced"}) ?? "", /Verbindung/);
  assert.match(shopwareTriggerProblem({...valid, connectionId: "../x"}) ?? "", /Verbindung/);
  assert.match(shopwareTriggerProblem({...valid, event: "orderStatus", scope: "order", state: "paid"}) ?? "", /Zielstatus/);
  assert.equal(shopwareTriggerProblem({...valid, event: "orderStatus", scope: "order", state: "cancelled"}), null);
  assert.match(shopwareTriggerProblem({...valid, event: "orderStatus", scope: "kunde", state: "open"}) ?? "", /Statusbereich/);
  assert.match(shopwareTriggerProblem({...valid, event: "stockLow", threshold: 9e12}) ?? "", /Bestandsgrenze/);
  assert.equal(shopwareTriggerProblem({...valid, event: "stockLow", threshold: 5}), null);
});

test("jedes Ereignis hat seinen Webhook-Namen", () => {
  const name = (params: Record<string, unknown>) => shopwareWebhookEventName(shopwareTriggerParamsFrom({connectionId: "c", ...params}));

  assert.equal(name({event: "orderPlaced"}), "checkout.order.placed");
  assert.equal(name({event: "orderStatus", scope: "order_delivery", state: "shipped"}), "state_enter.order_delivery.state.shipped");
  assert.equal(name({event: "customerRegistered"}), "checkout.customer.register");
  assert.equal(name({event: "stockLow"}), "product.written");
  assert.equal(name({event: "newsletterSubscribed"}), "newsletter.confirmed");
  assert.equal(name({event: "newsletterSubscribed", confirmedOnly: false}), "newsletter.register");
});

test("Unbrauchbares beim Lesen fällt auf Vorgaben zurück", () => {
  const params = shopwareTriggerParamsFrom({event: "x", threshold: "viel", scope: "y"});

  assert.deepEqual(params, {event: "orderPlaced", connectionId: "", scope: "order_transaction", state: "", threshold: 0, confirmedOnly: true});
});
