import assert from "node:assert/strict";
import test from "node:test";
import {OutboundHttpError, type OutboundHttpClient, type OutboundHttpRequest, type OutboundHttpResponse} from "../../../connections/domain/repositories/outbound-http-client.js";
import {ShopwareError} from "../domain/shopware-error.js";
import {ShopwareClient} from "./shopware-client.js";

function clientWith(respond: (request: OutboundHttpRequest, index: number) => Partial<OutboundHttpResponse>) {
  const sent: OutboundHttpRequest[] = [];
  const http: OutboundHttpClient = {
    send: (request) => {
      sent.push(request);
      return Promise.resolve({status: 200, headers: {}, body: "{}", ...respond(request, sent.length - 1)});
    },
  };
  return {shopware: new ShopwareClient(http, "team-1", "conn-1"), sent};
}

const records = (count: number, offset = 0) => Array.from({length: count}, (_, index) => ({id: `id-${offset + index}`}));

test("sendet über die Verbindung an /api/… mit Accept: application/json und JSON-Body", async () => {
  const {shopware, sent} = clientWith(() => ({body: '{"ok":true}'}));

  const result = await shopware.request("PATCH", "/api/product/abc", {stock: 5});

  assert.deepEqual(result, {status: 200, data: {ok: true}});
  assert.equal(sent[0].connectionId, "conn-1");
  assert.equal(sent[0].teamId, "team-1");
  assert.equal(sent[0].method, "PATCH");
  assert.equal(sent[0].url, "/api/product/abc");
  assert.equal(sent[0].headers.accept, "application/json");
  assert.equal(sent[0].headers["content-type"], "application/json");
  assert.equal(sent[0].body, '{"stock":5}');
});

test("ohne Body gibt es weder Content-Type noch Body; leere Antworten sind null", async () => {
  const {shopware, sent} = clientWith(() => ({status: 204, body: ""}));

  assert.deepEqual(await shopware.request("GET", "/api/_info/version"), {status: 204, data: null});
  assert.equal("content-type" in sent[0].headers, false);
  assert.equal("body" in sent[0], false);
});

test("Pfade außerhalb von /api/ werden nicht gesendet", async () => {
  const {shopware, sent} = clientWith(() => ({}));

  await assert.rejects(() => shopware.request("GET", "/store-api/product"), ShopwareError);
  await assert.rejects(() => shopware.request("GET", "https://anders.example.com/api/x"), ShopwareError);
  assert.equal(sent.length, 0);
});

test("Fehlerstatus werden verständlich auf Deutsch gemeldet", async () => {
  const body = JSON.stringify({errors: [{status: "403", code: "FRAMEWORK__MISSING_PRIVILEGE_ERROR", title: "Forbidden", detail: "Missing privilege order:read"}]});
  const cases: Array<[number, string, RegExp]> = [
    [401, "{}", /Anmeldung abgelehnt/],
    [403, body, /fehlt eine Berechtigung: Missing privilege order:read/],
    [404, "{}", /kennt diese Adresse/],
    [400, JSON.stringify({errors: [{detail: "Ungültiger Filter"}]}), /abgelehnt \(Status 400\): Ungültiger Filter/],
    [429, "", /begrenzt/],
    [502, "<html>", /Fehler \(Status 502\)/],
  ];
  for (const [status, responseBody, expected] of cases) {
    const {shopware} = clientWith(() => ({status, body: responseBody}));
    await assert.rejects(
      () => shopware.request("GET", "/api/x"),
      (error: unknown) => error instanceof ShopwareError && error.status === status && expected.test(error.message),
      String(status),
    );
  }
});

test("Fehler des HTTP-Dienstes (Netzwerk, Anmeldung) bleiben unverändert", async () => {
  const shopware = new ShopwareClient({send: () => Promise.reject(new OutboundHttpError("nicht erreichbar"))}, "t", "c");

  await assert.rejects(() => shopware.request("GET", "/api/x"), (error: unknown) => error instanceof OutboundHttpError);
});

test("search sendet die Kriterien samt Gesamtzahl-Modus und liest data und total", async () => {
  const {shopware, sent} = clientWith(() => ({body: JSON.stringify({data: [{id: "a"}, "kaputt", {id: "b"}], total: 42})}));

  const result = await shopware.search("order", {filter: [{type: "equals", field: "orderNumber", value: "10001"}], limit: 2});

  assert.deepEqual(result, {data: [{id: "a"}, {id: "b"}], total: 42});
  assert.equal(sent[0].url, "/api/search/order");
  assert.deepEqual(JSON.parse(sent[0].body ?? "{}"), {"total-count-mode": 1, filter: [{type: "equals", field: "orderNumber", value: "10001"}], limit: 2});
});

test("search kennt nur gültige Entitätsnamen", async () => {
  const {shopware, sent} = clientWith(() => ({}));

  for (const entity of ["", "Order", "order/../x", "order?x=1", "1order"]) {
    await assert.rejects(() => shopware.search(entity, {}), ShopwareError, entity);
  }
  assert.equal(sent.length, 0);
});

test("searchAll holt Seiten gleicher Größe, bis genug da sind, und kürzt auf das Limit", async () => {
  const {shopware, sent} = clientWith((request) => {
    const {page} = JSON.parse(request.body ?? "{}") as {page: number};
    return {body: JSON.stringify({data: records(500, (page - 1) * 500), total: 1300})};
  });

  const result = await shopware.searchAll("product", {}, 1200);

  assert.equal(result.data.length, 1200);
  assert.equal(result.total, 1300);
  assert.deepEqual(sent.map((request) => {
    const body = JSON.parse(request.body ?? "{}") as {page: number; limit: number};
    return [body.page, body.limit];
  }), [[1, 500], [2, 500], [3, 500]]);
});

test("searchAll hört bei einer unvollständigen Seite auf und fragt nie über total hinaus", async () => {
  const {shopware, sent} = clientWith(() => ({body: JSON.stringify({data: records(3), total: 3})}));

  const result = await shopware.searchAll("customer", {}, 50);

  assert.equal(result.data.length, 3);
  assert.equal(sent.length, 1);
});

test("searchAll mit kleinem Limit fragt nur eine kleine Seite an", async () => {
  const {shopware, sent} = clientWith(() => ({body: JSON.stringify({data: records(10), total: 99})}));

  const result = await shopware.searchAll("order", {}, 10);

  assert.equal(result.data.length, 10);
  assert.equal(sent.length, 1);
  assert.equal((JSON.parse(sent[0].body ?? "{}") as {limit: number}).limit, 10);
});

test("version liest die Shopware-Version", async () => {
  assert.equal(await clientWith(() => ({body: '{"version":"6.6.10.2"}'})).shopware.version(), "6.6.10.2");
  assert.equal(await clientWith(() => ({body: "{}"})).shopware.version(), "unbekannt");
});
