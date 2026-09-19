import assert from "node:assert/strict";
import test from "node:test";
import {InMemoryDocumentStore} from "../../../data/infrastructure/in-memory/in-memory-document-store.js";
import {type DocumentStore} from "../../../data/domain/repositories/document-store.js";
import {documentLookupNodeExecutor} from "./document-lookup-node-executor.js";
import {type TaskRunContext} from "./node-executor.js";

test("gibt einen gefundenen Datensatz mit verständlichem Ergebnis zurück", async () => {
  const store = new InMemoryDocumentStore();
  await store.createCollection(collection());
  await store.create({
    teamId: "team_1", collectionId: "kunden", documentId: "kunde_1",
    data: {email: "lea@example.com", status: "aktiv"},
  });

  const result = await documentLookupNodeExecutor.execute(
    lookupNode("{{email}}"), runContext(store, {"{{email}}": "lea@example.com"}), [],
  );

  assert.deepEqual(result.outputs.value, {type: "string", value: "Datensatz gefunden"});
  assert.deepEqual(result.outputs.found, {type: "boolean", value: true});
});

test("liefert keinen Treffer als reguläres Bedingungsergebnis", async () => {
  const store = new InMemoryDocumentStore();
  await store.createCollection(collection());

  const result = await documentLookupNodeExecutor.execute(
    lookupNode("unbekannt@example.com"), runContext(store), [],
  );

  assert.deepEqual(result.outputs.value, {
    type: "string", value: "Kein passender Datensatz gefunden",
  });
  assert.deepEqual(result.outputs.found, {type: "boolean", value: false});
});

test("übersetzt einen Suchfehler in ein verständliches Ergebnis", async () => {
  const result = await documentLookupNodeExecutor.execute(
    lookupNode("lea@example.com"), runContext(new FailingDocumentStore()), [],
  );

  assert.deepEqual(result.outputs.value, {type: "string", value: "Suche fehlgeschlagen"});
  assert.deepEqual(result.outputs.message, {
    type: "string", value: "Der Datensatz konnte nicht gesucht werden.",
  });
});

function lookupNode(value: string) {
  return {
    id: "lookup", primitive: "documentLookup" as const, title: "Datensatz suchen",
    description: "", referenceName: "kunde",
    config: {
      primitive: "documentLookup" as const, collectionName: "kunden",
      filters: [{field: "email", operator: "equals" as const, value}],
    },
  };
}

function runContext(
  documentStore: DocumentStore,
  templateValues: Record<string, unknown> = {},
): TaskRunContext {
  return {
    teamId: "team_1", documentStore,
    resolveTemplateValue: (value) => templateValues[value] ?? value,
  } as TaskRunContext;
}

function collection() {
  return {teamId: "team_1", id: "kunden", displayName: "kunden"};
}

class FailingDocumentStore extends InMemoryDocumentStore {
  override findOne(): Promise<null> {
    return Promise.reject(new Error("Datenbank nicht erreichbar"));
  }
}
