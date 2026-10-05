import assert from "node:assert/strict";
import test from "node:test";
import {type OutboundHttpClient, type OutboundHttpRequest} from "../../../connections/domain/repositories/outbound-http-client.js";
import {ShopwareError} from "../domain/shopware-error.js";
import {ShopwareClient} from "../infrastructure/shopware-client.js";
import {searchOrdersAction} from "./search-orders-action.js";

const order = {
  id: "0190a1", orderNumber: "10001", createdAt: "2026-10-05T08:30:12.123+00:00", amountTotal: 119, amountNet: 100,
  customerComment: "Bitte klingeln",
  currency: {isoCode: "EUR"},
  stateMachineState: {technicalName: "open", name: "Open", translated: {name: "Offen"}},
  orderCustomer: {customerId: "c1", customerNumber: "K1", email: "anna@example.com", firstName: "Anna", lastName: "Muster", company: null},
  lineItems: [
    {id: "li2", label: "Versandkosten", quantity: 1, unitPrice: 5, totalPrice: 5, type: "custom", position: 2, payload: {}},
    {id: "li1", label: "T-Shirt", quantity: 2, unitPrice: 50, totalPrice: 100, type: "product", position: 1, payload: {productNumber: "SW1000"}},
  ],
  transactions: [
    {stateMachineState: {technicalName: "paid", translated: {name: "Bezahlt"}}, paymentMethod: {name: "Invoice", translated: {name: "Rechnung"}}},
    {stateMachineState: {technicalName: "open", translated: {name: "Offen"}}, paymentMethod: {translated: {name: "Vorkasse"}}},
  ],
  deliveries: [{
    stateMachineState: {technicalName: "shipped", translated: {name: "Versandt"}},
    shippingMethod: {translated: {name: "Standard"}},
    shippingOrderAddress: {firstName: "Anna", lastName: "Muster", company: "Muster GmbH", street: "Hauptstr. 1", zipcode: "12345", city: "Berlin", country: {name: "Germany", translated: {name: "Deutschland"}}},
  }],
  billingAddress: {firstName: "Anna", lastName: "Muster", company: null, street: "Rechnungsweg 2", zipcode: "54321", city: "Hamburg", country: {name: "Germany"}},
};

function shopwareWith(respond: (body: Record<string, unknown>) => unknown) {
  const sent: OutboundHttpRequest[] = [];
  const http: OutboundHttpClient = {
    send: (request) => {
      sent.push(request);
      return Promise.resolve({status: 200, headers: {}, body: JSON.stringify(respond(JSON.parse(request.body ?? "{}") as Record<string, unknown>))});
    },
  };
  const bodies = () => sent.map((request) => JSON.parse(request.body ?? "{}") as Record<string, unknown>);
  return {client: new ShopwareClient(http, "team-1", "conn-1"), sent, bodies};
}

const run = (client: ShopwareClient, params: Record<string, unknown>) =>
  searchOrdersAction.execute({client, params, resolveText: (text) => text.replace("{{start}}", "2026-10-01")});

test("ohne Eingaben: neueste 50 Bestellungen ohne Filter, mit allen nötigen Assoziationen", async () => {
  const {client, sent, bodies} = shopwareWith(() => ({data: [order], total: 1}));

  await run(client, {});

  assert.equal(sent[0].url, "/api/search/order");
  const body = bodies()[0];
  assert.deepEqual(body.filter, []);
  assert.deepEqual(body.sort, [{field: "createdAt", order: "DESC"}]);
  assert.equal(body.limit, 50);
  assert.equal(body.page, 1);
  assert.equal(body["total-count-mode"], 1);
  assert.deepEqual(Object.keys(body.associations as object).sort(), ["billingAddress", "currency", "deliveries", "lineItems", "orderCustomer", "stateMachineState", "transactions"]);
});

test("alle Eingaben werden zu Filtern; Templates und Datumsangaben werden aufgelöst", async () => {
  const {client, bodies} = shopwareWith(() => ({data: [], total: 0}));

  await run(client, {
    createdFrom: "{{start}}", createdTo: "2026-10-05T12:00:00+02:00", status: "open", paymentStatus: "paid",
    deliveryStatus: "shipped", customerEmail: " anna@example.com ", orderNumber: "10001", sort: "oldest", limit: "5",
  });

  const body = bodies()[0];
  assert.deepEqual(body.filter, [
    {type: "range", field: "createdAt", parameters: {gte: "2026-10-01T00:00:00.000Z", lte: "2026-10-05T10:00:00.000Z"}},
    {type: "equals", field: "stateMachineState.technicalName", value: "open"},
    {type: "equals", field: "transactions.stateMachineState.technicalName", value: "paid"},
    {type: "equals", field: "deliveries.stateMachineState.technicalName", value: "shipped"},
    {type: "equals", field: "orderCustomer.email", value: "anna@example.com"},
    {type: "equals", field: "orderNumber", value: "10001"},
  ]);
  assert.deepEqual(body.sort, [{field: "createdAt", order: "ASC"}]);
  assert.equal(body.limit, 5);
});

test("nur eine Untergrenze ergibt einen Bereich ohne Obergrenze", async () => {
  const {client, bodies} = shopwareWith(() => ({data: [], total: 0}));

  await run(client, {createdFrom: "2026-10-01"});

  assert.deepEqual(bodies()[0].filter, [{type: "range", field: "createdAt", parameters: {gte: "2026-10-01T00:00:00.000Z"}}]);
});

test("liefert die Bestellungen im einfachen Modell samt Anzahl, Gesamtzahl und found", async () => {
  const {client} = shopwareWith(() => ({data: [order], total: 7}));

  const outputs = await run(client, {});

  assert.deepEqual(Object.keys(outputs).sort(), ["count", "found", "total", "value"]);
  assert.deepEqual(outputs.count, {type: "number", value: 1});
  assert.deepEqual(outputs.total, {type: "number", value: 7});
  assert.deepEqual(outputs.found, {type: "boolean", value: true});
  const [mapped] = (outputs.value as {value: Array<Record<string, unknown>>}).value;
  const {raw, ...model} = mapped;
  assert.deepEqual(model, {
    id: "0190a1", orderNumber: "10001", createdAt: "2026-10-05T08:30:12.123+00:00",
    status: "open", statusLabel: "Offen", paymentStatus: "paid", paymentStatusLabel: "Bezahlt",
    deliveryStatus: "shipped", deliveryStatusLabel: "Versandt", currency: "EUR", total: 119, netTotal: 100,
    customer: {id: "c1", number: "K1", email: "anna@example.com", firstName: "Anna", lastName: "Muster", company: ""},
    billingAddress: {firstName: "Anna", lastName: "Muster", company: "", street: "Rechnungsweg 2", zip: "54321", city: "Hamburg", country: "Germany"},
    shippingAddress: {firstName: "Anna", lastName: "Muster", company: "Muster GmbH", street: "Hauptstr. 1", zip: "12345", city: "Berlin", country: "Deutschland"},
    shippingMethod: "Standard", paymentMethod: "Rechnung", customerComment: "Bitte klingeln",
    lineItems: [
      {id: "li1", label: "T-Shirt", productNumber: "SW1000", quantity: 2, unitPrice: 50, total: 100, type: "product"},
      {id: "li2", label: "Versandkosten", productNumber: "", quantity: 1, unitPrice: 5, total: 5, type: "custom"},
    ],
  });
  assert.equal((raw as {orderNumber: string}).orderNumber, "10001", "das rohe Shopware-Objekt bleibt erhalten");
});

test("eine Bestellung mit fehlenden Teilen ergibt leere Werte statt eines Fehlers", async () => {
  const {client} = shopwareWith(() => ({data: [{id: "x"}], total: 1}));

  const outputs = await run(client, {});

  const [mapped] = (outputs.value as {value: Array<Record<string, unknown>>}).value;
  assert.equal(mapped.orderNumber, "");
  assert.equal(mapped.total, 0);
  assert.equal(mapped.billingAddress, null);
  assert.equal(mapped.shippingAddress, null);
  assert.deepEqual(mapped.lineItems, []);
  assert.equal(mapped.paymentStatus, "");
});

test("keine Treffer: leere Liste, found ist false", async () => {
  const {client} = shopwareWith(() => ({data: [], total: 0}));

  const outputs = await run(client, {});

  assert.deepEqual(outputs.value, {type: "json", value: []});
  assert.deepEqual(outputs.found, {type: "boolean", value: false});
});

test("ein Limit von 500 braucht genau eine Seite, die Gesamtzahl in Shopware bleibt sichtbar", async () => {
  const {client, bodies} = shopwareWith(() => ({data: Array.from({length: 500}, (_, index) => ({id: `o-${index}`})), total: 5000}));

  const outputs = await run(client, {limit: "500"});

  assert.equal(bodies().length, 1);
  assert.deepEqual(outputs.count, {type: "number", value: 500});
  assert.deepEqual(outputs.total, {type: "number", value: 5000});
});

test("ungültige Eingaben nennen das Feld und senden nichts", async () => {
  const {client, sent} = shopwareWith(() => ({data: [], total: 0}));
  const cases: Array<[Record<string, unknown>, RegExp]> = [
    [{status: "geloescht"}, /„geloescht“ ist für „Bestellstatus“ nicht erlaubt/],
    [{paymentStatus: "x"}, /Zahlungsstatus/],
    [{deliveryStatus: "x"}, /Lieferstatus/],
    [{sort: "zufall"}, /Sortierung/],
    [{createdFrom: "gestern"}, /„Bestellt ab“: „gestern“ ist kein gültiges Datum/],
    [{createdTo: "31.13.2026"}, /Bestellt bis/],
    [{limit: 0}, /Höchstanzahl.*1 bis 500/],
    [{limit: 501}, /Höchstanzahl/],
    [{limit: "viele"}, /Höchstanzahl/],
    [{limit: 1.5}, /Höchstanzahl/],
    [{orderNumber: 5}, /muss ein Text sein/],
    [{customerEmail: "x".repeat(300)}, /zu lang/],
  ];
  for (const [params, expected] of cases) {
    await assert.rejects(() => run(client, params), (error: unknown) => error instanceof ShopwareError && expected.test(error.message), JSON.stringify(params));
  }
  assert.equal(sent.length, 0);
});

test("Fehler von Shopware erreichen den Aufrufer mit verständlicher Meldung", async () => {
  const http: OutboundHttpClient = {send: () => Promise.resolve({status: 403, headers: {}, body: JSON.stringify({errors: [{detail: "Missing privilege order:read"}]})})};

  await assert.rejects(
    () => run(new ShopwareClient(http, "t", "c"), {}),
    (error: unknown) => error instanceof ShopwareError && /Berechtigung: Missing privilege order:read/.test(error.message),
  );
});
