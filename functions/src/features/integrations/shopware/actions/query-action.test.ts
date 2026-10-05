import assert from "node:assert/strict";
import test from "node:test";
import {fakeShopware, resolveTemplates} from "../infrastructure/shopware-test-support.js";
import {queryAction} from "./query-action.js";

const run = (shop: ReturnType<typeof fakeShopware>, params: Record<string, unknown>) =>
  queryAction.execute({client: shop.client, params, resolveText: resolveTemplates});

test("fragt die gewählte Entität mit den Kriterien aus dem JSON ab und liefert die rohen Datensätze", async () => {
  const shop = fakeShopware({"POST /api/search/tax": {body: {data: [{id: "t1", taxRate: 19}, {id: "t2", taxRate: 7}], total: 2}}});

  const outputs = await run(shop, {entity: "tax", criteria: '{"filter": [{"type": "equals", "field": "taxRate", "value": "{{nummer}}"}], "sort": [{"field": "taxRate"}]}', limit: 20, page: 2});

  const body = shop.bodies("POST /api/search/tax")[0];
  assert.deepEqual(body.filter, [{type: "equals", field: "taxRate", value: "10001"}]);
  assert.deepEqual(body.sort, [{field: "taxRate"}]);
  assert.equal(body.limit, 20);
  assert.equal(body.page, 2);
  assert.equal(body["total-count-mode"], 1);
  assert.deepEqual(outputs.value, {type: "json", value: [{id: "t1", taxRate: 19}, {id: "t2", taxRate: 7}]});
  assert.deepEqual([outputs.count, outputs.total, outputs.found], [{type: "number", value: 2}, {type: "number", value: 2}, {type: "boolean", value: true}]);
});

test("ohne Kriterien gelten Seite 1 und 50 Datensätze", async () => {
  const shop = fakeShopware({"POST /api/search/order": {body: {data: [], total: 0}}});

  const outputs = await run(shop, {entity: "order"});

  const body = shop.bodies("POST /api/search/order")[0];
  assert.equal(body.limit, 50);
  assert.equal(body.page, 1);
  assert.deepEqual(outputs.found, {type: "boolean", value: false});
});

test("Limit, Seite und Zählmodus dürfen nicht in den Kriterien stehen", async () => {
  const shop = fakeShopware({});

  for (const key of ["limit", "page", "total-count-mode"]) {
    await assert.rejects(() => run(shop, {entity: "order", criteria: JSON.stringify({[key]: 1})}), new RegExp(`„${key}“ steht nicht in den Kriterien`));
  }
  assert.equal(shop.sent.length, 0);
});

test("ungültige Eingaben senden nichts", async () => {
  const shop = fakeShopware({});
  const cases: Array<[Record<string, unknown>, RegExp]> = [
    [{}, /welche Entität/],
    [{entity: "Order"}, /Entität/],
    [{entity: "order/../x"}, /Entität/],
    [{entity: "order", criteria: "{kaputt"}, /kein gültiges JSON/],
    [{entity: "order", criteria: "[1]"}, /JSON-Objekt/],
    [{entity: "order", criteria: "1"}, /JSON-Objekt/],
    [{entity: "order", limit: 0}, /Höchstanzahl/],
    [{entity: "order", page: 0}, /Seite/],
    [{entity: "order", criteria: " ".repeat(5) + "x".repeat(20_001)}, /zu lang/],
  ];
  for (const [params, expected] of cases) await assert.rejects(() => run(shop, params), expected, JSON.stringify(params));
  assert.equal(shop.sent.length, 0);
});

test("Fehler von Shopware (z. B. ein unbekanntes Feld) erreichen den Aufrufer", async () => {
  const shop = fakeShopware({"POST /api/search/order": {status: 400, body: {errors: [{detail: "Field \"foo\" not found"}]}}});

  await assert.rejects(() => run(shop, {entity: "order", criteria: '{"filter":[{"type":"equals","field":"foo","value":1}]}'}), /abgelehnt \(Status 400\): Field "foo" not found/);
});
