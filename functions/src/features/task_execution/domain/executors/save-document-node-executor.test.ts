import assert from "node:assert/strict";
import test from "node:test";
import {InMemoryDocumentStore} from "../../../data/infrastructure/in-memory/in-memory-document-store.js";
import {saveDocumentNodeExecutor} from "./save-document-node-executor.js";
import {type TaskRunContext} from "./node-executor.js";

test("legt mit dem Speichermodus Anlegen einen Datensatz an", async () => {
  const store = await storeWithCollection();
  const result = await executeSave(store, "create", "", [{field: "status", value: "neu"}]);

  assert.deepEqual(result.outputs.isNew, {type: "boolean", value: true});
  assert.equal((result.outputs.record?.value as {fields: {status: string}}).fields.status, "neu");
});

test("aktualisiert nur konfigurierte Felder eines vorhandenen Datensatzes", async () => {
  const store = await storeWithCollection();
  await store.create({
    teamId: "team_1", collectionId: "kunden", documentId: "kunde_1",
    data: {email: "lea@example.com", status: "neu"},
  });

  const result = await executeSave(store, "update", "kunde_1", [{field: "status", value: "aktiv"}]);
  const saved = await store.findById({teamId: "team_1", collectionId: "kunden", documentId: "kunde_1"});

  assert.deepEqual(result.outputs.isNew, {type: "boolean", value: false});
  assert.deepEqual(saved?.data, {email: "lea@example.com", status: "aktiv"});
});

test("legt beim Anlegen oder Aktualisieren fehlende Datensätze an", async () => {
  const store = await storeWithCollection();
  const first = await executeSave(store, "upsert", "kunde_1", [{field: "status", value: "neu"}]);
  const second = await executeSave(store, "upsert", "kunde_1", [{field: "email", value: "lea@example.com"}]);
  const saved = await store.findById({teamId: "team_1", collectionId: "kunden", documentId: "kunde_1"});

  assert.deepEqual(first.outputs.isNew, {type: "boolean", value: true});
  assert.deepEqual(second.outputs.isNew, {type: "boolean", value: false});
  assert.deepEqual(saved?.data, {status: "neu", email: "lea@example.com"});
});

async function executeSave(
  store: InMemoryDocumentStore,
  mode: "create" | "update" | "upsert",
  documentId: string,
  fields: {field: string; value: string}[],
) {
  return saveDocumentNodeExecutor.execute({
    node: {
      id: "save", primitive: "saveDocument", title: "Datensatz speichern",
      description: "", referenceName: "speichern",
      config: {primitive: "saveDocument", collectionId: "kunden", mode, documentId, fields},
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
    teamId: "team_1", id: "kunden", displayName: "Kundinnen und Kunden",
  });
  return store;
}
