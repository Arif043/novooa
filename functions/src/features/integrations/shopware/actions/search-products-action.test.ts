import assert from "node:assert/strict";
import test from "node:test";
import {fakeShopware, resolveTemplates} from "../infrastructure/shopware-test-support.js";
import {searchProductsAction} from "./search-products-action.js";

const product = {
  id: "p1", productNumber: "SW1000", active: true, stock: 12, availableStock: 10, ean: "4006381333931", parentId: null,
  name: null, translated: {name: "T-Shirt"},
  price: [{currencyId: "c", gross: 119, net: 100}],
  manufacturer: {translated: {name: "Muster GmbH"}},
};

const run = (shop: ReturnType<typeof fakeShopware>, params: Record<string, unknown>) =>
  searchProductsAction.execute({client: shop.client, params, resolveText: resolveTemplates});

test("ohne Eingaben: 50 Produkte nach Name, ohne Filter", async () => {
  const shop = fakeShopware({"POST /api/search/product": {body: {data: [], total: 0}}});

  await run(shop, {});

  const body = shop.bodies("POST /api/search/product")[0];
  assert.deepEqual(body.filter, []);
  assert.deepEqual(body.sort, [{field: "name", order: "ASC"}]);
  assert.equal(body.limit, 50);
  assert.deepEqual(body.associations, {manufacturer: {}, tax: {}});
});

test("alle Eingaben werden zu Filtern; Aktiv ist ein Wahrheitswert, der Bestand ein Bereich", async () => {
  const shop = fakeShopware({"POST /api/search/product": {body: {data: [], total: 0}}});

  await run(shop, {name: "Shirt", productNumber: "{{nummer}}", active: "false", stockMin: "0", stockMax: 5, sort: "stock", limit: 10});

  const body = shop.bodies("POST /api/search/product")[0];
  assert.deepEqual(body.filter, [
    {type: "contains", field: "name", value: "Shirt"},
    {type: "equals", field: "productNumber", value: "10001"},
    {type: "equals", field: "active", value: false},
    {type: "range", field: "stock", parameters: {gte: 0, lte: 5}},
  ]);
  assert.deepEqual(body.sort, [{field: "stock", order: "ASC"}]);
  assert.equal(body.limit, 10);
});

test("nur eine Bestandsgrenze ergibt einen halboffenen Bereich", async () => {
  const shop = fakeShopware({"POST /api/search/product": {body: {data: [], total: 0}}});

  await run(shop, {stockMax: "0"});

  assert.deepEqual(shop.bodies("POST /api/search/product")[0].filter, [{type: "range", field: "stock", parameters: {lte: 0}}]);
});

test("liefert Produkte im einfachen Modell; der Name kommt aus translated, fehlende Teile bleiben leer", async () => {
  const shop = fakeShopware({"POST /api/search/product": {body: {data: [product, {id: "p2"}], total: 9}}});

  const outputs = await run(shop, {});

  const [first, second] = (outputs.value as {value: Array<Record<string, unknown>>}).value;
  const {raw, ...model} = first;
  assert.deepEqual(model, {
    id: "p1", productNumber: "SW1000", name: "T-Shirt", active: true, stock: 12, availableStock: 10,
    price: {gross: 119, net: 100}, ean: "4006381333931", manufacturer: "Muster GmbH", parentId: "",
  });
  assert.equal((raw as {id: string}).id, "p1");
  assert.deepEqual({price: second.price, name: second.name, active: second.active}, {price: null, name: "", active: false});
  assert.deepEqual([outputs.count, outputs.total, outputs.found], [{type: "number", value: 2}, {type: "number", value: 9}, {type: "boolean", value: true}]);
});

test("ungültige Eingaben nennen das Feld und senden nichts", async () => {
  const shop = fakeShopware({});
  const cases: Array<[Record<string, unknown>, RegExp]> = [
    [{active: "vielleicht"}, /Aktiv/], [{sort: "zufall"}, /Reihenfolge/], [{stockMin: "viel"}, /Bestand ab/],
    [{stockMax: 1.5}, /Bestand bis/], [{limit: 501}, /Höchstanzahl/], [{name: "x".repeat(201)}, /zu lang/],
  ];
  for (const [params, expected] of cases) await assert.rejects(() => run(shop, params), expected, JSON.stringify(params));
  assert.equal(shop.sent.length, 0);
});
