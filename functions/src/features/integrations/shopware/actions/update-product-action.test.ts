import assert from "node:assert/strict";
import test from "node:test";
import {fakeShopware, resolveTemplates} from "../infrastructure/shopware-test-support.js";
import {updateProductAction} from "./update-product-action.js";

const id = "d".repeat(32);
const currency = "e".repeat(32);

const product = (overrides: Record<string, unknown> = {}) => ({
  id, productNumber: "SW1000", active: true, stock: 5, name: "T-Shirt",
  price: [{currencyId: currency, gross: 100, net: 84.03}], tax: {taxRate: 19}, ...overrides,
});
const found = (...products: unknown[]) => products.map((entry) => ({body: {data: [entry], total: 1}}));

const run = (shop: ReturnType<typeof fakeShopware>, params: Record<string, unknown>) =>
  updateProductAction.execute({client: shop.client, params, resolveText: resolveTemplates});

test("ändert nur den Bestand und liest das Produkt danach neu", async () => {
  const shop = fakeShopware({
    "POST /api/search/product": found(product(), product({stock: 20})),
    [`PATCH /api/product/${id}`]: {status: 204},
  });

  const outputs = await run(shop, {productNumber: "SW1000", stock: "20"});

  assert.deepEqual(shop.bodies(`PATCH /api/product/${id}`), [{stock: 20}]);
  assert.equal((outputs.value as {value: {stock: number}}).value.stock, 20);
  assert.deepEqual(outputs.changed, {type: "boolean", value: true});
});

test("Aktiv ändert nur das Flag; ohne wirkliche Änderung ist changed false", async () => {
  const shop = fakeShopware({
    "POST /api/search/product": found(product(), product()),
    [`PATCH /api/product/${id}`]: {status: 204},
  });

  const outputs = await run(shop, {productNumber: "SW1000", active: "true"});

  assert.deepEqual(shop.bodies(`PATCH /api/product/${id}`), [{active: true}]);
  assert.deepEqual(outputs.changed, {type: "boolean", value: false});
});

test("der Preis ist brutto; Netto berechnet die Aktion aus dem Steuersatz, die Währung bleibt, andere Währungen auch", async () => {
  const other = {currencyId: "f".repeat(32), gross: 9, net: 8, linked: true};
  const shop = fakeShopware({
    "POST /api/search/product": found(product({price: [{currencyId: currency, gross: 100, net: 84.03}, other]}), product()),
    [`PATCH /api/product/${id}`]: {status: 204},
  });

  await run(shop, {productNumber: "SW1000", price: "119,00"});

  assert.deepEqual(shop.bodies(`PATCH /api/product/${id}`), [{price: [other, {currencyId: currency, gross: 119, net: 100, linked: true}]}]);
});

test("ohne bisherigen Preis gilt die Standardwährung", async () => {
  const shop = fakeShopware({
    "POST /api/search/product": found(product({price: null, tax: {taxRate: 7}}), product()),
    [`PATCH /api/product/${id}`]: {status: 204},
  });

  await run(shop, {productId: id, price: 107});

  assert.deepEqual(shop.bodies(`PATCH /api/product/${id}`), [{price: [{currencyId: "b7d2554b0ce847cd82f3ac9bd1c0dfca", gross: 107, net: 100, linked: true}]}]);
});

test("eine Variante ohne eigenen Steuersatz bekommt ihn vom Hauptprodukt; ohne Steuersatz wird nichts geändert", async () => {
  const parentId = "9".repeat(32);
  const inherited = fakeShopware({
    "POST /api/search/product": [
      {body: {data: [product({tax: null, parentId})], total: 1}},
      {body: {data: [product({id: parentId, tax: {taxRate: 19}})], total: 1}},
      {body: {data: [product()], total: 1}},
    ],
    [`PATCH /api/product/${id}`]: {status: 204},
  });
  await run(inherited, {productNumber: "SW1000", price: "119"});
  assert.equal(((inherited.bodies(`PATCH /api/product/${id}`)[0].price as Array<{net: number}>)[0]).net, 100);

  const none = fakeShopware({"POST /api/search/product": found(product({tax: null}))});
  await assert.rejects(() => run(none, {productNumber: "SW1000", price: "10"}), /Steuersatz.*nicht bestimmt/);
  assert.equal(none.sent.some((request) => request.method === "PATCH"), false);
});

test("alles zusammen in einem Aufruf", async () => {
  const shop = fakeShopware({
    "POST /api/search/product": found(product(), product({stock: 0, active: false})),
    [`PATCH /api/product/${id}`]: {status: 204},
  });

  await run(shop, {productNumber: "SW1000", stock: 0, active: "false", price: "119"});

  const [body] = shop.bodies(`PATCH /api/product/${id}`);
  assert.deepEqual(Object.keys(body).sort(), ["active", "price", "stock"]);
  assert.equal(body.stock, 0, "ein Bestand von 0 ist eine Änderung");
  assert.equal(body.active, false);
});

test("ohne Änderung, ohne Produkt oder mit ungültigen Werten wird nichts gesendet", async () => {
  const shop = fakeShopware({"POST /api/search/product": found(product())});
  const cases: Array<[Record<string, unknown>, RegExp]> = [
    [{productNumber: "SW1000"}, /was am Produkt geändert werden soll/],
    [{stock: "5"}, /Artikelnummer/],
    [{productNumber: "SW1000", stock: "-1"}, /Bestand/],
    [{productNumber: "SW1000", stock: "1,5"}, /Bestand/],
    [{productNumber: "SW1000", price: "teuer"}, /Preis brutto/],
    [{productNumber: "SW1000", price: "-3"}, /Preis brutto/],
    [{productNumber: "SW1000", active: "vielleicht"}, /Aktiv/],
  ];
  for (const [params, expected] of cases) await assert.rejects(() => run(shop, params), expected, JSON.stringify(params));
  assert.equal(shop.sent.length, 0);
});

test("ein unbekanntes Produkt ist ein Fehler, bevor etwas geändert wird", async () => {
  const shop = fakeShopware({"POST /api/search/product": {body: {data: [], total: 0}}});

  await assert.rejects(() => run(shop, {productNumber: "XYZ", stock: 1}), /Das Produkt mit der Nummer XYZ wurde in Shopware nicht gefunden/);
  assert.equal(shop.sent.some((request) => request.method === "PATCH"), false);
});
