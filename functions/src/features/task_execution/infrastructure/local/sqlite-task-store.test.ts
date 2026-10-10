import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase} from "../../../../db/database.js";
import {SQLiteTaskStore} from "./sqlite-task-store.js";

test("loads client task documents whose primitive is stored in node config", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await database.run(sql`CREATE TABLE tasks (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, title TEXT NOT NULL,
    objective TEXT NOT NULL, graph_json TEXT NOT NULL
  )`);
  await database.run(sql`INSERT INTO tasks (id, team_id, title, objective, graph_json) VALUES (${"task-1"}, ${"team-1"}, ${"Aufgabe"}, ${""}, ${JSON.stringify(graphDocument())})`);

  const task = await new SQLiteTaskStore(database).loadTask("team-1", "task-1");

  assert.equal(task.nodes[0]?.primitive, "prompt");
  assert.equal(task.nodes[0]?.config.primitive, "prompt");
  database.$client.close();
});

test("loads data nodes whose primitive is stored in node configuration", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await database.run(sql`CREATE TABLE tasks (
    id TEXT PRIMARY KEY, team_id TEXT NOT NULL, title TEXT NOT NULL,
    objective TEXT NOT NULL, graph_json TEXT NOT NULL
  )`);
  await database.run(sql`INSERT INTO tasks (id, team_id, title, objective, graph_json) VALUES (${"task-1"}, ${"team-1"}, ${"Aufgabe"}, ${""}, ${JSON.stringify(dataGraphDocument())})`);

  const task = await new SQLiteTaskStore(database).loadTask("team-1", "task-1");

  assert.equal(task.nodes[0]?.config.primitive, "documentLookup");
  assert.equal(task.nodes[1]?.config.primitive, "saveDocument");
  assert.equal(task.nodes[1]?.config.collectionName, "Kunden");
  database.$client.close();
});

function graphDocument() {
  return {
    nodes: [{
      id: "node-1", title: "Prompt", description: "", outputs: [{key: "value", name: "prompt1", showOnCanvas: true}],
      config: {
        primitive: "prompt", instruction: "Hallo", languageModelId: "model-1",
        outputType: "text", choices: ["", ""], structuredFields: [],
        attachments: [], knowledgeAttachments: [], skillAttachments: [],
      },
    }],
    edges: [],
  };
}

function dataGraphDocument() {
  return {
    nodes: [
      {
        id: "lookup", title: "Datensatz suchen", description: "", outputs: [{key: "value", name: "lookup", showOnCanvas: true}],
        config: {primitive: "documentLookup", collectionName: "Kunden", filters: []},
      },
      {
        id: "save", title: "Datensatz speichern", description: "", outputs: [{key: "value", name: "save", showOnCanvas: true}],
        config: {
          primitive: "saveDocument", collectionName: "Kunden", mode: "create", documentId: "",
          fields: [{field: "name", value: "Max"}],
        },
      },
    ],
    edges: [],
  };
}
