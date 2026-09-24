import assert from "node:assert/strict";
import test from "node:test";
import {InMemoryDocumentStore} from "../../../data/infrastructure/in-memory/in-memory-document-store.js";
import {type DocumentStore} from "../../../data/domain/repositories/document-store.js";
import {tableFromCollectionNodeExecutor} from "./table-from-collection-node-executor.js";
import {type TaskRunContext} from "./node-executor.js";

test("liest alle Datensätze einer Sammlung als ausgerichtete Tabelle", async () => {
  const store = new InMemoryDocumentStore();
  await store.createCollection(collection());
  await store.create({
    teamId: "team_1", collectionId: "kunden", documentId: "kunde_1",
    data: {name: "Lea", status: "aktiv"},
  });
  await store.create({
    teamId: "team_1", collectionId: "kunden", documentId: "kunde_2",
    data: {name: "Tom"},
  });

  const result = await tableFromCollectionNodeExecutor.execute(node(), runContext(store));

  // InMemoryDocumentStore.findMany's row order isn't stable across runs
  // (updatedAt-based, sub-millisecond ties break arbitrarily) — the
  // executor doesn't (and shouldn't) impose its own order, so this asserts
  // shape and membership rather than exact row order.
  const table = result.outputs.value as {
    type: "table"; value: {columns: string[]; rows: unknown[][]};
  };
  assert.equal(table.type, "table");
  assert.deepEqual(table.value.columns, ["name", "status"]);
  assert.deepEqual(
    new Set(table.value.rows.map((row) => JSON.stringify(row))),
    new Set([JSON.stringify(["Lea", "aktiv"]), JSON.stringify(["Tom", null])]),
  );
  assert.deepEqual(result.outputs.rowCount, {type: "number", value: 2});
});

test("liefert eine leere Tabelle für eine unbekannte Sammlung", async () => {
  const store = new InMemoryDocumentStore();

  const result = await tableFromCollectionNodeExecutor.execute(node(), runContext(store));

  assert.deepEqual(result.outputs.value, {
    type: "table", value: {columns: [], rows: []},
  });
  assert.deepEqual(result.outputs.rowCount, {type: "number", value: 0});
});

function node() {
  return {
    id: "table", primitive: "tableFromCollection" as const,
    title: "Sammlung als Tabelle", description: "", outputName: "sammlungAlsTabelle",
    config: {primitive: "tableFromCollection" as const, collectionName: "kunden"},
  };
}

function runContext(documentStore: DocumentStore): TaskRunContext {
  return {
    teamId: "team_1", documentStore,
    templateExpressionResolver: {resolveText: (value: string) => value},
  } as TaskRunContext;
}

function collection() {
  return {teamId: "team_1", id: "kunden", displayName: "kunden"};
}
