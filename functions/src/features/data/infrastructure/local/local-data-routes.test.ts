import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {testingRoutes} from "../../../../shared/local/local-runtime-http-test-support.js";
import {dataRoutes} from "./local-data-routes.js";
import {SQLiteDocumentStore} from "./sqlite-document-store.js";

async function dataApi(t: TestContext) {
  const store = new SQLiteDocumentStore(await runtimeTestDatabase(t));
  await store.ensureCollection({teamId: "team-1", displayName: "Kunden"});
  return testingRoutes(dataRoutes, {store});
}

const documents = "/v1/data/collections/Kunden/documents";

test("creates, finds, updates and deletes a document with its full nested data", async (t) => {
  const api = await dataApi(t);
  const data = {name: "ACME", address: {city: "Berlin", tags: ["b2b", 1]}, active: true};

  const created = await api.handle({method: "POST", url: documents, body: {data}});
  const id = (created?.body as {id: string}).id;
  const found = await api.handle({method: "POST", url: "/v1/data/collections/Kunden/query",
    body: {filters: [{field: "name", operator: "equals", value: "ACME"}], search: "berlin"}});
  const updated = await api.handle({method: "PUT", url: `${documents}/${id}`, body: {data: {...data, name: "ACME AG"}}});
  const deleted = await api.handle({method: "DELETE", url: `${documents}/${id}`, body: undefined});

  assert.equal(created?.statusCode, 201);
  assert.deepEqual((created?.body as {data: unknown}).data, data, "Response-Schema schneidet keine verschachtelten Felder ab");
  assert.deepEqual((found?.body as {items: Array<{id: string}>}).items.map((item) => item.id), [id]);
  assert.equal((updated?.body as {data: {name: string}}).data.name, "ACME AG");
  assert.equal(deleted?.statusCode, 204);
});

test("rejects malformed queries and documents through the schema", async (t) => {
  const api = await dataApi(t);

  const unknownOperator = await api.handle({method: "POST", url: "/v1/data/collections/Kunden/query",
    body: {filters: [{field: "name", operator: "like", value: "A"}]}});
  const arrayData = await api.handle({method: "POST", url: documents, body: {data: ["kein", "Objekt"]}});

  assert.equal(unknownOperator?.statusCode, 400);
  assert.equal(arrayData?.statusCode, 400);
});

test("reports an unknown collection as not found", async (t) => {
  const api = await dataApi(t);

  const response = await api.handle({method: "POST", url: "/v1/data/collections/Fehlt/documents", body: {data: {}}});

  assert.deepEqual(response, {statusCode: 404, body: {error: "Die Datensammlung wurde nicht gefunden."}});
});
