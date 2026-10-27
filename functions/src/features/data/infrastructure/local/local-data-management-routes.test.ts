import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {dataRoutes} from "./local-data-routes.js";
import {SQLiteDocumentStore} from "./sqlite-document-store.js";

async function dataApi(t: TestContext) {
  const store = new SQLiteDocumentStore(await runtimeTestDatabase(t));
  const kunden = await store.ensureCollection({teamId: "team-1", displayName: "Kunden"});
  await store.createMany({teamId: "team-1", collectionId: kunden.id, items: [{name: "Ben", umsatz: 20}, {name: "Anna", umsatz: 5}]});
  return testingRoutes(dataRoutes, {store});
}

const names = (body: unknown) => (body as {items: Array<{name: string}>}).items.map((item) => item.name);

test("creates, renames and deletes collections with conflicts reported as 409", async (t) => {
  const api = await dataApi(t);

  const created = await api.handle({method: "POST", url: "/v1/data/collections", body: {name: "  Lieferanten "}});
  const duplicate = await api.handle({method: "POST", url: "/v1/data/collections", body: {name: "Kunden"}});
  const blank = await api.handle({method: "POST", url: "/v1/data/collections", body: {name: "   "}});
  const taken = await api.handle({method: "PUT", url: "/v1/data/collections/Lieferanten", body: {name: "Kunden"}});
  const renamed = await api.handle({method: "PUT", url: "/v1/data/collections/Kunden", body: {name: "Kundschaft"}});
  const missing = await api.handle({method: "PUT", url: "/v1/data/collections/Fehlt", body: {name: "X"}});
  const deleted = await api.handle({method: "DELETE", url: "/v1/data/collections/Lieferanten", body: undefined});
  const list = await api.handle({method: "GET", url: "/v1/data/collections", body: undefined});

  assert.equal(created?.statusCode, 201);
  assert.equal((created?.body as {name: string}).name, "Lieferanten");
  assert.deepEqual([duplicate?.statusCode, blank?.statusCode, taken?.statusCode, missing?.statusCode], [409, 400, 409, 404]);
  assert.deepEqual(renamed?.body && {name: (renamed.body as {name: string}).name, count: (renamed.body as {documentCount: number}).documentCount},
    {name: "Kundschaft", count: 2});
  assert.equal(deleted?.statusCode, 204);
  assert.deepEqual(names(list?.body), ["Kundschaft"]);
});

test("deletes chosen documents and clears a collection", async (t) => {
  const api = await dataApi(t);
  const query = async () => (await api.handle({method: "POST", url: "/v1/data/collections/Kunden/query", body: {}}))?.body as
    {items: Array<{id: string}>};
  const [first] = (await query()).items;

  const chosen = await api.handle({method: "POST", url: "/v1/data/collections/Kunden/documents/delete", body: {ids: [first.id]}});
  const cleared = await api.handle({method: "DELETE", url: "/v1/data/collections/Kunden/documents", body: undefined});

  assert.deepEqual(chosen?.body, {deleted: 1});
  assert.deepEqual(cleared?.body, {deleted: 1});
  assert.equal((await query()).items.length, 0);
});

test("sorts query results by a field", async (t) => {
  const api = await dataApi(t);

  const response = await api.handle({method: "POST", url: "/v1/data/collections/Kunden/query",
    body: {sort: {field: "umsatz", direction: "desc"}}});
  const unsafe = await api.handle({method: "POST", url: "/v1/data/collections/Kunden/query",
    body: {sort: {field: "umsatz", direction: "zufällig"}}});

  assert.deepEqual((response?.body as {items: Array<{data: {name: string}}>}).items.map((item) => item.data.name), ["Ben", "Anna"]);
  assert.equal(unsafe?.statusCode, 400);
});

test("exports the filtered collection as CSV or JSON file", async (t) => {
  const api = await dataApi(t);

  const csv = await api.handleRaw({method: "POST", url: "/v1/data/collections/Kunden/export",
    body: {format: "csv", sort: {field: "name", direction: "asc"}}});
  const json = await api.handleRaw({method: "POST", url: "/v1/data/collections/Kunden/export",
    body: {format: "json", search: "anna"}});

  assert.equal(csv.statusCode, 200);
  assert.equal(csv.headers["content-type"], "text/csv; charset=utf-8");
  assert.match(String(csv.headers["content-disposition"]), /filename="Kunden.csv"/);
  assert.equal(csv.body, "﻿name,umsatz\r\nAnna,5\r\nBen,20\r\n");
  assert.deepEqual(JSON.parse(json.body), [{name: "Anna", umsatz: 5}]);
});

test("previews an import, refuses files with issues and imports clean files", async (t) => {
  const api = await dataApi(t);
  const upload = (url: string, content: string) => api.handle({method: "POST", url, body: undefined,
    headers: {"content-type": "application/octet-stream"}}, Buffer.from(content));

  const preview = await upload("/v1/data/collections/Kunden/import?format=csv", "Voller Name,PLZ\nCleo,01067\nDan,10115\n");
  const broken = await upload("/v1/data/collections/Kunden/import?format=csv&dryRun=false", "n\nA,B\n");
  const imported = await upload("/v1/data/collections/Kunden/import?format=csv&dryRun=false", "name\nCleo\nDan\n");
  const tooLarge = await upload("/v1/data/collections/Kunden/import?format=csv", "x".repeat(5 * 1024 * 1024 + 1));
  const list = await api.handle({method: "GET", url: "/v1/data/collections", body: undefined});

  assert.deepEqual(preview?.body, {count: 2, fields: ["Voller_Name", "PLZ"], renamedFields: [{from: "Voller Name", to: "Voller_Name"}],
    sample: [{Voller_Name: "Cleo", PLZ: "01067"}, {Voller_Name: "Dan", PLZ: 10115}], issues: []});
  assert.equal(broken?.statusCode, 422);
  assert.deepEqual(imported?.body, {imported: 2});
  assert.equal(tooLarge?.statusCode, 413);
  assert.equal((list?.body as {items: Array<{documentCount: number}>}).items[0]?.documentCount, 4);
});
