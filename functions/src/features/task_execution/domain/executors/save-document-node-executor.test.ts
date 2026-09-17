import assert from "node:assert/strict";
import test from "node:test";
import {InMemoryDocumentStore} from "../../../data/infrastructure/in-memory/in-memory-document-store.js";
import {saveDocumentNodeExecutor} from "./save-document-node-executor.js";
import {type TaskRunContext} from "./node-executor.js";

test("legt ohne passende Datensätze einen neuen Datensatz an", async () => {
  const store = await storeWithCollection();

  const result = await executeSave(store, "kunde@example.com", "neu");

  assert.deepEqual(result.outputs.created, {type: "boolean", value: true});
  assert.deepEqual(result.outputs.count, {type: "number", value: 1});
  assert.equal((await store.findMany({teamId: "team_1", collectionId: "kunden"})).length, 1);
});

test("aktualisiert alle passenden Datensätze", async () => {
  const store = await storeWithCollection();
  await store.create({
    teamId: "team_1", collectionId: "kunden", data: {email: "kunde@example.com", status: "neu"},
  });
  await store.create({
    teamId: "team_1", collectionId: "kunden", data: {email: "kunde@example.com", status: "offen"},
  });

  const result = await executeSave(store, "kunde@example.com", "aktiv");
  const records = await store.findMany({
    teamId: "team_1",
    collectionId: "kunden",
    filters: [{field: "email", operator: "equals", value: "kunde@example.com"}],
  });

  assert.deepEqual(result.outputs.created, {type: "boolean", value: false});
  assert.deepEqual(result.outputs.count, {type: "number", value: 2});
  assert.deepEqual(records.map((record) => record.data.status), ["aktiv", "aktiv"]);
});

test("legt eine fehlende Datensammlung beim Speichern implizit an", async () => {
  const store = new InMemoryDocumentStore();

  await executeSave(store, "kunde@example.com", "neu");

  assert.equal((await store.findMany({teamId: "team_1", collectionId: "kunden"})).length, 1);
});

test("legt ohne Bedingungen immer einen neuen Datensatz an", async () => {
  const store = await storeWithCollection();
  await store.create({
    teamId: "team_1", collectionId: "kunden",
    data: {email: "kunde@example.com", status: "bestehend"},
  });

  const result = await executeSave(store, "kunde@example.com", "neu", []);
  const records = await store.findMany({teamId: "team_1", collectionId: "kunden"});

  assert.deepEqual(result.outputs.created, {type: "boolean", value: true});
  assert.equal(records.length, 2);
  assert.equal(records.some((record) => record.data.status === "bestehend"), true);
});

async function executeSave(
  store: InMemoryDocumentStore,
  email: string,
  status: string,
  filters: {field: string; operator: "equals"; value: string}[] = [
    {field: "email", operator: "equals", value: email},
  ],
) {
  return saveDocumentNodeExecutor.execute({
    node: {
      id: "save", primitive: "saveDocument", title: "Datensatz speichern",
      description: "", referenceName: "speichern",
      config: {
        primitive: "saveDocument", collectionName: "kunden", filters,
        fields: [{field: "status", value: status}],
      },
    }, context: "", parentOutputs: [],
  }, {
    teamId: "team_1",
    documentStore: store,
    resolveTemplateValue: (value: string) => value,
  } as unknown as TaskRunContext);
}

async function storeWithCollection(): Promise<InMemoryDocumentStore> {
  const store = new InMemoryDocumentStore();
  await store.createCollection({
    teamId: "team_1", id: "kunden", displayName: "kunden",
  });
  return store;
}
