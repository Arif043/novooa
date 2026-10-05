import assert from "node:assert/strict";
import test from "node:test";
import {fakeShopware, resolveTemplates} from "../infrastructure/shopware-test-support.js";
import {searchCustomersAction} from "./search-customers-action.js";

const customer = {
  id: "k1", customerNumber: "K1", email: "anna@example.com", firstName: "Anna", lastName: "Muster", company: "Muster GmbH",
  active: true, guest: false, createdAt: "2026-01-01T10:00:00.000+00:00",
  group: {translated: {name: "Standard-Kundengruppe"}},
  defaultBillingAddress: {street: "Hauptstr. 1", zipcode: "12345", city: "Berlin", country: {translated: {name: "Deutschland"}}},
};

const run = (shop: ReturnType<typeof fakeShopware>, params: Record<string, unknown>) =>
  searchCustomersAction.execute({client: shop.client, params, resolveText: resolveTemplates});

test("ohne Eingaben: die neuesten 50 Kunden", async () => {
  const shop = fakeShopware({"POST /api/search/customer": {body: {data: [], total: 0}}});

  await run(shop, {});

  const body = shop.bodies("POST /api/search/customer")[0];
  assert.deepEqual(body.filter, []);
  assert.deepEqual(body.sort, [{field: "createdAt", order: "DESC"}]);
  assert.deepEqual(Object.keys(body.associations as object).sort(), ["defaultBillingAddress", "group"]);
});

test("der Name sucht in Vorname, Nachname und Firma", async () => {
  const shop = fakeShopware({"POST /api/search/customer": {body: {data: [], total: 0}}});

  await run(shop, {email: "@example.com", name: "Muster", customerNumber: "{{nummer}}", active: "true", sort: "name", limit: 20});

  const body = shop.bodies("POST /api/search/customer")[0];
  assert.deepEqual(body.filter, [
    {type: "contains", field: "email", value: "@example.com"},
    {type: "multi", operator: "OR", queries: [
      {type: "contains", field: "firstName", value: "Muster"},
      {type: "contains", field: "lastName", value: "Muster"},
      {type: "contains", field: "company", value: "Muster"},
    ]},
    {type: "equals", field: "customerNumber", value: "10001"},
    {type: "equals", field: "active", value: true},
  ]);
  assert.deepEqual(body.sort, [{field: "lastName", order: "ASC"}, {field: "firstName", order: "ASC"}]);
  assert.equal(body.limit, 20);
});

test("liefert Kunden im einfachen Modell", async () => {
  const shop = fakeShopware({"POST /api/search/customer": {body: {data: [customer, {id: "k2"}], total: 2}}});

  const outputs = await run(shop, {});

  const [first, second] = (outputs.value as {value: Array<Record<string, unknown>>}).value;
  const {raw: _raw, ...model} = first;
  assert.deepEqual(model, {
    id: "k1", customerNumber: "K1", email: "anna@example.com", firstName: "Anna", lastName: "Muster", company: "Muster GmbH",
    active: true, guest: false, group: "Standard-Kundengruppe", createdAt: "2026-01-01T10:00:00.000+00:00",
    billingAddress: {street: "Hauptstr. 1", zip: "12345", city: "Berlin", country: "Deutschland"},
  });
  assert.deepEqual({email: second.email, billingAddress: second.billingAddress, active: second.active}, {email: "", billingAddress: null, active: false});
  assert.deepEqual(outputs.found, {type: "boolean", value: true});
});

test("ungültige Eingaben senden nichts", async () => {
  const shop = fakeShopware({});

  await assert.rejects(() => run(shop, {active: "x"}), /Aktiv/);
  await assert.rejects(() => run(shop, {sort: "x"}), /Reihenfolge/);
  await assert.rejects(() => run(shop, {email: "x".repeat(255)}), /zu lang/);
  assert.equal(shop.sent.length, 0);
});
